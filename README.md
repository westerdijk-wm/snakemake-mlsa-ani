# snakemake-MLSA-ANI

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/westerdijk-wm/snakemake-mlsa-ani/actions/workflows/main.yaml/badge.svg?branch=main)](https://github.com/westerdijk-wm/snakemake-mlsa-ani/actions?query=branch%3Amain+workflow%3ATests)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![workflow catalog](https://img.shields.io/badge/Snakemake%20workflow%20catalog-darkgreen)](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/westerdijk-wm/snakemake-mlsa-ani)


Automated multilocus sequence analysis (MLSA), phylogenetic inference, and Average Nucleotide Identity (ANI) analysis from genome assemblies.

## Overview

**snakemake-MLSA-ANI** is a reproducible Snakemake workflow designed to generate phylogenetic and genomic similarity analyses from assembled genomes.

Starting from genome assemblies, the pipeline:
- checks the reference gene database
- assesses genome assembly quality
- extracts homologous loci using reference sequences
- performs locus-level quality control
- generates multiple sequence alignments
- concatenates loci into MLSA datasets
- infers phylogenetic trees
- optionally computes ANI between genomes
- optionally downloads and incorporates public genomes from NCBI

Originally developed for fungal phylogenetics, but applicable to any organism with suitable reference loci.


## Installation

Ensure Conda and Git are installed. Then clone the repository:

```bash
git clone https://github.com/WesterdijkInstitute/snakemake-mlsa-ani.git
cd snakemake-mlsa-ani
```

Create the Snakemake environment:

```bash
conda env create -f workflow/envs/mlsa.yaml
conda activate snake-mlsa-ani
```


## Quick Start

1. Place genome assemblies in: `genomes/`
2. Provide reference loci: `config/ref-genes.fas`
   with header format: `>{strain}|{gene} {optional description}`
3. Configure the workflow: `config/config.yaml`

For full configuration options see: [Configuration documentation](docs/configuration.md)

> **New to this workflow?** Try the [test dataset](docs/test-data.md) first. It requires no local genomes and runs end-to-end in a few minutes (depending on the cores).

**Run** pipeline with Snakemake:

```bash
snakemake --cores 30 --use-conda
```

Generate report afterwards:

```bash
snakemake --report report.html
```


## Full Documentation

- [Configuration](docs/configuration.md)
- [Outputs](docs/outputs.md)
- [Methods](docs/methods.md)
- [Test dataset](docs/test-data.md)
- [Troubleshooting](docs/troubleshooting.md)


## Workflow

```text
Genome assemblies
        │
        ▼
Reference gene validation
        │
        ▼
Genome QC
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
        ├─────────► ANI analysis 
        │
        ▼
Report
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
|   \-- schemas/
|-- logs/
|-- db/
|   |-- ref-genes.fas
|   \-- public_genomes.txt
|-- genomes/
\-- config.yaml
```


## Citation

If you use this workflow, please cite:


## License

See [LICENSE](LICENSE) for details.


## Troubleshooting

See [Troubleshooting](docs/troubleshooting.md).  
For issues or feedback, feel free to open a GitHub issue.
