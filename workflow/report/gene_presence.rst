Gene presence/absence matrix
=============================

Overview of MLSA locus copy numbers across all samples, produced by rule
``genes_qc`` and visualised by rule ``table_plot``.

Values represent the number of times each locus was detected per genome:

- ``0``: gene absent
- ``1``: gene present (single copy, expected)
- ``2+``: gene duplicated

Fragmentation is assessed separately based on alignment coverage and length
ratio relative to the reference (rules ``sam_realign``, ``sam_extract_hit_seq``).

Only genomes with all loci present as a single unfragmented copy pass quality
control and are carried forward into MLSA and ANI analyses.