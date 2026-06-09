library(readr)
library(gridExtra)
library(grid)
library(gtable)

input_file <- snakemake@input[["tsv"]]
output_file <- snakemake@output[["pdf"]]

df <- read_tsv(input_file, show_col_types = FALSE)

# remove rownames / row index completely
df <- as.data.frame(df, row.names = NULL)

# force character (avoids formatting surprises)
df[] <- lapply(df, as.character)

# build table grob
tg <- tableGrob(df, rows = NULL)

tg <- gtable_add_grob(tg,
        grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
        t = 2, b = nrow(tg), l = 1, r = ncol(tg))
tg <- gtable_add_grob(tg,
        grobs = rectGrob(gp = gpar(fill = NA, lwd = 2)),
        t = 1, l = 1, r = ncol(tg))

# Render
pdf(output_file, width = 14, height = 8)
grid.newpage()
grid.draw(tg)
dev.off()


