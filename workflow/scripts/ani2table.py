#!/usr/bin/env python3

import sys
import logging
import pandas as pd
import re

log_file = snakemake.log["log"]

logger = logging.getLogger("ani_matrix")
logger.setLevel(logging.INFO)

fmt = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")

file_handler = logging.FileHandler(log_file)
file_handler.setFormatter(fmt)
logger.addHandler(file_handler)

sys.stderr = open(log_file, "a")


def clean_id(x: str) -> str:
    """
    Convert genomes/XXX.ext -> XXX
    """
    x = x.strip()

    # remove directory
    x = x.split("/")[-1]

    # remove extensions if present
    x = re.sub(r"\.(fna|fa|fasta|fas)$", "", x)

    return x


def detect_header(first_line: str) -> bool:
    """
    detect if file has header
    """
    return "ANI" in first_line or "Ref_file" in first_line


def main(infile, outfile):

    logger.info(f"Reading ANI results from: {infile}")

    rows = []
    skipped = 0

    with open(infile) as f:
        first = f.readline()

        has_header = detect_header(first)

        if has_header:
            logger.info("Header detected — skipping first line")
        else:
            logger.info("No header detected — processing from first line")
            f.seek(0)

        for line in f:
            if not line.strip():
                continue

            parts = line.strip().split("\t")

            if len(parts) < 3:
                logger.warning(f"Skipping short line ({len(parts)} fields): {line.rstrip()}")
                skipped += 1
                continue

            ref = clean_id(parts[0])
            qry = clean_id(parts[1])
            ani = float(parts[2])

            rows.append((ref, qry, ani))
            rows.append((qry, ref, ani))

    if not rows:
        raise RuntimeError("No valid ANI rows parsed — output would be empty")

    logger.info(f"Parsed {len(rows) // 2} ANI pairs ({len(rows)} with symmetry), {skipped} lines skipped")

    df = pd.DataFrame(rows, columns=["ref", "qry", "ani"])

    matrix = df.pivot_table(index="ref", columns="qry", values="ani", aggfunc="mean")

    # Fill diagonal
    filled = 0
    for i in matrix.index:
        if i in matrix.columns:
            matrix.loc[i, i] = 100.0
            filled += 1

    logger.info(f"Matrix shape: {matrix.shape[0]}x{matrix.shape[1]} ({filled} diagonal cells set to 100)")

    nan_count = matrix.isna().sum().sum()
    if nan_count:
        logger.warning(f"{nan_count} missing values in ANI matrix — pairwise comparisons may be incomplete")

    matrix = matrix.sort_index().sort_index(axis=1)

    matrix.index.name = None
    matrix.columns.name = None

    matrix.to_csv(outfile, sep="\t", float_format="%.5f")
    logger.info(f"ANI matrix written to: {outfile}")


logger.info("Starting ANI matrix construction")
main(snakemake.input[0], snakemake.output[0])
logger.info("ANI matrix construction completed successfully")