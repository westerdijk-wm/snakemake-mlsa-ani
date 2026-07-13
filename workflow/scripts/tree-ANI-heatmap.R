#!/usr/bin/env Rscript
# Adapted from https://github.com/b-brankovics/ani-typer

options(warn = -1)

newick      <- snakemake@input[["tree"]]
infile      <- snakemake@input[["ani"]]
plotfile    <- snakemake@output[["pdf"]]
log <- file(snakemake@log[[1]], open = "wt")
sink(log, type = "output")
sink(log, type = "message")

say <- function(x) write(x, stdout())

die <- function(error) {
  say(paste("ERROR:", error))
  quit(status = 1)
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
suppressPackageStartupMessages(library(grid))

# -------------------------
# SIZE SETTINGS
# -------------------------
plot_width <- 20
plot_height <- 18
base_pointsize <- 14
label_fontsize <- 25
legend_title_fontsize <- 24
legend_label_fontsize <- 21
title_fontsize <- 26
dendrogram_lwd <- 2.4
cell_border_lwd <- 0.45

# -------------------------
# TREE
# -------------------------
tree <- ape::read.tree(newick)

# -------------------------
# TREE PROCESSING
# -------------------------
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
    extension <- max(h) - h

    ii <- sapply(
      1:Ntip(tree),
      function(x, y) which(y == x),
      y = tree$edge[, 2]
    )

    tree$edge.length[ii] <-
      tree$edge.length[ii] + extension
  }

  tree
}

ultra <- force.ultrametric(tree)

dendro <- as.dendrogram.phylo(ultra)

coldendrogram <-
  rev(
    dendro %>%
      set("branches_lwd", dendrogram_lwd)
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

# validation
if (!identical(
  sort(colnames(d)),
  sort(rownames(d))
)) {
  die("Symmetric table required (rownames must match colnames).")
}

# validate tree ↔ matrix
if (!identical(
  sort(colnames(d)),
  sort(tree$tip.label)
)) {
  die("Tree IDs do not match matrix IDs.")
}

# ordering
d <- d[
  tree$tip.label,
  tree$tip.label
]

data <- as.matrix(d)
mode(data) <- "numeric"

# -------------------------
# FORMAT LABELS FOR ITALICS
# -------------------------
format_species <- function(x) {

  pattern <- "^((?:[A-Z]\\.|[A-Z][a-z]+)\\s+[a-z-]+)(.*)$"

  out <- x

  hit <- grepl(pattern, x)

  out[hit] <- sapply(
    x[hit],
    function(label) {

      m <- regexec(pattern, label)
      p <- regmatches(label, m)[[1]]

      species <- trimws(p[2])
      rest <- trimws(p[3])

      if (rest == "") {
        paste0("italic('", species, "')")
      } else {
        paste0(
          "paste(italic('",
          species,
          "'),' ",
          rest,
          "')"
        )
      }
    }
  )

  out
}

row_labels <- parse(text = format_species(rownames(data)))
col_labels <- parse(text = format_species(colnames(data)))

# -------------------------
# OUTPUT
# -------------------------
vals <- data[lower.tri(data) | upper.tri(data)]
vals <- vals[!is.na(vals)]

global_min <- min(vals)
global_max <- max(vals)

cutoff <- ifelse(global_max <= 1.5, 0.95, 95)
max_val <- ifelse(global_max <= 1.5, 1, 100)

min_val <- as.numeric(quantile(vals, probs = 0.02, na.rm = TRUE))

col_fun <- colorRamp2(
  c(min_val, cutoff, max_val),
  c("red", "yellow", "darkgreen")
)

legend_breaks <- seq(min_val, max_val, length.out = 5)

legend_labels <- if (global_max <= 1.5) {
  sprintf("%.2f", legend_breaks)
} else {
  sprintf("%.1f", legend_breaks)
}

say("Generating heatmap plot")

ht <- Heatmap(
  data,
  name = "ANI",
  cluster_rows = coldendrogram,
  cluster_columns = coldendrogram,
  col = col_fun,
  row_labels = row_labels,
  column_labels = col_labels,
  row_names_gp = gpar(fontsize = label_fontsize),
  column_names_gp = gpar(fontsize = label_fontsize),
  column_names_rot = 45,
  column_names_max_height = unit(6, "cm"),
  row_names_max_width = unit(7, "cm"),
  row_dend_gp = gpar(lwd = dendrogram_lwd),
  column_dend_gp = gpar(lwd = dendrogram_lwd),
  rect_gp = gpar(col = "grey90", lwd = cell_border_lwd),
  column_title = "ANI",
  column_title_gp = gpar(
    fontsize = title_fontsize,
    fontface = "bold"
  ),
  heatmap_legend_param = list(
    title = "ANI",
    title_gp = gpar(
      fontsize = legend_title_fontsize,
      fontface = "bold"
    ),
    labels_gp = gpar(
      fontsize = legend_label_fontsize
    ),
    at = legend_breaks,
    labels = legend_labels
  )
)

pdf(
  plotfile,
  width = plot_width,
  height = plot_height,
  pointsize = base_pointsize,
  useDingbats = FALSE
)

on.exit(dev.off(), add = TRUE)

draw(
  ht,
  heatmap_legend_side = "right",
  padding = unit(c(10, 18, 10, 10), "mm"),
  newpage = FALSE
)