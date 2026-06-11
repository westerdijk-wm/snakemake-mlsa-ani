# Test dataset

A small example dataset is provided to verify your installation and demonstrate the workflow end-to-end without needing to supply your own genomes.

## Overview

The test set uses **8 public genome assemblies** from four closely related *Aspergillus* species (section *Fumigati*), downloaded automatically from NCBI, together with a **4-locus reference gene set** derived from *Aspergillus fumigatus* Af293.

| Species | Accessions |
|---|---|
| *A. fumigatus* | GCA_000150145.1, GCA_000002655.1 (Af293) |
| *A. fischeri* | GCA_000149645.4, GCA_014250575.1 |
| *A. lentulus* | GCA_010724455.1, GCA_023625555.1 |
| *A. udagawae* | GCA_001078395.2, GCA_010723835.1 |

Including two genomes per species and several closely related species provides a meaningful phylogeny and ANI comparison while keeping the dataset small and fast to run.

## Reference loci

`db/ref-genes.fas` contains four single-copy marker genes extracted from *A. fumigatus* Af293 (GCA_000002655.1):

- `calmodulin`
- `actin`
- `rpb2`
- `tubA`

These are commonly used MLSA markers for *Aspergillus* / section *Fumigati* phylogenetics.

## Configuration

`db/public_genomes.txt`:

```text
GCA_000150145.1
GCA_000002655.1
GCA_000149645.4
GCA_014250575.1
GCA_010724455.1
GCA_023625555.1
GCA_001078395.2
GCA_010723835.1
```

Example `config.yaml`:

```yaml
genes:
  - calmodulin
  - actin
  - rpb2
  - tubA

tree:
  method: iqtree
  bootstrap: 1000

ani_method: skani

public_genomes: db/public_genomes.txt
```

No genomes need to be placed in `genomes/` — all 8 assemblies are downloaded automatically.

## Running the test set

With `genomes/` empty, `db/ref-genes.fas` and `db/public_genomes.txt` populated as above, and `config.yaml` set as shown:

```bash
snakemake --cores 4 --use-conda
```

This downloads the 8 genome assemblies, runs the full pipeline (QC, gene extraction, alignment, IQ-TREE phylogeny, skani ANI), and finishes in a short time on a standard machine.

Generate the summary report with:

```bash
snakemake  --cores 4 --use-conda --report
```

Example outputs from this run are shown in [Outputs](outputs.md).