#!/usr/bin/env Rscript
library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
input_file  <- args[1]
output_file <- args[2]

# Read the report
df <- read.delim(input_file, header=FALSE,
                 col.names = c("Sample","Gene","Value"),
                 stringsAsFactors = FALSE)

# All genes present across all samples
all_genes <- unique(df$Gene)

# Duplicates: Value > 1
dups <- df %>%
  filter(Value > 1) %>%
  mutate(dup_str = paste0(Gene, " (", Value, "x)")) %>%
  group_by(Sample) %>%
  summarise(duplicates = paste(dup_str, collapse = ", "), .groups="drop")

# Missing genes
missing <- df %>%
  group_by(Sample) %>%
  summarise(missing_genes = paste(setdiff(all_genes, Gene), collapse = ", "), .groups="drop")

# Merge and filter interesting samples
summary_tbl <- full_join(missing, dups, by = "Sample") %>%
  mutate(
    missing_genes = ifelse(is.na(missing_genes), "", missing_genes),
    duplicates    = ifelse(is.na(duplicates), "", duplicates)
  ) %>%
  filter(missing_genes != "" | duplicates != "")

# Write output
if(nrow(summary_tbl) == 0){
  write.table(
    data.frame(Message="All samples have all genes and no duplicates."),
    file = output_file,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE
  )
} else {
  write.table(summary_tbl, file = output_file, sep = "\t", quote = FALSE, row.names = FALSE)
}