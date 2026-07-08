Genome analysis pipeline report
================================

This report summarises a modular comparative genomics workflow implemented in
Snakemake. The pipeline covers the following stages:

**Genome acquisition and QC**
  Public genomes are downloaded from NCBI (rule ``get_genome``) and assessed
  with QUAST (rule ``quast``).

**Gene extraction**
  Reference genes are validated (rule ``validate_ref_genes``), mapped against
  each assembly with minimap2 (rule ``minimap2``), filtered, realigned, and
  deduplicated (rules ``sam_filter``, ``sam_realign``, ``sam_extract_hit_seq``,
  ``rename_extracted_hit_seq``, ``join_fragments``, ``genes_deduplicate``).

**Gene QC and filtering**
  Pooled gene hits are assessed for presence, copy number, and fragmentation
  (rule ``genes_qc``). Only samples with all loci present as a single
  unfragmented copy proceed to downstream analyses.

**Phylogenetic reconstruction**
  Per-gene alignments are produced with MUSCLE (rule ``align``), concatenated
  into a supermatrix (rule ``concat``), and used to infer a maximum-likelihood
  tree with IQ-TREE, RAxML, or FastTree. The final tree is midpoint-rerooted
  (rule ``reroot_tree``).

**Average Nucleotide Identity**
  Pairwise ANI is computed using skani, FastANI, or pyANI (configurable),
  reshaped into a square matrix (rule ``ani_table``), and co-visualised with
  the phylogeny (rule ``ani_plot``).

All outputs are automatically generated.