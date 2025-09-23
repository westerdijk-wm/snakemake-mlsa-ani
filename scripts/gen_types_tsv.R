#!/usr/bin/env Rscript

# Usage: Rscript make_fumigatus_table.R /path/to/folder output.tsv
# Needed for types.tsv input for snakemake-mlsa-ani

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript make_fumigatus_table.R <relative_dir> <output_tsv>")
}

input_dir  <- args[1]   # e.g. "../genomes"
output_tsv <- args[2]

# List all .fna files in that directory
fna_files <- list.files(path = input_dir,
                        pattern = "\\.fna$",
                        full.names = TRUE)

if (length(fna_files) == 0) {
  stop("No .fna files found in ", input_dir)
}

# Make table: file basename (no extension) + constant species
df <- data.frame(
  tools::file_path_sans_ext(basename(fna_files)),
  rep("A. fumigatus", length(fna_files)),
  stringsAsFactors = FALSE
)

# Write TSV without header
write.table(df, file = output_tsv, sep = "\t",
            quote = FALSE, row.names = FALSE, col.names = FALSE)

message("Table written to: ", output_tsv)
