# snakemake-MLSA-ANI

Automated multilocus sequence analysis (MLSA), phylogenetic inference, and Average Nucleotide Identity (ANI) analysis from genome assemblies.

---

## Overview

**snakemake-MLSA-ANI** is a reproducible Snakemake workflow for multilocus sequence analysis directly from assembled genomes.

The pipeline automates:
- homologous gene extraction
- locus quality control
- multiple sequence alignment
- concatenation of loci
- phylogenetic inference
- optional ANI analysis

Originally developed for fungal phylogenetics, but applicable to any organism with suitable reference loci.

---

## Features

- Homology-based gene extraction from genome assemblies
- Reference gene validation and quality control
- Multiple sequence alignment (MUSCLE)
- Concatenated MLSA phylogenies
- Multiple phylogenetic methods:
  - IQ-TREE
  - RAxML
  - FastTree
- ANI analysis:
  - skani
  - FastANI
  - PyANI
- NCBI genome download support
- Automated Snakemake reports
- Fully reproducible (Snakemake + Conda)

---

## Workflow

```text
Genome assemblies
        │
        ▼
Reference gene validation
        │
        ▼
Genome QC (QUAST)
        │
        ▼
Gene extraction
        │
        ▼
Gene QC
        │
        ▼
Alignment
        │
        ▼
Concatenation
        │
        ▼
Phylogenetic inference
        │
        ├────────────► ANI analysis (optional)
        │
        ▼
Report
```

## Installation

Clone the repository:

```bash
git clone https://github.com/WesterdijkInstitute/snakemake-mlsa-ani.git
cd snakemake-mlsa-ani
```

Create the environment:

```bash
conda env create -f workflow/envs/mlsa.yml
conda activate snake-mlsa-ani
```

## Quick Start

1. Place genome assemblies in: `genomes/`
2. Provide reference loci: `db/ref-genes.fas`
3. Configure the workflow: `config.yaml`

For full configuration options see: [Configuration documentation](docs/configuration.md)

**Run** pipeline with Snakemake:

```bash
snakemake --cores 8 --use-conda
```

Generate report afterwards:

```bash
snakemake --report report.html
```

## Directory structure

```text
|-- README.md
|-- docs/
|-- workflow/
|   |-- Snakefile
|   |-- envs/
|   |-- scripts/
|   |-- rules/
|   |-- schemas/
|-- logs/
|-- db/
|   |-- ref-genes.fas
|   \-- public_genomes.txt
|-- genomes/
\-- config.yaml
```

## Documentation

- [Configuration](docs/configuration.md)
- [Workflow](docs/workflow.md)
- [Methods](docs/methods.md)
- [Outputs](docs/outputs.md)
- [Troubleshooting](docs/troubleshooting.md)

## Citation

If you use this workflow, please cite:

(add citation here)

## License

See [LICENSE](LICENSE) for details.

## Troubleshooting

See [Troubleshooting](docs/troubleshooting.md). For issues or feedback, feel free to open a GitHub issue.