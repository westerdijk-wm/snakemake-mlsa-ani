# Log to file if running under Snakemake's log redirection
log <- file(snakemake@log[[1]], open = "wt")
sink(log, type = "message")
sink(log, type = "output", append = TRUE)

suppressMessages({
  library(ggtree)
  library(ggplot2)
  library(treeio)
})

# --- Snakemake I/O ---
input_file <- snakemake@input[["nwk"]]
output_pdf <- snakemake@output[["pdf"]]

# --- Read tree ---
tree <- read.tree(input_file)

if (is.null(tree) || length(tree$tip.label) == 0) {
  stop("Failed to read a valid tree from: ", input_file)
}

n_tips <- length(tree$tip.label)

# Bootstrap values: read.tree() stores internal node support
# (if present in the newick) in tree$node.label
has_support <- !is.null(tree$node.label) && any(nzchar(tree$node.label))

# --- Build the plot ---
p <- ggtree(tree, layout = "rectangular") +
  geom_tiplab(size = 3, align = TRUE, linesize = 0.25, offset = 0.002) +
  theme_tree2() +
  theme(
    plot.margin = margin(10, 60, 10, 10)
  )

if (has_support) {
  # coercion warning for tip labels / empty internal labels (NA by design)
  p$data$support_num <- suppressWarnings(as.numeric(p$data$label))

  p <- p +
    geom_text2(
      data = subset(p$data, !isTip & !is.na(support_num)),
      aes(label = label),
      hjust = -0.2,
      vjust = -0.4,
      size = 2.5,
      color = "firebrick"
    )
}

# Expand x-axis a bit so long tip labels aren't cut off
max_x <- max(p$data$x, na.rm = TRUE)
p <- p + xlim(0, max_x * 1.3)

# --- Scale output size to number of tips ---
plot_height <- max(4, n_tips * 0.25)
plot_width  <- 10

# --- Save output ---
ggsave(
  filename = output_pdf,
  plot = p,
  width = plot_width,
  height = plot_height,
  limitsize = FALSE
)

message("Tree plot saved to: ", output_pdf)

sink(type = "message")
sink(type = "output")