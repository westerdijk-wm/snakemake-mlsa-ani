# snakemake-MLSA-ANI

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/westerdijk-wm/snakemake-mlsa-ani/actions/workflows/main.yaml/badge.svg?branch=main)](https://github.com/westerdijk-wm/snakemake-mlsa-ani/actions?query=branch%3Amain+workflow%3ATests)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![workflow catalog](https://img.shields.io/badge/Snakemake%20workflow%20catalog-darkgreen)](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/westerdijk-wm/snakemake-mlsa-ani)


Automated multilocus sequence analysis (MLSA), phylogenetic inference, and
Average Nucleotide Identity (ANI) analysis from genome assemblies.

## Overview

**snakemake-MLSA-ANI** is a reproducible Snakemake workflow designed to
generate phylogenetic and genomic similarity analyses from assembled genomes.

Starting from genome assemblies, the pipeline:

- validates the reference gene database
- assesses genome assembly quality (QUAST)
- extracts homologous loci using reference sequences (minimap2)
- performs locus-level quality control
- generates multiple sequence alignments (MUSCLE)
- concatenates loci into MLSA supermatrices
- infers phylogenetic trees (IQ-TREE, RAxML, or FastTree)
- optionally computes ANI between genomes (skani, FastANI, or pyANI)
- optionally downloads and incorporates public genomes from NCBI

Originally developed for fungal phylogenetics, but applicable to any organism
with suitable reference loci.

## Installation

### Option 1 — Clone with Git

Ensure Conda and Git are installed, then:

```bash
git clone https://github.com/westerdijk-wm/snakemake-mlsa-ani.git
cd snakemake-mlsa-ani
conda env create -f workflow/envs/mlsa.yaml
conda activate snake-mlsa-ani
```

### Option 2 — Deploy with Snakedeploy

[Snakedeploy](https://snakedeploy.readthedocs.io) deploys the workflow into
any working directory without cloning the full repository, keeping your data
and workflow code cleanly separated:

```bash
conda install bioconda::snakedeploy
snakedeploy deploy-workflow \
    https://github.com/westerdijk-wm/snakemake-mlsa-ani . --branch main
```

This downloads the workflow files and creates a `config/` directory with
template configuration files ready to edit.


## Quick Start

1. Place genome assemblies in `genomes/` (`.fna`, `.fa`, `.fasta`, or `.fas`)
2. Provide reference loci in `config/ref-genes.fas`
   with header format `>{strain}|{gene} {optional description}`
3. Edit `config/config.yaml`

For full configuration options see [Configuration](docs/configuration.md).

> **New to this workflow?** Try the [test dataset](docs/test-data.md) first.
> It requires no local genomes and runs end-to-end in a few minutes.

**Run** pipeline with Snakemake:

```bash
snakemake --cores 10 --use-conda
```

Generate the interactive HTML report afterwards:

```bash
snakemake --cores 10 --report report.html
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
Genome QC (QUAST)
        │
        ▼
Gene extraction (minimap2)
        │
        ▼
Gene QC
        │
        ▼
Alignment (MUSCLE)
        │
        ▼
Concatenation
        │
        ▼
Phylogenetic inference
(IQ-TREE / RAxML / FastTree)
        │
        ├─────────► ANI analysis
        │           (skani / FastANI / pyANI)
        ▼
Report
```


## Directory structure

```text
|-- README.md
|-- docs/
|--logs/
|-- workflow/
|   |-- Snakefile
|   |-- envs/
|   |-- scripts/
|   |-- rules/
|   \-- report/
|-- config/
|   |-- config.yaml
|   |-- ref-genes.fas
|   |-- public_genomes.txt
|   \-- sample_metadata.tsv
|-- genomes/
\-- resources/
    \-- public_genomes/
```


## Citation

If you use this workflow, please cite:


## License

See [LICENSE](LICENSE) for details.

## Troubleshooting

See [Troubleshooting](docs/troubleshooting.md).  
For issues or feedback, feel free to open a GitHub issue.
