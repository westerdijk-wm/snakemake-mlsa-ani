#!/usr/bin/env Rscript

options(warn=0) #Set this value back to 0 if you want to display Rscript warnings in the terminal.

args <- commandArgs(trailingOnly = TRUE)

say = function(x) {
    write(x, stdout())
}

die = function(error) {
  say(paste("ERROR:", error))
  say("USAGE:")
  say("\tnj-for-dist-matrix.R <tab-separated table> <newick tree file>")
  say("\tWarning: The tab-separated table needs to be symmetrical table (rownames and colnames have to be the same.)")
  .Internal(.invokeRestart(list(NULL, NULL), NULL))
}

if (length(args) != 2) {
   die("The script requires exactly two arguments.")
}


say("Executing R script for NJ tree")

library('ape')
library('phangorn')

# infile <- "dist.tsv"
# outfile <- "nj.nwk"

# Arguments:
# Input distance TSV (headless)
infile <- args[1]
# Output newick
outfile <- args[2]

dist <- read.table(infile, sep="\t", header=F, row.names=1)
colnames(dist) <- rownames(dist)
# Create NJ tree
tree <- ape::nj( as.dist(dist) )
# midpoint reroot
tree <- midpoint(tree)
# write newick file
write.tree(tree, file=outfile)
