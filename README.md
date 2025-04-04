# MLSA pipeline

This is a copy of the MLSA Snakemake pipeline that was used for _Ralstonia syzygii_.
The goals is to standardize and document how the pipeline can be used for future
analysis. This is geared towards bacterial genomes, due to using prokka for annotation.
You can run it for any type of genomes if you either avoid the GFF based gene extraction
or provide the necessary annotation files with consistent naming conventions.

## Setting up

```
|-- README.md
|-- Snakefile
|-- db/
|   |-- ref-genes.fas
|   \-- types.tsv
|-- genomes/
\-- mlsa.yml
```

1. Create a `genomes` folder where you place all the genomes with an `.fna` extention
2. Modify the `mlsa.yml` file so the correct genes are listed
3. Specify type or reference strains for ANI classification in `db/types.tsv`
4. Specify reference genes for extracting homologous genes using mapping in `db/ref-genes.fas`

**Considerations for running the pipeline**:

- **WARNING**: GFF based extraction works out of the box for bacterial genomes, but not for other genomes
    + You could add all the required files in the `annotation` folder
    + For `my_fungus` they would be: `annotation/my_fungus/my_fungus.fna` and `annotation/my_fungus/my_fungus.gff`
- Strain list is defined by the content of `genomes`.
- Gene names for GFF based extraction has to be defined in `mlsa.yml` as an entry within `genes:`
- If you add new genomes to the input after already generating `genes/gff-pool.fas`, you need to delete it before you can run it for the full set
- It is recommended to first run until `report/overview_gff.csv` is generated


Example for `db/types.tsv`:

```tsv
# Table based on DOI:10.1007/s10658-020-02190-8
GCF_015910705.1	Ralstonia solanacearum	Phylotype IIA
GCA_015910955.1	Ralstonia pseudosolanacearum	Phylotype III
GCA_000009125.1	Ralstonia pseudosolanacearum	Phylotype I
GCA_000283475.1	Ralstonia syzygii	Phylotype IV
```

The file consists of tab separated columns. The first column specifies the reference genomes filename without the extension.
The second column specifies the taxon (species) name.
Further columns and rows that start with `#` are ignored.

Example for `db/ref-genes.fas`:

```fasta
>GCA_000009125.1|adk cds-CAD16240.1
ATGCGGTTGATTCTGTTGGGCGCACCCGGCGCCGGCAAAGGTACGCAAGCCAAATTCATC
TGCGAACGCTTCGGCATTCCGCAGATCTCCACCGGCGACATGCTGCGCGCCGCCGTCAAG
GCCGGCACCCCGCTGGGCATCGAAGCCAAGAAGGTGATGGACGCCGGCGGCCTGGTGTCC
GACGACATCATCATCGGCCTGGTGAAGGACCGCCTGCAGCAGTCCGACTGCAAGAACGGC
TACCTGTTCGACGGCTTCCCGCGCACCATCCCCCAGGCCGAAGCCATGAAGGATGCCGGC
GTGCCGATCGACTACGTGCTGGAAATCGACGTGCCGTTCGACGCCATCATCGAGCGCATG
AGCGGCCGCCGCGTGCACGTGGCCTCGGGCCGGACCTATCACGTCAAGTACAACCCGCCC
AAGAACGAGGGCCAGGACGACGAAACCGGCGATCCGCTGATCCAGCGCGACGACGACAAG
GAAGAAACCGTCCGCAAGCGCCTGTCCGTGTACGAGAACCAGACCCGCCCGCTGGTGGAC
TACTACTCCGGCTGGGCCGAGAACGGCAACGGTGCCGCCAAGGTGGCGCCGCCCAAGTAC
CGCAAGATCAGCGGGATCGGCAACGTGGAAGACATCACCGGCCGCGTGTTCGGCGCACTG
GAAGCCTGA
```

The format for the ID line is `>{strain}|{gene} {other text}`.
It is expected that following the `>` sign a text follows without spaces
containig the strain name and the gene name separated by a `|` sign.
Each of these strain+gene combos have to be unique. The strain name
will be ignored downstream so no problem if they are not accurate.
The gene names are important because sequence results will be grouped
based on those.

## Running the pipeline

As an example data set, you can use the following data from NCBI:

```bash
# This uses ncbi-ids.txt as input
snakemake -c 1 download/renamed.log
```

The same can be done manually as well.

```bash
# donwload the sequences from NCBI
datasets download genome accession GCF_015910705.1,GCA_025859615.1,GCA_015910955.1,GCA_014884745.1,GCA_021117135.1,GCA_000283475.1,GCA_000009125.1 --include genome,gff3
# Extract and move the files to genomes folder (plus rename them)
unzip ncbi_dataset.zip
cd ncbi_dataset/data/
for g in GC*; do cp $g/*_genomic.fna ../../genomes/$g\.fna; mkdir -p ../../annotation/$g; cp $g/*.gff ../../annotation/$g/$g\.gff; cp $g/*_genomic.fna ../../annotation/$g/$g\.fna; done
# There will be some errors, because two are not annotated
cd ../..
```

### Pyani analysis:

```
# You need to specify the number of cores for the run
snakemake -c 4 results/pyani_cov_plot.pdf results/pyani_ANI.pdf
```

You can check the plots that were requested to see how your genomes compare.

### Running prokka for bacterial genomes and extracting genes based on gene names:

```
# You need to specify the number of cores for the run
snakemake -c 4 report/overview_gff.csv
```

Check if all genes were found for all strains and exactly once.

> An example:
>
>     cd report
>     csvq 'select * from overview_gff'
>
> In the example reported the following:
>
>     +------------------+-------------------------------+------+------+------+-----+------+------+------+------+-----+
>     |        ID        |             taxon             | gyrB | leuS | rplB | egl | gdhA | mutS | fliC | ppsA | adk |
>     +------------------+-------------------------------+------+------+------+-----+------+------+------+------+-----+
>     | GCA_000009125.1  | Ralstonia pseudosolanacearum  | 1    | 1    | 1    | 1   | 1    | 1    | 1    | 1    | 1   |
>     | GCA_000283475.1  | Ralstonia syzygii             | 1    | 1    | 1    | 1   | 1    | 1    | 1    | 1    | 1   |
>     | GCA_014884745.1  | Ralstonia solanacearum        | 1    | NA   | 1    | NA  | NA   | 1    | NA   | 1    | 1   |
>     | GCA_015910955.1  | Ralstonia pseudosolanacearum  | 1    | NA   | 1    | 1   | 1    | 1    | NA   | 1    | 1   |
>     | GCA_021117135.1  | Ralstonia solanacearum        | 1    | 1    | 1    | NA  | 1    | 1    | NA   | NA   | 1   |
>     | GCA_025859615.1  | Ralstonia pseudosolanacearum  | 1    | 1    | 1    | NA  | NA   | 1    | NA   | 1    | 1   |
>     | GCF_015910705.1  | Ralstonia solanacearum        | 1    | 1    | 1    | NA  | NA   | 1    | NA   | 1    | 1   |
>     +------------------+-------------------------------+------+------+------+-----+------+------+------+------+-----+  
>


You can use the sequences collected (`genes/gff-pool.fas`) as the reference set for the mapping option if some are missed.

> For simplicity you can use a single reference's gene sequences or a collection of strains of genes

### Running gene extraction based on homology:

```
# You need to specify the number of cores for the run
snakemake -c 4 report/overview_map.csv
```

> An example:
>
>     cd report
>     csvq 'select * from overview_map'
>
> In the example reported the following:
>
>     +------------------+-------------------------------+------+------+------+------+------+------+------+-----+-----+
>     |        ID        |             taxon             | ppsA | leuS | gdhA | rplB | gyrB | fliC | mutS | egl | adk |
>     +------------------+-------------------------------+------+------+------+------+------+------+------+-----+-----+
>     | GCA_000009125.1  | Ralstonia pseudosolanacearum  | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1   | 1   |
>     | GCA_000283475.1  | Ralstonia syzygii             | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1   | 1   |
>     | GCA_014884745.1  | Ralstonia solanacearum        | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1   | 1   |
>     | GCA_015910955.1  | Ralstonia pseudosolanacearum  | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1   | 1   |
>     | GCA_021117135.1  | Ralstonia solanacearum        | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1   | 1   |
>     | GCA_025859615.1  | Ralstonia pseudosolanacearum  | 1    | 1    | 1    | 1    | 1    | 1    | 2    | 1   | 1   |
>     | GCF_015910705.1  | Ralstonia solanacearum        | 1    | 1    | 1    | 1    | 1    | 1    | 2    | 1   | 1   |
>     +------------------+-------------------------------+------+------+------+------+------+------+------+-----+-----+
>
> In this, case GCA_025859615.1 and GCF_015910705.1 have to be checked and one of the mutS entries removed, manually
> (`genes/map/GCA_025859615.1.fas` and `genes/map/GCF_015910705.1`).
> Since one of the entries had similarity (`sim`) close to 90% and the other less than 50% it is easy to identify that the second one should be removed.
> You can also adjust the similarity threshold in the `Snakefile`.

### Phylogeny

> Relies on the results of the extraction steps

Based on the collected genes you can generate a phylogeny. Below is the description how to do it using RAxML.


> Here is an exmaple when you have some strains missing a gene. In this example it is `hag`.
>
>     # Check alignment length
>     fasta_length genes/aligned/hag.fas -e | head -2
>     
>     # Use the above alignment length (replace '822' by the alignment length)
>     csvq -f TSV 'select * FROM overview_map WHERE hag = "NA" ORDER BY taxon '  | cut -f1 | tail +2 | perl -ne 's/\R//g; print ">$_\|hag missing\n" . ("-" x 822) . "\n"' >missing-hag.fas
>     cat missing-hag.fas >> genes/aligned/hag.fas
>
> Remeber to do this step for each genes.
> This example marked them as gaps (`-`), but you can mark them as missing (`?`); this choice influences the resulting phylogeny.

Align and concatenate all the genes from the mapping pipeline.

> Generally the mapping pipeline returns more results than the annotation one.
> You can modify the `Snakefile` to change it to the gff version. Change the input to `genes/gff-pool.fas` for `rule align:`

```
snakemake -c 1 genes/concat.fas
```

Run the default RAxML analysis by pasting the below commands.

```
cd genes
group=GTRGAMMA-partitioned-bs1000
# Correct partition format for RAxML
cat concat.tab | perl -ne 's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;' >concat.part
# ML tree using partitions
raxmlHPC -m GTRGAMMA -p 12345 -# 20 -q concat.part -s concat.fas -n $group\-concat-ML
# rapid bootstrap calculation (-x otherwise -b for regular bootstrap)
#raxmlHPC -m GTRGAMMA -p 12345 -x 12345 -# 1000 -q concat.part -s concat.fas -n $group\-concat-bs
raxmlHPC-PTHREADS -T 32 -m GTRGAMMA -p 12345 -x 12345 -# 1000 -q concat.part -s concat.fas -n $group\-concat-bs
raxmlHPC -m GTRGAMMA -p 12345 -f b -t RAxML_bestTree.$group\-concat-ML -z RAxML_bootstrap.$group\-concat-bs -n $group\-concat-ML-bs
nw_reroot -s RAxML_bipartitions.$group\-concat-ML-bs >$group\.nwk
cp $group\.nwk ../report/
cd ..
```

If you want to add the species names to the IDs on the tree, run the following:

```
snakemake -c 1 report/$group\-sp-tagged.nwk
```

## Renaming IDs

Remember that you can use `rename-ids.pl` to rename IDs in table formats (csv and tsv) and in nwk trees:

```
rename-ids.pl tags original-tree.nwk >renamed-tree.nwk
```

Where `tags` is a TSV file like this:

```tsv
GCA_000009125.1	GCA_000009125.1_Ralstonia_pseudosolanacearum
GCA_015910955.1	GCA_015910955.1_Ralstonia_pseudosolanacearum
GCA_025859615.1	GCA_025859615.1_Ralstonia_pseudosolanacearum
GCA_014884745.1	GCA_014884745.1_Ralstonia_solanacearum
GCA_021117135.1	GCA_021117135.1_Ralstonia_solanacearum
GCF_015910705.1	GCF_015910705.1_Ralstonia_solanacearum
GCA_000283475.1	GCA_000283475.1_Ralstonia_syzygii
```

The first column has to match exactly the original ID and will be replaced by the value in the second column.
