#!/usr/bin/env python3

import sys
import pandas as pd
import re

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

    rows = []

    with open(infile) as f:
        first = f.readline()

        has_header = detect_header(first)

        if not has_header:
            # process first line too
            f.seek(0)
        else:
            # skip header
            pass

        for line in f:
            if not line.strip():
                continue

            parts = line.strip().split("\t")

            if len(parts) < 3:
                continue

            ref = clean_id(parts[0])
            qry = clean_id(parts[1])
            ani = float(parts[2])

            rows.append((ref, qry, ani))
            rows.append((qry, ref, ani))  # enforce symmetry

    df = pd.DataFrame(rows, columns=["ref", "qry", "ani"])

    matrix = df.pivot_table(
        index="ref",
        columns="qry",
        values="ani",
        aggfunc="mean"
    )

    # fill diagonal = 100
    for i in matrix.index:
        if i in matrix.columns:
            matrix.loc[i, i] = 100.0

    matrix = matrix.sort_index().sort_index(axis=1)

    matrix.index.name = None
    matrix.columns.name = None

    matrix.to_csv(outfile, sep="\t", float_format="%.5f")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ani_to_matrix.py <input.tsv> <output.tsv>")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])