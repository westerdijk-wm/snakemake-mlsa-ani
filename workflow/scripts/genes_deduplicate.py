#!/usr/bin/env python3

import sys
from Bio import SeqIO
import logging

in_fasta = snakemake.input[0]
out_fasta = snakemake.output[0]
logfile = snakemake.log[0]

# Configure logger
logging.basicConfig(
    filename=logfile,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
)

logger = logging.getLogger(__name__)

def deduplicate_fasta(input_fasta, output_fasta):
    seen = set()
    unique_records = []

    for record in SeqIO.parse(input_fasta, "fasta"):
        seq = str(record.seq)

        if seq in seen:
            logger.info(
                    "Ignoring duplicate sequence '%s' (sequence identical to a previous entry)",
                    record.id,
                )
        else:
        # if seq not in seen:
            seen.add(seq)
            unique_records.append(record)

    SeqIO.write(unique_records, output_fasta, "fasta")

deduplicate_fasta(in_fasta, out_fasta)
