library(readr)
library(gridExtra)
library(grid)
library(gtable)

input_file <- snakemake@input[["tsv"]]
output_file <- snakemake@output[["pdf"]]

df <- read_tsv(input_file, show_col_types = FALSE)

# remove rownames / row index completely
df <- as.data.frame(df, row.names = NULL)

# force character
df[] <- lapply(df, as.character)

# build table grob
tg <- tableGrob(df, rows = NULL)

# italicize all column headers except first
for (j in 2:ncol(df)) {
  idx <- which(
    tg$layout$t == 1 &
    tg$layout$l == j &
    tg$layout$name == "colhead-fg"
  )

  if (length(idx) > 0) {
    tg$grobs[[idx]]$gp <- gpar(fontface = "italic")
  }
}

# outer border
tg <- gtable_add_grob(
  tg,
  grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
  t = 2, b = nrow(tg), l = 1, r = ncol(tg)
)

# header border
tg <- gtable_add_grob(
  tg,
  grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
  t = 1, l = 1, r = ncol(tg)
)

# -------------------------
# AUTO-SIZE PDF TO TABLE
# -------------------------

pdf(
  NULL,
  width = 1,
  height = 1
)

w <- convertWidth(
  sum(tg$widths),
  "in",
  valueOnly = TRUE
)

h <- convertHeight(
  sum(tg$heights),
  "in",
  valueOnly = TRUE
)

invisible(dev.off())

margin <- 0.05

# -------------------------
# FINAL OUTPUT
# -------------------------

pdf(
  output_file,
  width = w + margin,
  height = h + margin,
  useDingbats = FALSE
)

grid.draw(tg)

invisible(dev.off())