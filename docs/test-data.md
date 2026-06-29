# Test dataset

A small example dataset is provided to verify your installation and demonstrate
the workflow end-to-end without needing to supply your own genomes.

## Overview

The test set uses **8 public genome assemblies** from four closely related
*Aspergillus* species (section *Fumigati*), downloaded automatically from NCBI,
together with a **4-locus reference gene set** derived from *Aspergillus fumigatus* Af293.

| Species | Sample | Accession |
|---|---|---|
| *A. fumigatus* | Af293 | GCA_000002655.1 |
| *A. fumigatus* | NRRL181 | GCA_000149645.4 |
| *A. fischeri* | NRRL4585 | GCA_014250575.1 |
| *A. fischeri* | IFM46972 | GCA_010723835.1 |
| *A. lentulus* | IFM58399 | GCA_010724455.1 |
| *A. lentulus* | PK20-01 | GCA_023625555.1 |
| *A. udagawae* | IFM46973 | GCA_001078395.2 |
| *A. udagawae* | A1163 | GCA_000150145.1 |

Including two genomes per species and several closely related species provides
a meaningful phylogeny and ANI comparison while keeping the dataset small and
fast to run.

## Reference loci

`config/ref-genes.fas` contains four single-copy marker genes extracted from
*A. fumigatus* Af293 (GCA_000002655.1):

- `calmodulin`
- `actin`
- `rpb2`
- `benA`

These are commonly used MLSA markers for *Aspergillus* / section *Fumigati*
phylogenetics.

## Configuration

`config/public_genomes.txt`:

```text
sample	assembly
Af293	GCA_000002655.1
A1163	GCA_000150145.1
IFM58399	GCA_010724455.1
PK20-01	GCA_023625555.1
IFM46973	GCA_001078395.2
IFM46972	GCA_010723835.1
NRRL181	GCA_000149645.4
NRRL4585	GCA_014250575.1
```

`config/config.yaml`:

```yaml
genes:
  - calmodulin
  - actin
  - rpb2
  - benA

tree:
  method: iqtree
  bootstrap: 1000

ani_method: skani

ref_genes: config/ref-genes.fas
accessions: config/public_genomes.txt
```

No genomes need to be placed in `genomes/` — all 8 assemblies are downloaded
automatically.

## Running the test set

With `genomes/` empty and the configuration files above in place:

```bash
snakemake --cores 4 --use-conda
```

This downloads the 8 genome assemblies, runs the full pipeline (QC, gene
extraction, alignment, IQ-TREE phylogeny, skani ANI), and finishes in a short
time on a standard machine.

Generate the summary report with:

```bash
snakemake --cores 4 --use-conda --report
```

Example outputs from this run are shown in [Outputs](outputs.md).