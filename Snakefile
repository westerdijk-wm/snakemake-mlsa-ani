include: "rules/common.smk"

configfile: "mlsa.yml"

#Define a rule all
rule all:
    input:
        "report/calmodulin_rpb2_actin.nwk",
        "report/map-report.tsv",
        "report/map-sanity.tsv",
        "report/fastani_table.tsv",
        "quast/report.pdf",
        "results/pyani_cov_plot.pdf",
        "results/pyani_ANI.pdf"


# Get data from NCBI
rule dataset:
    """
    Download data from NCBI and place it to correct location
    """
    input:
        "ncbi-ids.txt"
    output:
        "download/ncbi_dataset.zip",
        "download/README.md"
    shell:
        """
        datasets download genome accession --inputfile {input} --include genome,gff3 --filename {output[0]}
        cd download
        unzip ncbi_dataset.zip
        """


rule move_dataset:
    """
    Place the donwloaded dataset to correct location
    """
    input:
        "download/README.md"
    output:
        "download/renamed.log"
    shell:
        """
        scripts/rename-download.py >{output}
        cp download/renamed/*/*.fna genomes/.
        mv download/renamed/* annotation/.
        rm {input}
        """


# Annotate genomes
# rule prokka:
#     """
#     Annotate genome assemblies using prokka
#     """
#     input:
#         "genomes/{sample}.fna"
#     output:
#         "annotation/{sample}/{sample}.fna", # Genome sequences (with contig names matching with gff)
#         #"annotation/{sample}/{sample}.log", # log
#         #"annotation/{sample}/{sample}.faa", # Protein sequences
#         #"annotation/{sample}/{sample}.ffn",  # gene sequences also rRNA
#         "annotation/{sample}/{sample}.gff" # GFF annotation
#     threads: 8
#     shell:
#         "prokka {input} --force --cpus {threads} --outdir annotation/{wildcards.sample} --prefix {wildcards.sample} --centre BioInt --compliant"


# Assembly quality check
rule fasta_assembly_statistics:
    input:
        "assemblies/{sample}/contigs.fasta"
    output:
        "assembly_qc/{sample}.stats"
    shell:
        """
        fasta_assembly_statistics {input} >{output}
        """


rule gff:
    input:
        "annotation/{sample}/{sample}.gff",
        "mlsa.yml",
        "annotation/{sample}/{sample}.fna"
    output:
        "genes/gff/{sample}.fas"
    shell:
        """
        perl {gff3filter} {input[0]} {input[1]} |
        perl {gff3extract} - {input[2]} |
        {rename} - -sample={wildcards.sample} > {output}
        """


rule gff_all:
    input:
        expand("genes/gff/{sample}.fas", sample=SAMPLES)
    output:
        "genes/gff-pool.fas"
    shell:
        """
        cat {input} > {output}
        """


# Assembly quality check
rule quast:
    input:
        fasta=GENOMES
    output:
        file_pdf="quast/report.pdf"
    log:
        "logs/quast.log"
    conda:
        "envs/quast.yaml"
    params:
        outdir="quast"
    threads:
        workflow.cores
    shell:
        """
        quast.py {input.fasta} \
            -o {params.outdir} \
            --fungus \
            --min-contig 5 \
            --min-identity 95.0 \
            --threads {threads} \
            > {log} 2>&1
        """

# Rule build gene base
# Cat .fas .fasta .fna etc to a ref-genes.fas and go on..
# Extract gene names so we do not need the config.yaml 


rule minimap:
    input:
        IN_GENOME=genome_file,
        IN_DATABASE="db/ref-genes.fas"
    output:
        OUT_SAM=temp("minimap/{sample}_mapping.sam"),
        F_SAM=temp("minimap/{sample}_mapping_filtered.sam")
    threads:
        workflow.cores
    log:
        "logs/minimap/{sample}.log"
    shell:
        """
        minimap2 -a -x map-ont {input.IN_GENOME} {input.IN_DATABASE} > {output.OUT_SAM} 2> {log} 

        samtools view {output.OUT_SAM} -F4 -h |
        sam-flip.pl |
        sam-keep-best.pl -rid -l -n=1 -po=0.1 \
        > {output.F_SAM}
        """


rule sam_realign:
    input:
        IN_HITS="minimap/{sample}_mapping_filtered.sam",
        IN_DATABASE="db/ref-genes.fas",
        IN_QUERY=genome_file
    output:
        OUT_SAM=temp("sam_realign/{sample}_realigned_mapping.sam")
    threads:
        4
    shell:
        """
        {samrealign} {input.IN_HITS} {input.IN_DATABASE} {input.IN_QUERY} > {output.OUT_SAM}
        """


## extract locus sequences
rule sam_extract_hit_seq:
    input:
        IN="sam_realign/{sample}_realigned_mapping.sam"
    output:
        OUT=temp("genes/map/{sample}.fas")
    params:
        sim=0.7
    threads:
        4
    shell:
        """
        cat {input.IN} |
        sam-filter.pl -minsim={params.sim} |
        sam-extract-hit-seq.pl |
        {rename2} - -sample={wildcards.sample} > {output.OUT}
        """

rule map_all:
    input:
        expand("genes/map/{sample}.fas", sample=SAMPLES)
    output:
        "genes/map-pool.fas"
    threads:
        4
    shell:
        """
        cat {input} > {output}
        """

rule align:
    input:
        "genes/map-pool.fas"
    output:
        "genes/aligned/{gene}.fas"
    threads:
        4
    log:
        "logs/muscle/{gene}.log"
    shell:
        """
        cat {input} | fasta_grep {wildcards.gene} | muscle > {output} 2> {log}
        """

rule concat:
    input:
        expand("genes/aligned/{gene}.fas", gene=config["genes"])
    output:
        fas="genes/concat.fas",
        tab="genes/concat.tab"
    threads: 
        4
    shell:
        """
        fasta_autoconcatenate -r='^>([^\|]*)' {input} > {output.fas} 2> {output.tab}
        """

# Raxml commands in rules
rule partition_file:
    input:
        "genes/concat.tab"
    output:
        "genes/concat.part"
    threads: 
        4
    shell:
        """
        cat {input} | perl -ne 's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;' > {output}
        """

rule raxml_bootstrap:
    input:
        fas="genes/concat.fas",
        part="genes/concat.part"
    output:
        boot="phylogeny/RAxML_bootstrap.analysis-bs",
        tree="phylogeny/RAxML_bestTree.analysis-bs"
    threads: 
        workflow.cores
    log:
        "logs/raxml_bootstrap.log"
    shell:
        """
        raxmlHPC-PTHREADS -T {threads} -m GTRGAMMA -p 12345 -x 12345 -f a -# 150 \
                          -q {input.part} -s {input.fas} \
                          -n analysis-bs -w `pwd`/phylogeny/ \
                          > {log} 2>&1
        """

rule raxml_bipartitions:
    input:
        tree="phylogeny/RAxML_bestTree.analysis-bs",
        boot="phylogeny/RAxML_bootstrap.analysis-bs"
    output:
        "phylogeny/RAxML_bipartitions.analysis-ML-bs"
    threads: 
        workflow.cores
    log:
        "logs/raxml_bipartitions.log"
    shell:
        """
        raxmlHPC -m GTRGAMMA -p 12345 -f b \
                 -t {input.tree} -z {input.boot} \
                 -n analysis-ML-bs -w `pwd`/phylogeny/ \
                 > {log} 2>&1
        """

rule reroot_tree:
    input:
        "phylogeny/RAxML_bipartitions.analysis-ML-bs"
    output:
        "report/calmodulin_rpb2_actin.nwk"
    threads: 
        4
    log:
        "logs/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """

# ANI
rule pyani:
    input:
        GENOMES
    output:
        "report/pyani/ANIm_percentage_identity.tab",
        "report/pyani/ANIm_alignment_coverage.tab"
    threads: 
        workflow.cores
    shell:
        """
        average_nucleotide_identity.py \
            -f \
            -i genomes/ \
            -o report/pyani \
            -m ANIm
        """

rule ani_distance:
    input:
        "report/pyani/ANIm_percentage_identity.tab"
    output:
        "report/pyani_dist.phy",
        "report/pyani_dist.tsv",
        "report/pyani_dist.nwk"
    threads: 
        8
    shell:
        """
        scripts/ani2distance-phylip.pl {input} >{output[0]}
        tail -n +2 {output[0]} >{output[1]}
        # scripts/nj-for-phylip-distance-matrix.pl {output[0]} | nw_reroot - > {output[1]}
        scripts/nj-for-dist-matrix.R {output[1]} {output[2]}
        """

rule ani_plot:
    input:
        "report/pyani_dist.nwk",
        "report/pyani/ANIm_percentage_identity.tab"
    output:
        "results/pyani_ANI.pdf"
    threads: 
        4
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """

rule cov_plot:
    input:
        "report/pyani_dist.nwk",
        "report/pyani/ANIm_alignment_coverage.tab"
    output:
        "results/pyani_cov_plot.pdf"
    threads: 
        4
    shell:
        """
        tree-heatmap.R {input} {output}
        """

rule fastani:
    input:
        GENOMES
    output:
        "report/genome-list.txt",
        "report/fastani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/fastANI.log"
    shell:
        """
        ls {input} > {output[0]}
        fastANI --rl {output[0]} --ql {output[0]} \
            -o {output[1]} \
            -t {threads} \
            > {log} 2>&1
        
        rm {output[0]}
        """

rule fastani_table:
    input:
        "report/fastani_pairs.tsv"
    output:
        "report/fastani_table.tsv"
    threads: 
        workflow.cores
    shell:
        """
        less {input} | cut -f1-3 | sort | perl -ne '{fastani_perl}' | table-cast.pl -s > {output}
        """

# rule spcall:
#     input:
#         "db/types.tsv",
#         "report/fastani_table.tsv"
#     output:
#         "report/sp_calls_long.tsv"        
#     shell:
#         """
#         ani-typer.pl -type {input[0]} -ani {input[1]} | cut -f1,2 >{output}
#         """

        
# rule extract_report:
#     input:
#         "genes/{method}-pool.fas"
#     output:
#         "report/{method}-report.tsv"
#     shell:
#         """
#         perl -ne '{script_code}' {input} > {output}
#         """


# Check for fragmantation, duplication, missing genes
rule gene_sanity_check:
    input:
        "report/{method}-report.tsv"
    output:
        "report/{method}-sanity.tsv"
    conda:
        "envs/R.yaml"
    shell:
        """
        Rscript scripts/check_genes.R {input} {output}
        """

# rule overview:
#     input:
#         "report/{method}-report.tsv",
#         "report/sp_calls_long.tsv"
#     output:
#         "report/overview_{method}.csv"
#     shell:
#         """
#         cut -f1,2 {input[1]} | perl -ne 's/\t/\ttaxon\t/; print' >report/sp
#         cat report/sp {input[0]} | table-cast.pl -s | perl -ne 's/^\t/ID\t/; print' | sed 's/\t/,/g' > {output}
#         rm report/sp
#         """

# rule sp_tags:
#     input:
#         "report/overview_map.csv"
#     output:
#         "report/sp-tags.tsv"
#     shell:
#         """
#         cat {input} | csvq -f TSV 'select id,taxon FROM stdin ORDER BY taxon' | grep -v taxon | perl -ne '{sp_perl}' >{output}
#         """

# rule rename_tree:
#     input:
#         "report/sp-tags.tsv",
#         "report/{tree}.nwk"
#     output:
#         "report/{tree}-sp-tagged.nwk"
#     shell:
#         """
#         scripts/rename-ids.pl {input} > {output}
#         """

