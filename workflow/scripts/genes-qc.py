#!/usr/bin/env python3

import sys
import re
import logging
import pandas as pd
from Bio import SeqIO
import os

map_fasta = snakemake.input["fasta"]
ref_fasta = snakemake.input["ref"]

public_genome_files = snakemake.input["public_genome_files"]
local_genome_files = snakemake.input["local_genome_files"]
genomes = local_genome_files + public_genome_files

detail_out = snakemake.output["detail"]
matrix_out = snakemake.output["matrix"]
filtered_fasta = snakemake.output["filtered"]
filtered_samples_out = snakemake.output["sample_lists"]

log_file = snakemake.log["log"]

# ---------------------------------------------------------
# LOGGING
# ---------------------------------------------------------

logger = logging.getLogger("gene_qc")
logger.setLevel(logging.INFO)

fmt = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

file_handler = logging.FileHandler(log_file)
file_handler.setFormatter(fmt)
logger.addHandler(file_handler)

# Keep stderr pointed at the log file for any uncaught print()/tracebacks
sys.stderr = open(log_file, "a")

logger.info("Starting gene QC")


# ---------------------------------------------------------
# THRESHOLDS
# ---------------------------------------------------------

MIN_COVERAGE = 0.95
MIN_LENGTH_RATIO = 0.90

MAX_MISSING_ALLOWED = 0


# ---------------------------------------------------------
# REFERENCE GENES
# ---------------------------------------------------------

ref_lengths = {}

for rec in SeqIO.parse(ref_fasta, "fasta"):

    header = rec.description.strip()

    if "|" in header:
        gene = header.split("|")[-1].split()[0]
    else:
        gene = header.split()[0]

    gene = gene.strip()
    ref_lengths[gene] = len(rec.seq)

if not ref_lengths:
    raise RuntimeError("No reference genes found")

logger.info(f"Loaded {len(ref_lengths)} reference genes")


# ---------------------------------------------------------
# PARSE MAP FASTA
# ---------------------------------------------------------

records = []

for rec in SeqIO.parse(map_fasta, "fasta"):

    desc = rec.description.strip()

    m = re.match(r"^([^|]+)\|([^\s]+)", desc)
    if not m:
        logger.warning(f"Unparsed header: {desc}")
        continue

    sample = m.group(1).strip()
    gene = m.group(2).strip()

    sim = re.search(r"sim:([0-9.]+)", desc)
    cov = re.search(r"cov:([0-9.]+)", desc)

    sim = float(sim.group(1)) if sim else None
    cov = float(cov.group(1)) if cov else None

    records.append(
        {
            "Sample": sample,
            "Gene": gene,
            "Length": len(rec.seq),
            "Similarity": sim,
            "Coverage": cov,
            "Record": rec,
        }
    )

if not records:
    raise RuntimeError("No loci found in input FASTA")

df = pd.DataFrame(records)
logger.info(f"Parsed {len(df)} gene hits")


# ---------------------------------------------------------
# REFERENCE COMPARISON
# ---------------------------------------------------------

df["RefLength"] = df["Gene"].map(ref_lengths)
df["LengthRatio"] = (df["Length"] / df["RefLength"]).round(3)


# ---------------------------------------------------------
# COPY NUMBER MATRIX
# All hits are kept; matrix reports the integer copy count per
# Sample/Gene (0 = absent).
# ---------------------------------------------------------

all_samples = sorted(df["Sample"].unique())
all_genes = sorted(ref_lengths.keys())

copy_counts = (
    df.groupby(["Sample", "Gene"])
    .size()
    .reset_index(name="Copies")
)

# Build full grid so absent genes appear as 0
full_index = pd.MultiIndex.from_product(
    [all_samples, all_genes], names=["Sample", "Gene"]
)
matrix_df = (
    copy_counts
    .set_index(["Sample", "Gene"])
    .reindex(full_index, fill_value=0)
    .reset_index()
    .pivot(index="Sample", columns="Gene", values="Copies")
    .reset_index()
)


# ---------------------------------------------------------
# DETAIL TABLE
# All individual hits, annotated with their per-gene copy count.
# ---------------------------------------------------------

detail = df.merge(copy_counts, on=["Sample", "Gene"])

detail = detail[
    [
        "Sample",
        "Gene",
        "Copies",
        "Length",
        "RefLength",
        "LengthRatio",
        "Coverage",
        "Similarity",
    ]
].sort_values(["Sample", "Gene"])


# ---------------------------------------------------------
# SAMPLE FILTERING
# A sample passes when every reference gene is present exactly
# once and no hit is fragmented.
# ---------------------------------------------------------

def is_fragmented(row):
    if pd.notna(row["Coverage"]) and row["Coverage"] < MIN_COVERAGE:
        return True
    if pd.notna(row["LengthRatio"]) and row["LengthRatio"] < MIN_LENGTH_RATIO:
        return True
    return False

detail["Fragmented"] = detail.apply(is_fragmented, axis=1)

# Summarise per sample against the full gene set
summary = pd.DataFrame({"Sample": all_samples})

gene_counts = copy_counts.set_index(["Sample", "Gene"])["Copies"]

def sample_stats(s):
    missing = sum(
        1 for g in all_genes if gene_counts.get((s, g), 0) == 0
    )
    duplicated = sum(
        1 for g in all_genes if gene_counts.get((s, g), 0) > 1
    )
    fragmented = detail[
        (detail["Sample"] == s) & detail["Fragmented"]
    ].shape[0]
    return pd.Series(
        {"Missing": missing, "Duplicated": duplicated, "Fragmented": fragmented}
    )

summary = summary.join(summary["Sample"].apply(sample_stats))

summary["PASS"] = (
    (summary["Missing"] <= MAX_MISSING_ALLOWED)
    & (summary["Duplicated"] == 0)
    & (summary["Fragmented"] == 0)
)

passing_samples = set(summary.loc[summary["PASS"], "Sample"])
failing_samples = set(summary.loc[~summary["PASS"], "Sample"])


# ---------------------------------------------------------
# WRITE GENOME LIST FOR ANI
# ---------------------------------------------------------

GENOME_EXTS = [".fna", ".fasta", ".fas", ".fa"]

# SEARCH_DIRS = ["genomes", "resources/public_genomes"]

with open(filtered_samples_out, "w") as out:

    for sample in sorted(passing_samples):

        found = False
 
        for genome in genomes:

            pattern = rf"/{sample}\."
            if re.search(pattern, genome) and os.path.exists(genome):
                out.write(genome + "\n")
                found = True
                break

            if found:
                break

        if not found:
            logger.warning(f"No genome file found for passing sample '{sample}'")

logger.info(f"Wrote ANI genome list with {len(passing_samples)} samples")


# ---------------------------------------------------------
# FAILURE LOGGING
# ---------------------------------------------------------

logger.info("========== SAMPLE FAILURE REPORT ==========")

for _, row in summary.iterrows():

    if row["PASS"]:
        continue

    s = row["Sample"]

    logger.info(
        f"SAMPLE FAIL: {s} | "
        f"MISSING={row['Missing']} "
        f"DUP={row['Duplicated']} "
        f"FRAG={row['Fragmented']}"
    )

    subset = detail[detail["Sample"] == s]

    missing_genes = [g for g in all_genes if gene_counts.get((s, g), 0) == 0]
    dup_genes = [g for g in all_genes if gene_counts.get((s, g), 0) > 1]
    frag_genes = subset[subset["Fragmented"]]["Gene"].tolist()

    if missing_genes:
        logger.info(f"  missing: {', '.join(missing_genes)}")
    if dup_genes:
        logger.info(f"  duplicated: {', '.join(dup_genes)}")
    if frag_genes:
        logger.info(f"  fragmented: {', '.join(frag_genes)}")


# ---------------------------------------------------------
# WRITE OUTPUTS
# ---------------------------------------------------------

detail.drop(columns=["Fragmented"]).to_csv(detail_out, sep="\t", index=False)

matrix_df.to_csv(matrix_out, sep="\t", index=False)

# ---------------------------------------------------------
# FILTER FASTA
# ---------------------------------------------------------

filtered_records = [
    row["Record"]
    for _, row in df.iterrows()
    if row["Sample"] in passing_samples
]

SeqIO.write(filtered_records, filtered_fasta, "fasta")


# ---------------------------------------------------------
# FINAL LOG
# ---------------------------------------------------------

logger.info("========== QC SUMMARY ==========")
logger.info(f"Total samples: {len(all_samples)}")
logger.info(f"Passing samples: {len(passing_samples)}")
logger.info(f"Failing samples: {len(failing_samples)}")
logger.info(f"Total gene hits: {len(df)}")

logger.info("Gene QC completed successfully")