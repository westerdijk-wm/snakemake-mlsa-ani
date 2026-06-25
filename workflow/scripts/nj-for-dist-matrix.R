#!/usr/bin/env Rscript

options(warn = 0)

message("Executing R script for NJ tree")

library(ape)
library(phangorn)

# Snakemake I/O
infile <- snakemake@input[["tsv"]]
outfile <- snakemake@output[["tree"]]

# Read distance matrix (headless TSV)
dist <- read.table(
    infile,
    sep = "\t",
    header = FALSE,
    row.names = 1,
    check.names = FALSE
)

# restore column names
colnames(dist) <- rownames(dist)
# Create NJ tree
tree <- ape::nj(as.dist(dist))
# Midpoint root
tree <- midpoint(tree)

# Write Newick
write.tree(tree, file = outfile)