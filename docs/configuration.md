# Configuration

The workflow is configured through [config.yaml](../config.yaml).

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

| Key | Required | Description |
|---|---|---|
| `genes` | Yes | List of MLSA loci to extract and analyze. |
| `tree.method` | Yes | Phylogenetic inference method (`iqtree`, `raxml`, `fasttree`). |
| `tree.bootstrap` | Depends on method | Number of bootstrap replicates. |
| `ani_method` | Yes | ANI tool to use (`skani`, `fastani`, `pyani`, `none`). |
| `public_genomes` | No | Path to a file listing NCBI accessions to include. |

---

## Genes (MLSA loci)

`genes` defines which loci are extracted from genome assemblies and used for multilocus sequence analysis. Each gene corresponds to a reference locus in the `db/ref-genes.fas` database and the names must match exactly.

- At least one gene must be specified.
- You may specify a subset of the genes present in the reference database to run a reduced analysis.

---

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

Requirements:

- The header must contain a strain ID and gene name separated by `|`.
- Each `strain|gene` combination must be unique.
- Gene names must match those defined in `config.yaml`.
- Any text after the first space is treated as an optional description and is ignored during parsing.

It is also possible to include homologous genes from different strains (e.g. `flavus|actin`, `fumigatus|actin`). This enables consistent locus comparisons across taxa and is important for downstream phylogenetic inference.

---

## Phylogenetic inference

Phylogenetic reconstruction is configured under `tree`. The selected `method` determines which inference algorithm is used.

### `iqtree` (recommended)

- Automatic model selection (ModelFinder Plus, `-m MFP`)
- Ultrafast bootstrap approximation
- Bootstrap (`tree.bootstrap`):
  - Minimum: 100 (lower values raise an error)
  - Recommended: ≥ 1000 (lower values trigger a warning)

### `raxml`

- Maximum likelihood inference
- Standard bootstrap support
- Bootstrap (`tree.bootstrap`):
  - Minimum: 1 (lower values raise an error)
  - Recommended: ≥ 100 (lower values trigger a warning)

### `fasttree`

- Very fast approximate tree inference
- No bootstrap support
- `tree.bootstrap` is ignored if set (a warning is printed)

---

## ANI analysis

Configured under `ani_method`. Available options:

### `skani` (recommended)

- Fast ANI estimation
- Scales well to large datasets

### `fastani`

- Pairwise ANI computation
- Relatively fast

### `pyani`

- ANI plus coverage-based methods
- Relatively slow

### `none`

- Disables ANI analysis entirely; no ANI rules are included in the workflow

---

## Genome input

Genome assemblies must be placed in the `genomes/` directory.

Supported file extensions:

- `.fna`
- `.fa`
- `.fasta`
- `.fas`

Each file must contain a single genome assembly. The sample name used downstream is derived from the filename (without extension).

### Public genomes

A list of public genome accessions can be specified via `public_genomes` in `config.yaml`, pointing to a text file (e.g. `db/public_genomes.txt`).

- Listed genomes are downloaded from NCBI and placed in `public_genomes/`.
- They are automatically merged with local genomes from `genomes/` for all downstream analyses.
- Lines starting with `#` and empty lines are ignored.

Example `db/public_genomes.txt`:

```text
GCA_010724455.1
GCF_000002855.4
```

Each entry must be a valid NCBI assembly accession starting with `GCA_` or `GCF_`.