# Modifying the pipeline for fungal data

## Annotation

funannnotate can recognize and consistently annotate conserved genes
similarly to prokka. However, there a few differences and limitations.

- Genes don't get a `gene` tag with the gene name, instead only `Name` tag
- CDS sequences related to those genes don't get the tag propagated
- When a gene has paralogues then they get `_#` notation like `TUB2_1`

```yaml
genes:
- CMD1
- RPB2
- TUB2_1
- ACT1_1

names:
- CMD1
- RPB2
- TUB2_1
- ACT1_1
```

Here is an example (currently tested on A. flavus)

## Changelog

- Added option for `gff3-extract-cds.pl` to work on genes with `-gene` flag
- Added a feature to `gff3-filter-yaml.pl` to use the `names` list from the YAML and match `Name` tags

```bash
cat A_flavus_annotate_results/Aspergillus_flavus.gff3 | perl -ne 'if (/ID=(\S+);.*Name=(\S+)(;.+)?$/) { $id = $1; $name = $2; $map{$id} = $name if $name}; if (/CDS/ && /ID=([^-]+)/) {$name = $map{$1}; s/$/Name=$name/;}; print' >update.gff3
```

After this the extraction scripts works properly for extracting the coding sequence

```bash
# Extract genes
perl scripts/gff3-filter-yaml.pl update.gff3 fun-genes.yml | perl scripts/gff3-extract-cds.pl -gene - A_flavus_annotate_results/Aspergillus_flavus.scaffolds.fa >extracted-gene.fas
# extract the coding only
perl scripts/gff3-filter-yaml.pl update.gff3 fun-genes.yml | perl scripts/gff3-extract-cds.pl  - A_flavus_annotate_results/Aspergillus_flavus.scaffolds.fa >extracted.fas
```
