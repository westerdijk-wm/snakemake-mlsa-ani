# Configuration

The workflow is configured through [config.yaml](config.yaml)

This file defines the analysis parameters: loci selection, phylogenetic inference settings, ANI options, and optional inclusion of public genomes.

## Full configuration example

An example `config.yaml` configuration looks like this:

```yaml
genes:
  - actin
  - calmodulin
  - rpb2
  - tub2
  - cyp51A

tree:
  method: iqtree
  bootstrap: 1000

ani_method: skani

public_genomes: db/public_genomes.txt
```

## Genes (MLSA loci)

The `genes` defines which loci are extracted from genome assemblies and used for multilocus sequence analysis. Each gene corresponds to a reference locus in the `db/ref-genes.fas` database and must therefore match. 

At least one gene must be specified. You may also include a subset of the genes present in the reference database if you only want to run a reduced analysis.

## Reference gene database format

The reference loci are defined in `db/ref-genes.fas`. Each sequence must follow the required header format:

```text
>{strain}|{gene} {optional description}
```

For example:
```text
>GCA_000009125.1|actin cds-CAD16240.1
ATGCGTATTCC...
```

The header must contain a strain + gene ID separated by `|`. Each strain|gene combination must be unique. Gene names must match those defined in `config.yaml`. Additional description is allowed but ignored during parsing. 

It is also possible to include homologous genes from different strains (e.g. flavus|actin, fumigatus|actin). This enables consistent locus comparisons across taxa and is important for downstream phylogenetic inference.

## Phylogenetic inference

Phylogenetic reconstruction is configured under `tree`. The selected method determines which inference algorithm is used.

- **IQ-TREE (recommended)**
  - Model selection (MFP)
  - Ultrafast bootstrap
  - Bootstrap:
    - minimum: 100
    - recommended: ≥1000
- **RAxML**
  - Maximum likelihood inference
  - Standard bootstrap support
  - Bootstrap:
    - minimum: 1
    - recommended: ≥100
- **FastTree**
  - Very fast approximate tree
  - No bootstrap support


## ANI analysis

Configured under `ani_method`. You can specify different ANI tools:

- **skani (recommended)**
  - Fast ANI estimation
  - Scales to large datasets
  - Produces table + plot
- **FastANI**
  - Pairwise ANI computation
  - Good for bacterial datasets
- **pyani**
  - ANI + coverage-based methods
  - More detailed, slower
- **none**
  - do not run any ANI analysis

## Genome input 

Genome assemblies must be placed in the `genomes/` directory.

Supported formats are:
- .fna
- .fa
- .fasta
- .fas

Each file must contain a single genome assembly. The sample name used downstream is derived from the filename (without extension).

### Public genomes

A list of public_genomes can be specified in `db/public_genomes.txt`. They will be downloaded from NCBI and moved to the folder `public_genomes/` during execution. The genomes will automatically be incorporated in the pipeline with the local genomes. 

Example `db/public_genomes.txt`:

```text
GCA_010724455.1
GCF_000002855.4
```

Each entry must be a valid NCBI assembly accession starting with `GCA_` or `GCF_`.