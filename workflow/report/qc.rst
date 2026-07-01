Genome quality control (QUAST)
===============================

Assembly quality was assessed for each genome using QUAST (rule ``quast``).

Metrics include:

- Number of contigs
- Total assembly length
- N50
- GC content

These results are used to evaluate genome completeness and contiguity prior to
gene extraction (rules ``minimap2`` through ``genes_deduplicate``), phylogenetic
reconstruction, and ANI analysis.