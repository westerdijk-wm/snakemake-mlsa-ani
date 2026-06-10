# Configuration

The workflow is configured through [config.yaml](config.yaml)

This file defines all analysis parameters, including loci selection, phylogenetic inference settings, ANI options, and optional inclusion of public genomes.

---

# Full configuration example

A minimal working configuration:

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

---

# Genes (MLSA loci)

The `genes` field defines which loci are extracted from genome assemblies and used for multilocus sequence analysis.

Example:

genes:
  - actin
  - calmodulin
  - rpb2

## Requirements

- At least one gene must be specified  
- Gene names must match entries in `db/ref-genes.fas`  
- Each gene represents a locus used for:
  - sequence extraction
  - multiple sequence alignment
  - concatenated phylogeny

---

## Reference gene database format

Location:

`db/ref-genes.fas`

Header format:

>{strain}|{gene} {optional description}

Example:

>GCA_000009125.1|actin cds-CAD16240.1
ATGCGT...

## Requirements

- Headers must contain strain + gene separated by `|`
- Each strain|gene must be unique
- Gene names must match config.yaml
- Additional description is allowed but ignored

---

# Phylogenetic inference

Configured under `tree`:

tree:
  method: iqtree
  bootstrap: 1000

---

## IQ-TREE (recommended)

tree:
  method: iqtree
  bootstrap: 1000

- Model selection (MFP)
- Ultrafast bootstrap
- Recommended for most datasets

Bootstrap:
- minimum: 100
- recommended: ≥1000

---

## RAxML

tree:
  method: raxml
  bootstrap: 1000

- Maximum likelihood inference
- Standard bootstrap support

Bootstrap:
- minimum: 1
- recommended: ≥100

---

## FastTree

tree:
  method: fasttree

- Very fast approximate tree
- No bootstrap support

Note: bootstrap value is ignored

---

# ANI analysis

ani_method: skani

---

## Disable ANI

ani_method: none

---

## skani (recommended)

ani_method: skani

- Fast ANI estimation
- Scales to large datasets
- Produces table + plot

---

## FastANI

ani_method: fastani

- Pairwise ANI computation
- Good for bacterial datasets

---

## PyANI

ani_method: pyani

- ANI + coverage-based methods
- More detailed, slower

---

# Public genomes

public_genomes: db/public_genomes.txt

## File format

GCF_010724455.1
GCF_000149645.3

- blank lines ignored
- lines starting with # are comments
- genomes are downloaded from NCBI
- merged with local genomes

---

# Genome input requirements

Directory:

genomes/

Supported formats:
- .fna
- .fa
- .fasta
- .fas

Rules:
- one genome per file
- sample name = filename without extension

Example:

genomes/
├── CBS12345.fna
├── CBS12346.fasta
└── CBS12347.fa

Becomes:
CBS12345
CBS12346
CBS12347

---

# Validation rules

## Reference genes
- correct header format required
- unique strain|gene keys
- must match config gene list

## Genomes
- valid extensions only
- at least one genome required
- merged local + public set

---

# Configuration summary

| Section | Purpose |
|--------|--------|
| genes | MLSA loci |
| tree | phylogenetic inference |
| ani_method | ANI workflow |
| public_genomes | NCBI genomes |
| genomes/ | input assemblies |
| db/ref-genes.fas | reference loci |