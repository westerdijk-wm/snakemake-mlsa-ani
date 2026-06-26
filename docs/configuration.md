# Configuration

The workflow is configured through [`config/config.yaml`](../config/config.yaml).

This file defines the analysis parameters: loci selection, phylogenetic
inference settings, ANI options, and optional inclusion of public genomes.

## Full configuration example

An example `config.yaml` configuration looks like this:

```yaml
# Gene configuration — names must match headers in ref-genes.fas exactly
genes:
  - calmodulin
  - actin
  - rpb2
  - benA

# Tree configuration
tree:
  method: iqtree    # iqtree | raxml | fasttree
  bootstrap: 1000

# ANI configuration
ani_method: skani   # skani | fastani | pyani | none

# Reference gene database
ref_genes: config/ref-genes.fas

# Optional: public genomes to download from NCBI
accessions: config/public_genomes.txt

# Optional: relabel genome IDs in phylogeny and ANI plots
# sample_labels: config/sample_metadata.tsv
```

| Key | Required | Description |
|---|---|---|
| `genes` | Yes | List of MLSA loci to extract and analyze. |
| `tree.method` | Yes | Phylogenetic inference method (`iqtree`, `raxml`, `fasttree`). |
| `tree.bootstrap` | Depends on method | Number of bootstrap replicates. |
| `ani_method` | Yes | ANI tool to use (`skani`, `fastani`, `pyani`, `none`). |
| `ref_genes` | Yes | Path to the reference gene FASTA database. |
| `accessions` | No | Path to TSV listing NCBI accessions to download. |
| `sample_labels` | No | Path to TSV file to replace genome IDs with readable labels in phylogeny and ANI plots. |


## Genes (MLSA loci)

`genes` defines which loci are extracted from genome assemblies and used for
multilocus sequence analysis. Each gene corresponds to a reference locus in
the reference gene database and the names must match exactly.

- At least one gene must be specified.
- You may specify a subset of the genes present in the reference database to
  run a reduced analysis.


## Reference gene database format

The reference loci are defined in the file pointed to by `ref_genes`
(default: `config/ref-genes.fas`). Each sequence must follow the required
header format:

```text
>{strain}|{gene} {optional description}
```

For example:

```text
>Af293|actin NC_007199.1:c1114851-1113100 act1
AAGAAGTTGCTGCTCTCGTCATCGACAATGGGTATGTCTTTTATCTTCAG.....
```

Requirements:

- The header must contain a strain ID and gene name separated by `|`.
- Each `strain|gene` combination must be unique.
- Gene names must match those listed under `genes` in `config.yaml`.
- Any text after the first space is treated as an optional description and is
  ignored during parsing.

It is also possible to include homologous genes from different strains (e.g.
`flavus|actin`, `fumigatus|actin`). This enables consistent locus comparisons
across taxa and is important for downstream phylogenetic inference.

The database is validated automatically at the start of each run. See
[Outputs](outputs.md) for details on validation results.


## Phylogenetic inference

Phylogenetic reconstruction is configured under `tree`. The selected `method`
determines which inference algorithm is used.

### `iqtree` (recommended)

- Automatic model selection (ModelFinder Plus, `-m MFP`)
- Ultrafast bootstrap approximation
- Bootstrap (`tree.bootstrap`):
  - Minimum: 100 (lower values raise an error)
  - Recommended: ≥ 1000 (lower values trigger a warning)

### `raxml`

- Maximum likelihood inference under GTR+GAMMA
- Standard bootstrap support
- Bootstrap (`tree.bootstrap`):
  - Minimum: 1 (lower values raise an error)
  - Recommended: ≥ 100 (lower values trigger a warning)

### `fasttree`

- Very fast approximate tree inference under GTR+GAMMA
- No bootstrap support
- `tree.bootstrap` is ignored if set (a warning is printed)


## ANI analysis

Configured under `ani_method`. Available options:

### `skani` (recommended)

- Fast sketch-based ANI estimation
- Scales well to large genome sets

### `fastani`

- Pairwise ANI computation
- Relatively fast

### `pyani`

- ANIm-based ANI and alignment coverage analysis
- Relatively slow; produces both identity and coverage matrices

### `none`

- Disables ANI analysis entirely; no ANI rules are included in the workflow


## Genome input

Genome assemblies must be placed in the `genomes/` directory.

Supported file extensions:

- `.fna`
- `.fa`
- `.fasta`
- `.fas`

Each file must contain a single genome assembly. The sample name used
downstream is derived from the filename (without extension).

### Public genomes

Additional public genomes can be specified via `accessions` in `config.yaml`,
pointing to a tab-separated file (default: `config/public_genomes.txt`) with
a `sample` column and an `assembly` column:

```text
sample    assembly
Af293     GCA_000002655.1
A1163     GCA_000150145.1
IFM58399  GCA_010724455.1
PK20-01   GCA_023625555.1
IFM46973  GCA_001078395.2
IFM46972  GCA_010723835.1
NRRL181   GCA_000149645.4
NRRL4585  GCA_014250575.1
```

- `sample` is the name used for that genome throughout the workflow.
- `assembly` must be a valid NCBI assembly accession (`GCA_` or `GCF_`).
- Downloaded assemblies are placed in `resources/public_genomes/` and
  processed identically to local genomes from `genomes/`.

### Optional sample relabeling (tree + ANI plots)

The workflow supports optional relabeling of genome identifiers in downstream
visualizations (phylogenetic tree and ANI heatmaps), controlled via
`sample_labels` in `config.yaml`:

```yaml
sample_labels: config/sample_metadata.tsv
```

The file must be tab-separated with two columns:

```text
sample    assembly
Af293     GCA_000002655.1
A1163     GCA_000150145.1
```

Where `assembly` is the exact genome identifier used in the workflow and
`sample` is the display label used in tree and ANI heatmap outputs.

- If `sample_labels` is not set, raw genome IDs are used.
- If only a partial mapping exists, only matching genomes are relabeled.


## Compute resources

The number of threads available to the workflow is controlled via Snakemake's
`--cores` option:

```bash
snakemake --cores 10 --use-conda
```

Most rules use `threads: workflow.cores` and will use all available cores. A
few rules (gene extraction, alignment, concatenation) request
`min(4, workflow.cores)` threads, since these steps rarely benefit from more
than 4 threads per task. If `--cores` is set below 4, these rules
automatically scale down to the available core count.

Running with very few cores (e.g. `--cores 2`) is supported and will not cause
errors, but will increase runtime, particularly for QUAST, minimap2, IQ-TREE,
and ANI computation.