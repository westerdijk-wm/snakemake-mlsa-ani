# Scripts used for the workflow

## Missing scripts

- rename-ids.pl
- ani2distance-phylip.pl (ani-typer)
- nj-for-phylip-distance-matrix.pl (ani-typer)

Added (need to test):

- gff3-extract-cds.pl
- sam-realign.pl

Need to rewrite:

- [x] gff3-filter-yaml.pl
- [x] rename-extracted-gff-fasta.pl
- [x] rename-extracted-hit-fasta.pl


**BUG:** sam-harmonization installs to the wrong path

- Should go to `$CONDA_PREFIX/lib/perl5/site_perl/`
- Ends up in `$CONDA_PREFIX/lib/site_perl/

Temporary fix:

```bash
temp=`ls $CONDA_PREFIX/lib/site_perl/`; export PERL5LIB="$CONDA_PREFIX/lib/site_perl/$temp"
```

## sam-realign.pl

```bash
conda install bioconda::perl-bioperl-run # is not needed
conda install bioconda::muscle==3.8.1551
```
