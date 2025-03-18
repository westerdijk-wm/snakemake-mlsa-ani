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
    + You could add all the required files in the `annotations` folder
    + For `my_fungus` they would be: `annotations/my_fungus/my_fungus.fna` and `annotations/my_fungus/my_fungus.gff`
- Strain list is defined by the content of `genomes`.
- Gene names for GFF based extraction has to be defined in `mlsa.yml` as an entry within `genes:`
- If you add new genomes to the input after already generating `genes/gff-pool.fas`, you need to delete it before you can run it for the full set
- It is recommended to first run until `report/overview_gff.csv` is generated


Example for `db/types.tsv`:

```tsv
# True type strains
Ralstonia_solanacearum_UW251	Ralstonia solanacearum	Phylotype IIA
Ralstonia_pseudosolanacearum_LMG9673	  Ralstonia pseudosolanacearum	Phylotype III
Ralstonia_syzygii_LMG_10661	Ralstonia syzygii subsp. syzygii	Phylotype IV
# R. syzygii subsp.
CFBP8346_PD7815	Ralstonia syzygii subsp. celebesensis
Ralstonia_syzygii_PSI07	Ralstonia syzygii subsp. indonesiensis
# Unnamed subsp.
MAFF301558_PD7810_clean_hybrid	Ralstonia syzygii subsp. OrientalX
```

The file consists of tab separated columns. The first column specifies the reference genomes filename without the extension.
The second column specifies the taxon (species) name.
Further columns and rows that start with `#` are ignored.

Example for `db/ref-genes.fas`:

```fasta
>Ralstonia_solanacearum_Rs5|gyrB GEEGLODD_00003
ATGACCGAACAGCAGAAACCGCAATCCACCCCCGCCGAAAGCAGCAGCTACGGCGCCGCC
TCGATCCAGATCCTGGAAGGCCTGGAGGCGGTGCGCAAGCGGCCGGGCATGTACATCGGC
GATACGTCGGATGGCACCGGCCTGCACCACCTCGTGTTCGAGGTGCTGGACAACTCCATC
```

The format for the ID line is `>{strain}|{gene} {other text}`.
It is expected that following the `>` sign a text follows without spaces
containig the strain name and the gene name separated by a `|` sign.
Each of these strain+gene combos have to be unique. The strain name
will be ignored downstream so no problem if they are not accurate.
The gene names are important because sequence results will be grouped
based on those.

## Running the pipeline


### Pyani analysis:

```
# You need to specify the number of cores for the run
snakemake -c 24 results/pyani_cov_plot.pdf results/pyani_ANI.pdf
```

You can check the plots that were requested to see how your genomes compare.

### Running prokka for bacterial genomes and extracting genes based on gene names:

```
# You need to specify the number of cores for the run
snakemake -c 24 report/overview_gff.csv
```

Check if all genes were found for all strains and exactly once.

> An example:
>
>     cd report
>     csvq 'select * from overview_gff'
>
> In the example reported the following:
>
>     +--------------------------------------+-----------------------------------------+------+------+------+-----+------+------+-----+-----+------+
>     |                  ID                  |                  taxon                  | leuS | ppsA | gdhA | egl | rplB | gyrB | hag | adk | mutS |
>     +--------------------------------------+-----------------------------------------+------+------+------+-----+------+------+-----+-----+------+
>     | Ralstonia_pseudosolanacearum_Gj707   | Ralstonia pseudosolanacearum            | 1    | 1    | 1    | 1   | 1    | 1    | 1   | 1   | 1    |
>     | Ralstonia_pseudosolanacearum_LMG9673 | Ralstonia pseudosolanacearum            | NA   | 1    | 1    | 1   | 1    | 1    | 1   | 1   | 1    |
>     | Ralstonia_solanacearum_Rs5           | Ralstonia solanacearum                  | 1    | 1    | 1    | 1   | 1    | 1    | 1   | 1   | 1    |
>     | Ralstonia_solanacearum_UW251         | Ralstonia solanacearum                  | 1    | NA   | 1    | NA  | 1    | 1    | 1   | 1   | 1    |
>     | Ralstonia_syzygii_PSI07              | Ralstonia syzygii subsp. indonesiensis  | NA   | 1    | 1    | 1   | 1    | 1    | 1   | 1   | 1    |
>     +--------------------------------------+-----------------------------------------+------+------+------+-----+------+------+-----+-----+------+
>


You can use the sequences collected (`genes/gff-pool.fas`) as the reference set for the mapping option if some are missed.

> For simplicity you can use a single reference's gene sequences or a collection of strains of genes

### Running gene extraction based on homology:

```
# You need to specify the number of cores for the run
snakemake -c 24 report/overview_map.csv
```

> An example:
>
>     cd report
>     csvq 'select * from overview_map'
>
> In the example reported the following:
>
>     +--------------------------------------+-----------------------------------------+------+------+------+------+-----+------+-----+-----+------+
>     |                  ID                  |                  taxon                  | gdhA | rplB | mutS | leuS | adk | ppsA | hag | egl | gyrB |
>     +--------------------------------------+-----------------------------------------+------+------+------+------+-----+------+-----+-----+------+
>     | Ralstonia_pseudosolanacearum_Gj707   | Ralstonia pseudosolanacearum            | 1    | 1    | 2    | 1    | 1   | 1    | 1   | 1   | 1    |
>     | Ralstonia_pseudosolanacearum_LMG9673 | Ralstonia pseudosolanacearum            | 1    | 1    | 1    | 1    | 1   | 1    | 1   | 1   | 1    |
>     | Ralstonia_solanacearum_Rs5           | Ralstonia solanacearum                  | 1    | 1    | 1    | 1    | 1   | 1    | 1   | 1   | 1    |
>     | Ralstonia_solanacearum_UW251         | Ralstonia solanacearum                  | 1    | 1    | 1    | 1    | 1   | 1    | 1   | 1   | 1    |
>     | Ralstonia_syzygii_PSI07              | Ralstonia syzygii subsp. indonesiensis  | 1    | 1    | 1    | 1    | 1   | 1    | 1   | 1   | 1    |
>     +--------------------------------------+-----------------------------------------+------+------+------+------+-----+------+-----+-----+------+
>
> In this, case Ralstonia_pseudosolanacearum_Gj707 has to be checked and one of the mutS entries removed, manually (`genes/map/Ralstonia_pseudosolanacearum_Gj707.fas`).
> Since one of the entries had sim:0.91 and the other sim:0.45 it is easy to identify that the second one should be removed.

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
Ralstonia_pseudosolanacearum_Gj707      Ralstonia_pseudosolanacearum_Gj707_Ralstonia_pseudosolanacearum
Ralstonia_pseudosolanacearum_LMG9673    Ralstonia_pseudosolanacearum_LMG9673_Ralstonia_pseudosolanacearum
Ralstonia_solanacearum_Rs5      Ralstonia_solanacearum_Rs5_Ralstonia_solanacearum
Ralstonia_solanacearum_UW251    Ralstonia_solanacearum_UW251_Ralstonia_solanacearum
Ralstonia_syzygii_PSI07 Ralstonia_syzygii_PSI07_Ralstonia_syzygii_subsp._indonesiensis
```

The first column has to match exactly the original ID and will be replaced by the value in the second column.
