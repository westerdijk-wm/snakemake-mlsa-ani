#!/usr/bin/env python3

import sys
import re
import logging
import pandas as pd
from Bio import SeqIO
import os

USAGE = """
Usage:
    gene_qc.py \
        <map_pool.fas> \
        <ref_genes.fas> \
        <detail.tsv> \
        <summary.tsv> \
        <matrix.tsv> \
        <filtered.fas> \
        <sample_list.txt> \
        <qc.log>
"""

if len(sys.argv) != 9:
    sys.exit(USAGE)

(
    map_fasta,
    ref_fasta,
    detail_out,
    summary_out,
    matrix_out,
    filtered_fasta,
    filtered_samples_out,
    log_file,
) = sys.argv[1:9]


# ---------------------------------------------------------
# LOGGING
# ---------------------------------------------------------

logger = logging.getLogger("gene_qc")
logger.setLevel(logging.INFO)

fmt = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

for h in [
    logging.StreamHandler(sys.stderr),
    logging.FileHandler(log_file)
]:
    h.setFormatter(fmt)
    logger.addHandler(h)

logger.info("Starting gene QC")


# ---------------------------------------------------------
# THRESHOLDS
# ---------------------------------------------------------

MIN_COVERAGE = 0.95
MIN_LENGTH_RATIO = 0.90


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

    gene = gene.lower().strip()
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
    gene = m.group(2).strip().lower()

    sim = re.search(r"sim:([0-9.]+)", desc)
    cov = re.search(r"cov:([0-9.]+)", desc)

    sim = float(sim.group(1)) if sim else None
    cov = float(cov.group(1)) if cov else None

    records.append({
        "Sample": sample,
        "Gene": gene,
        "Length": len(rec.seq),
        "Similarity": sim,
        "Coverage": cov,
        "Record": rec
    })

if not records:
    raise RuntimeError("No loci found in input FASTA")

df = pd.DataFrame(records)
logger.info(f"Parsed {len(df)} gene hits")


# ---------------------------------------------------------
# COPY NUMBER
# ---------------------------------------------------------

copy_counts = (
    df.groupby(["Sample", "Gene"])
      .size()
      .reset_index(name="Copies")
)

df = df.merge(copy_counts, on=["Sample", "Gene"])


# ---------------------------------------------------------
# REFERENCE COMPARISON
# ---------------------------------------------------------

df["RefLength"] = df["Gene"].map(ref_lengths)
df["LengthRatio"] = (df["Length"] / df["RefLength"]).round(3)


# ---------------------------------------------------------
# CLASSIFICATION
# ---------------------------------------------------------

def classify(row):

    if row["Copies"] > 1:
        return "DUPLICATED"

    if pd.notna(row["Coverage"]) and row["Coverage"] < MIN_COVERAGE:
        return "FRAGMENTED"

    if pd.notna(row["LengthRatio"]) and row["LengthRatio"] < MIN_LENGTH_RATIO:
        return "FRAGMENTED"

    return "OK"


df["Status"] = df.apply(classify, axis=1)


duplicate_groups = (
    df[df["Copies"] > 1]
    .sort_values(
        ["Sample", "Gene", "Coverage", "Similarity", "Length"],
        ascending=[True, True, False, False, False]
    )
)

if not duplicate_groups.empty:

    logger.info(
        "========== DUPLICATE GENE REPORT =========="
    )

    for (sample, gene), sub in duplicate_groups.groupby(
        ["Sample", "Gene"]
    ):

        logger.info(
            f"DUPLICATE: {sample} | {gene} | "
            f"{len(sub)} copies"
        )

        for i, (_, row) in enumerate(
            sub.iterrows(),
            start=1
        ):

            logger.info(
                f"    copy={i} "
                f"cov={row['Coverage']} "
                f"sim={row['Similarity']} "
                f"len={row['Length']}"
            )

# ---------------------------------------------------------
# KEEP BEST HITS
# ---------------------------------------------------------

best_hits = (
    df.sort_values(
        ["Sample", "Gene", "Coverage", "Similarity", "Length"],
        ascending=[True, True, False, False, False]
    )
    .drop_duplicates(["Sample", "Gene"], keep="first")
    .copy()
)

logger.info(f"Reduced to {len(best_hits)} best hits")

dup_best = best_hits[
    best_hits["Copies"] > 1
]

for _, row in dup_best.iterrows():

    logger.info(
        f"SELECTED_BEST_DUPLICATE: "
        f"{row['Sample']} | {row['Gene']} "
        f"(cov={row['Coverage']}, "
        f"sim={row['Similarity']}, "
        f"len={row['Length']})"
    )


# ---------------------------------------------------------
# ADD MISSING GENES
# ---------------------------------------------------------

all_samples = sorted(best_hits["Sample"].unique())
all_genes = sorted(ref_lengths.keys())

observed = set(zip(best_hits["Sample"], best_hits["Gene"]))

missing_rows = []

for s in all_samples:
    for g in all_genes:

        if (s, g) not in observed:
            missing_rows.append({
                "Sample": s,
                "Gene": g,
                "Copies": 0,
                "Length": pd.NA,
                "RefLength": ref_lengths[g],
                "LengthRatio": 0,
                "Coverage": 0,
                "Similarity": pd.NA,
                "Status": "MISSING",
                "Record": None
            })

logger.info(f"Missing entries generated: {len(missing_rows)}")


# ---------------------------------------------------------
# CONCAT
# ---------------------------------------------------------

detail_base = df[
    [
        "Sample","Gene","Copies","Length",
        "RefLength","LengthRatio","Coverage",
        "Similarity","Status"
    ]
].copy()

missing_df = pd.DataFrame(missing_rows)

detail= pd.concat(df.dropna(axis=1, how='all') for df in [detail_base, missing_df])


# ---------------------------------------------------------
# GENE PRESENCE/ABSENCE MATRIX
# ---------------------------------------------------------

matrix_df = (
    detail
    .drop_duplicates(["Sample", "Gene"])
    [["Sample", "Gene", "Status"]]
    .copy()
)

status_map = {
    "OK": "1",
    "DUPLICATED": "2",
    "FRAGMENTED": "F",
    "MISSING": "NA"
}

matrix_df["Value"] = matrix_df["Status"].map(status_map)

matrix_df = (
    matrix_df
    .pivot(
        index="Sample",
        columns="Gene",
        values="Value"
    )
    .reset_index()
)

# ---------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------

summary = (
    detail.groupby("Sample")
    .agg(
        Missing=("Status", lambda x: (x == "MISSING").sum()),
        Duplicated=("Status", lambda x: (x == "DUPLICATED").sum()),
        Fragmented=("Status", lambda x: (x == "FRAGMENTED").sum()),
    )
    .reset_index()
)


# ---------------------------------------------------------
# SAMPLE FILTERING
# ---------------------------------------------------------

summary["PASS"] = (
    (summary["Missing"] == 0) &
    (summary["Duplicated"] == 0) &
    (summary["Fragmented"] == 0)
)

passing_samples = set(summary.loc[summary["PASS"], "Sample"])
failing_samples = set(summary.loc[~summary["PASS"], "Sample"])


# ---------------------------------------------------------
# WRITE GENOME LIST FOR ANI
# ---------------------------------------------------------

GENOME_EXTS = [".fna", ".fasta", ".fas", ".fa"]

SEARCH_DIRS = [
    "genomes",
    "public_genomes"
]

with open(filtered_samples_out, "w") as out:

    for sample in sorted(passing_samples):

        found = False

        for genome_dir in SEARCH_DIRS:

            for ext in GENOME_EXTS:

                genome = os.path.join(
                    genome_dir,
                    f"{sample}{ext}"
                )

                if os.path.exists(genome):
                    out.write(genome + "\n")
                    found = True
                    break

            if found:
                break

        if not found:
            logger.warning(
                f"No genome file found for passing sample '{sample}'"
            )

logger.info(
    f"Wrote ANI genome list with {len(passing_samples)} samples"
)

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

    missing = subset[subset["Status"] == "MISSING"]["Gene"].tolist()
    dup = subset[subset["Status"] == "DUPLICATED"]["Gene"].tolist()
    frag = subset[subset["Status"] == "FRAGMENTED"]["Gene"].tolist()

    if missing:
        logger.info(f"  missing: {', '.join(missing)}")
    if dup:
        logger.info(f"  duplicated: {', '.join(dup)}")
    if frag:
        logger.info(f"  fragmented: {', '.join(frag)}")


# ---------------------------------------------------------
# WRITE OUTPUTS
# ---------------------------------------------------------

detail = detail.sort_values(["Sample", "Gene"])
detail_out_df = detail.drop(columns=["Record"], errors="ignore")
detail_out_df.to_csv(detail_out, sep="\t", index=False)
summary.to_csv(summary_out, sep="\t", index=False)

matrix_df = matrix_df.astype(str)
matrix_df = matrix_df.replace({"<NA>": "NA", "nan": "NA"})
matrix_df.to_csv(matrix_out, sep="\t", index=False)

# ---------------------------------------------------------
# FILTER FASTA
# ---------------------------------------------------------

filtered_records = []

for _, row in best_hits.iterrows():
    if row["Sample"] in passing_samples:
        if row["Record"] is not None:
            filtered_records.append(row["Record"])

SeqIO.write(filtered_records, filtered_fasta, "fasta")


# ---------------------------------------------------------
# FINAL LOG
# ---------------------------------------------------------

logger.info("========== QC SUMMARY ==========")
logger.info(f"Total samples: {len(all_samples)}")
logger.info(f"Passing samples: {len(passing_samples)}")
logger.info(f"Failing samples: {len(failing_samples)}")

logger.info(f"Missing gene calls: {(detail['Status']=='MISSING').sum()}")
logger.info(f"Duplicated gene calls: {(detail['Status']=='DUPLICATED').sum()}")
logger.info(f"Fragmented gene calls: {(detail['Status']=='FRAGMENTED').sum()}")

logger.info("Gene QC completed successfully")