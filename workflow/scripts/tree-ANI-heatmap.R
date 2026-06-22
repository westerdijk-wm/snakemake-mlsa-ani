#!/usr/bin/env Rscript
# Adapted from https://github.com/b-brankovics/ani-typer

options(warn = 0)

args <- commandArgs(trailingOnly = TRUE)

say <- function(x) write(x, stdout())

die <- function(error) {
  say(paste("ERROR:", error))
  say("USAGE:")
  say("\ttree-heatmap.R <newick tree file> <tab-separated table> [<output file>] [<label_tsv>]")
  say("\tWarning: table must be symmetrical (rownames == colnames)")
  quit(status = 1)
}

if (length(args) < 2) {
  die("The script requires at least two arguments.")
}

say("Executing R script for plotting tree and heatmap")

# -------------------------
# LIBRARIES
# -------------------------
suppressPackageStartupMessages(library(dendextend))
suppressPackageStartupMessages(library(phylogram))
suppressPackageStartupMessages(library(phangorn))
suppressPackageStartupMessages(library(ComplexHeatmap))
suppressPackageStartupMessages(library(circlize))
suppressPackageStartupMessages(library(ape))

# -------------------------
# INPUTS
# -------------------------
newick <- args[1]
infile <- args[2]
plotfile <- ifelse(length(args) > 2, args[3], "heatmap.pdf")

labels_file <- NULL
label_map <- NULL
rename <- NULL

if (
  length(args) > 3 &&
  args[4] != "" &&
  file.exists(args[4])
) {
  labels_file <- args[4]
}

# -------------------------
# TREE
# -------------------------
tree <- ape::read.tree(newick)

# -------------------------
# OPTIONAL RELABELING
# -------------------------
if (!is.null(labels_file)) {

  say(paste("Using labels from", labels_file))

  label_map <- read.table(
    labels_file,
    sep = "\t",
    header = TRUE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (!all(c("Genome", "Sample") %in% colnames(label_map))) {
    die("Label TSV must contain columns: Genome and Sample")
  }

  rename <- setNames(
    label_map$Sample,
    label_map$Genome
  )

  tree$tip.label <- ifelse(
    tree$tip.label %in% names(rename),
    rename[tree$tip.label],
    tree$tip.label
  )

} else {

  say("No label file supplied; using original IDs.")
}

force.ultrametric <- function(tree, method = c("nnls", "extend")) {

  method <- method[1]

  if (method == "nnls") {

    tree <- nnls.tree(
      cophenetic(tree),
      tree,
      rooted = TRUE,
      trace = 0
    )

  } else if (method == "extend") {

    h <- diag(vcv(tree))
    d <- max(h) - h

    ii <- sapply(
      1:Ntip(tree),
      function(x, y) which(y == x),
      y = tree$edge[, 2]
    )

    tree$edge.length[ii] <-
      tree$edge.length[ii] + d

  } else {

    say("method not recognized: returning input tree")
  }

  tree
}

ultra <- force.ultrametric(tree)

dendro <- as.dendrogram.phylo(ultra)

coldendrogram <-
  rev(
    dendro %>%
      set("branches_lwd", 1.5)
  )

# -------------------------
# MATRIX LOADING
# -------------------------
d <- read.table(
  infile,
  sep = "\t",
  header = TRUE,
  row.names = 1,
  check.names = FALSE
)

# fallback header fix
if (!identical(
  sort(colnames(d)),
  sort(rownames(d))
)) {

  col <- read.table(
    infile,
    sep = "\t",
    header = FALSE,
    row.names = 1,
    nrows = 2,
    check.names = FALSE
  )

  colnames(d) <- col[1, ]
}

# final validation
if (!identical(
  sort(colnames(d)),
  sort(rownames(d))
)) {

  die(
    "Symmetric table required (rownames must match colnames)."
  )
}

# optional matrix relabel
if (!is.null(rename)) {

  rownames(d) <- ifelse(
    rownames(d) %in% names(rename),
    rename[rownames(d)],
    rownames(d)
  )

  colnames(d) <- ifelse(
    colnames(d) %in% names(rename),
    rename[colnames(d)],
    colnames(d)
  )
}

# validate tree ↔ matrix
if (!identical(
  sort(colnames(d)),
  sort(tree$tip.label)
)) {

  die("Tree IDs do not match matrix IDs.")
}

# -------------------------
# ORDERING
# -------------------------
d <- d[
  tree$tip.label,
  tree$tip.label
]

data <- as.matrix(d)

mode(data) <- "numeric"

# -------------------------
# OUTPUT
# -------------------------
pdf(
  file = plotfile,
  width = 12,
  height = 12,
  pointsize = 8
)

# -------------------------
# COLOR SCALE
# -------------------------
vals <- data[
  lower.tri(data) |
  upper.tri(data)
]

vals <- vals[!is.na(vals)]

global_min <- min(vals)
global_max <- max(vals)

say(
  paste(
    "Matrix range:",
    global_min,
    "to",
    global_max
  )
)

# -------------------------
# AUTO DETECT SCALE
# -------------------------
is_fraction <- global_max <= 1.5

if (is_fraction) {

  say(
    "Detected: fractional similarity matrix (0–1 scale)"
  )

  cutoff <- 0.95

  min_val <- as.numeric(
    quantile(
      vals,
      probs = 0.02,
      na.rm = TRUE
    )
  )

  max_val <- 1

  if (
    is.na(min_val) ||
    min_val > cutoff
  ) {
    min_val <- cutoff - 0.1
  }

} else {

  say(
    "Detected: percentage-like matrix (0–100 scale)"
  )

  cutoff <- 95

  min_val <- as.numeric(
    quantile(
      vals,
      probs = 0.02,
      na.rm = TRUE
    )
  )

  max_val <- 100

  if (
    is.na(min_val) ||
    min_val > cutoff
  ) {
    min_val <- cutoff - 10
  }
}

col_fun <- colorRamp2(
  c(max_val, cutoff, min_val),
  c("darkgreen", "yellow", "red")
)

# -------------------------
# PLOT
# -------------------------
say("Generating heatmap plot")

Heatmap(
  data,
  name = "ANI",

  cluster_rows = coldendrogram,
  cluster_columns = coldendrogram,

  col = col_fun,
  column_title = "ANI",

  # small but important improvement
  show_row_names = TRUE,
  show_column_names = TRUE,

  row_names_gp = gpar(
    fontsize = 11
  ),

  column_names_gp = gpar(
    fontsize = 11
  ),

  rect_gp = gpar(
    col = "grey90",
    lwd = 0.3
  )
)

invisible(dev.off())

say("Finished R script for plotting.")