# Scripts used for the workflow

## Missing scripts

Needed to rewrite:

- [x] gff3-filter-yaml.pl
- [x] rename-extracted-gff-fasta.pl
- [x] rename-extracted-hit-fasta.pl

Added (need to test):

- [ ] rename-ids.pl
- [ ] ani2distance-phylip.pl (ani-typer)
- [ ] ~~nj-for-phylip-distance-matrix.pl (ani-typer)~~
- [x] gff3-extract-cds.pl
- [x] sam-realign.pl

Alternative:

- [x] nj-for-dist-matrix.R (instead of nj-for-phylip-distance-matrix.pl)

## Phylogeny

```bash
# get input genomes
conda install conda-forge::ncbi-datasets-cli

# tree manipulation
conda install bioconda::newick_utils
```
