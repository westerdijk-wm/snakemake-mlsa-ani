Gene extraction and quality control
===================================

This step evaluates the recovery of reference genes across all genomes.

Workflow steps:
- Mapping reads/genomes against validated reference gene set
- Filtering low-quality hits based on alignment similarity
- Extracting locus sequences per genome
- Filtering gene sets for downstream phylogenetic inference

The final output contains a curated gene dataset used for MLSA alignment.