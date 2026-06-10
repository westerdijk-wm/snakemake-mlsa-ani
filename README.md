# snakemake-MLSA-ANI

Automated multilocus sequence analysis (MLSA), phylogenetic inference, and Average Nucleotide Identity (ANI) analysis from genome assemblies.

## Overview

**snakemake-MLSA-ANI** is a reproducible Snakemake workflow for multilocus sequence analysis directly from assembled genomes. The workflow automates homologous gene extraction, locus quality control, multiple sequence alignment, sequence concatenation, phylogenetic inference, and optional ANI analysis.

Originally developed for fungal phylogenetics, the workflow can be applied to any organism for which suitable reference loci are available.

## Features

- Homology-based gene extraction from genome assemblies
- Reference gene validation and quality control
- Multiple sequence alignment using MUSCLE
- Concatenated MLSA phylogenies
- Multiple phylogenetic inference methods (IQ-TREE, RAxML, FastTree)
- Optional ANI analysis (skani, FastANI, PyANI)
- NCBI genome download support
- Automated Snakemake reporting
- Reproducible execution using Snakemake and Conda


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
        ├─────────────► ANI analysis
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

Create the Conda environment:

```bash
conda env create -f environment.yml
conda activate snake-mlsa-ani
```

## Quick Start

Place genome assemblies in the `genomes/` directory and provide reference loci in `db/ref-genes.fas`.

The FASTA header of in `db/ref-genes.fas` must follow:

```text
>{strain}|{gene} {optional description}
```

For example:

```text
>GCA_000009125.1|adk cds-CAD16240.1
ATGCGGTT...
```

Requirements:

* Headers must contain both a strain name and gene name separated by |.
* Each strain|gene combination must be unique.
* Gene names must match those listed under genes: in config.yaml.
* Additional description after the gene name is allowed.

Next configure the [config file](config.yaml) by specifying the genes of interest, phylogenetic inference method, and ANI method.

```yaml
# Gene configuration
genes:
  - actin
  - calmodulin
  - rpb2
  - tub2
  - cyp51A

# Tree configuration
tree:
  method: iqtree
  bootstrap: 1000

# ANI configuration
ani_method: skani

# Optional, define public genomes to include in the analysis. 
public_genomes: db/public_genomes.txt
```

See [docs/configuration.md](docs/configuration.md) for details concerning configuration.

**Run** the workflow:

```bash
snakemake --cores 8 --use-conda
```

Afterwards you can generate a Snakemake report:

```bash
snakemake --report report.html
```

## Documentation

Detailed documentation is available in the `docs/` directory:

- [Configuration](docs/configuration.md)
- [Workflow](docs/workflow.md)
- [Methods](docs/methods.md)
- [Outputs](docs/outputs.md)
- [Troubleshooting](docs/troubleshooting.md)

## Citation

If you use snakemake-MLSA-ANI in your work, please cite:


## License

See the [LICENSE file](LICENSE) for details.

## Troubleshooting

If you encounter an issue, see [Troubleshooting](docs/troubleshooting.md).
Feel free to report any issue or feedback related to the pipeline by opening a Github issue.