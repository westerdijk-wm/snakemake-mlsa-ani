# Methods

The workflow performs multilocus sequence analysis (MLSA), phylogenetic inference, and Average Nucleotide Identity (ANI) analysis directly from assembled genome sequences.

## Workflow overview

[workflow overview figure here]

## Software overview

The workflow integrates established bioinformatics tools together with custom scripts for quality control, data transformation, and visualization.

| Component                             | Purpose                                   |
| ------------------------------------- | ----------------------------------------- |
| Snakemake                             | Workflow management                       |
| Minimap2                              | Reference gene mapping                    |
| SAMtools and associated SAM utilities | Alignment processing and locus extraction |
| MUSCLE                                | Multiple sequence alignment               |
| QUAST                                 | Genome assembly quality assessment        |
| IQ-TREE                               | Maximum-likelihood phylogenetic inference |
| RAxML                                 | Maximum-likelihood phylogenetic inference |
| FastTree                              | Rapid phylogenetic inference              |
| FastANI                               | Pairwise ANI calculation                  |
| skani                                 | Pairwise ANI calculation                  |
| pyani (ANIm)                          | ANI and alignment coverage analysis       |
| R                                     | Visualization and reporting               |
| Python                                | Quality control and data processing       |

Software versions are defined through the workflow Conda environments located in `workflow/envs/`, ensuring reproducible analyses.

## Input genomes

Genome assemblies are supplied through the `genomes/` directory and may be provided in FASTA format (`.fna`, `.fasta`, `.fas`, `.fa`).

Optionally, additional public genomes can be downloaded directly from NCBI using accession numbers listed in `public_genomes.txt`. Downloaded assemblies are incorporated into the workflow and processed identically to local genomes.

## Reference gene validation

Reference loci are supplied in `db/ref-genes.fas`.

Prior to analysis, the reference database is validated using the custom script `validate-ref-genes.py`. This step verifies FASTA formatting, header structure, and the uniqueness of all `strain|gene` identifiers.

The validated database is subsequently used throughout all mapping and quality-control steps.

## Assembly quality assessment

Assembly quality is evaluated using [QUAST](https://quast.sourceforge.net/).

Reported metrics include:

* Total assembly length
* Number of contigs
* N50
* GC content

These statistics provide an overview of assembly completeness and contiguity before downstream analyses.

## Reference gene mapping and locus extraction

Reference genes are identified within each genome using [Minimap2](https://github.com/lh3/minimap2).

Initial mappings are filtered to retain only the highest-scoring hits before being refined using the custom script `sam-realign.pl`.

Candidate loci are subsequently extracted from genome assemblies using SAM-based utility scripts. Only hits with a minimum sequence similarity of 70% are retained.

Extracted sequences are standardized using `rename-extracted-hit-fasta.pl`, producing FASTA headers in a consistent `sample|gene` format.

## Gene quality control

All extracted loci are pooled and evaluated using the custom script `genes-qc.py`.

For each sample-gene combination, the workflow determines:

* Copy number
* Alignment coverage
* Sequence similarity
* Relative gene length

Genes are classified according to the following criteria:

| Status     | Description                             |
| ---------- | --------------------------------------- |
| OK         | Single-copy gene passing all thresholds |
| DUPLICATED | Multiple copies detected                |
| FRAGMENTED | Coverage < 95% or length ratio < 0.90   |
| MISSING    | Gene not detected                       |

Gene lengths are compared against the validated reference gene database.

A genome is considered to pass QC only when all target loci are classified as **OK**. Genomes containing missing, duplicated, or fragmented loci are excluded from subsequent MLSA and ANI analyses.

The workflow additionally generates:

* Detailed gene QC table
* Sample-level QC summary
* Gene presence/absence matrix
* List of genomes passing all QC criteria

## Multiple sequence alignment

For each locus, sequences from all passing genomes are aligned independently using [MUSCLE](https://www.drive5.com/muscle/).

This produces one alignment per gene, preserving locus-specific evolutionary signal while minimizing the influence of missing data.

## Alignment concatenation

Individual locus alignments are combined into a single MLSA supermatrix using `fasta_autoconcatenate`.

During this step, the workflow also generates partition information describing locus boundaries within the concatenated alignment.

These partition definitions are subsequently used by partition-aware phylogenetic methods.

## Phylogenetic inference

Phylogenetic reconstruction is performed using one of three selectable methods.

### IQ-TREE

When selected, [IQ-TREE](https://iqtree.github.io/) performs maximum-likelihood inference using:

* Partitioned analysis
* ModelFinder Plus (MFP) model selection
* Ultrafast bootstrap support estimation

The number of bootstrap replicates is user configurable.

### RAxML

When selected, [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/) performs maximum-likelihood inference using:

* GTR+GAMMA substitution model
* Partitioned analysis
* Rapid bootstrap analysis

Bootstrap support values are generated using the user-specified number of replicates.

### FastTree

When selected, [FastTree](http://www.microbesonline.org/fasttree/) performs approximate maximum-likelihood inference using:

* General Time Reversible (GTR) model
* Gamma-distributed rate heterogeneity

FastTree provides a computationally efficient alternative for larger datasets.

### Tree rooting

The resulting phylogeny is midpoint-rooted using `nw_reroot` from the Newick Utilities package and exported in Newick format.

## Average Nucleotide Identity (ANI)

ANI analysis is optional and is performed only on genomes that pass all gene QC criteria.

### FastANI

[FastANI](https://github.com/ParBLiSS/FastANI) computes pairwise average nucleotide identity values between all passing genomes.

Pairwise results are converted into a symmetric similarity matrix using the custom script `ani2table.py`.

### skani

[skani](https://github.com/bluenote-1577/skani) computes pairwise ANI values using the triangle algorithm and similarly generates a symmetric ANI matrix.

### pyani

[pyani](https://github.com/widdowquinn/pyani) performs ANI analysis using the ANIm method.

Generated outputs include:

* Percentage identity matrices
* Alignment coverage matrices

For visualization purposes, ANI values are converted into distance matrices using `ani2distance-phylip.pl`, after which a neighbour-joining tree is generated using `nj-for-dist-matrix.R`.

## Visualization and reporting

The workflow generates publication-ready reports and figures throughout the analysis.

Custom scripts are used to produce:

* Gene presence/absence matrix visualizations
* ANI similarity heatmaps
* Tree-integrated ANI visualizations

ANI visualizations combine phylogenetic trees with genome similarity matrices, enabling direct comparison between MLSA-based phylogenetic relationships and whole-genome nucleotide identity.

## Reproducibility

The workflow is implemented in Snakemake and distributed with Conda environments for reproducible software installation and execution.

All analyses are fully automated and reproducible from the supplied genome assemblies, reference gene database, and configuration file.
