Average Nucleotide Identity (ANI)
==================================

Pairwise genome similarity was calculated for all samples passing gene QC
(rule ``genes_qc``) using the configured ANI method (skani, FastANI, or pyANI;
rules ``skani``, ``fastani``, or ``pyani``). Pairwise output was reshaped into
a square identity matrix (rule ``ani_table``) and visualised alongside the MLSA
phylogeny (rule ``ani_plot``).

Interpretation:

- Values close to 100% indicate near-identical genomes.
- Values below approximately 95% typically indicate species-level divergence.

The resulting matrix, combined with the MLSA phylogeny, supports species
delineation and clustering analysis.