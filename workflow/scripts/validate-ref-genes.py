#!/usr/bin/env python3

import re
import sys
from Bio import SeqIO

USAGE = """
Usage:
    validate_ref_genes.py <ref_genes.fas> <validated.ok> <cleaned.fas>
"""

if len(sys.argv) != 4:
    sys.exit(USAGE)

fasta = sys.argv[1]
outfile = sys.argv[2]
clean_fasta = sys.argv[3]

errors = []
warnings = []

seen_headers = set()
n_records = 0

with open(clean_fasta, "w") as out_fa:

    for rec in SeqIO.parse(fasta, "fasta"):

        n_records += 1

        original_header = rec.description

        # -----------------------------------------------------
        # CLEAN HEADER
        # -----------------------------------------------------

        header = original_header.strip()

        # collapse whitespace
        header = re.sub(r"\s+", " ", header)

        # normalize spaces around pipe
        header = re.sub(r"\s*\|\s*", "|", header)

        if header != original_header.strip():
            warnings.append(f"Header normalized: " f"'{original_header}' -> '{header}'")

        # -----------------------------------------------------
        # VALIDATE FORMAT
        # -----------------------------------------------------

        if not re.match(r"^[^|]+\|[^|]+$", header):

            errors.append(
                f"Invalid header format: '{header}' " f"(expected: strain|gene)"
            )
            continue

        strain, gene = header.split("|", 1)

        strain = strain.strip()
        gene = gene.strip()

        # -----------------------------------------------------
        # EMPTY FIELD CHECKS
        # -----------------------------------------------------

        if not strain:
            errors.append(f"Missing strain in header: '{header}'")

        if not gene:
            errors.append(f"Missing gene in header: '{header}'")

        # -----------------------------------------------------
        # DUPLICATE CHECK
        # -----------------------------------------------------

        unique_key = f"{strain}|{gene}"

        if unique_key in seen_headers:
            errors.append(f"Duplicate reference sequence detected: '{unique_key}'")

        seen_headers.add(unique_key)

        # -----------------------------------------------------
        # WRITE CLEAN FASTA RECORD
        # -----------------------------------------------------

        rec.id = unique_key
        rec.name = unique_key
        rec.description = ""

        SeqIO.write(rec, out_fa, "fasta")

# ---------------------------------------------------------
# FINAL VALIDATION
# ---------------------------------------------------------

if n_records == 0:
    errors.append("Reference FASTA contains no sequences.")

# ---------------------------------------------------------
# REPORT
# ---------------------------------------------------------

print("")
print("REFERENCE GENE FASTA VALIDATION")
print("--------------------------------")
print(f"Sequences checked: {n_records}")
print("")

if warnings:
    print("WARNINGS:")
    for w in warnings:
        print(f"  WARNING: {w}")
    print("")

if errors:
    print("ERRORS:")
    for e in errors:
        print(f"  ERROR: {e}")
    print("")
    print("Validation FAILED.")
    sys.exit(1)

print("Validation PASSED.")

# ---------------------------------------------------------
# SUCCESS MARKER
# ---------------------------------------------------------

with open(outfile, "w") as f:
    f.write("OK\n")
