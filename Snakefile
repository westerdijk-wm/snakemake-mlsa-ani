include: "rules/common.smk"

configfile: "mlsa.yml"

#Define a rule all
rule all:
    input:
        "results/MLSA.nwk",
        "quast/report.pdf",
        ani_targets()

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

rule gene_qc:
    input:
        fasta="genes/map-pool.fas",
        ref="db/ref-genes.fas"
    output:
        detail="report/gene_qc_detail.tsv",
        summary="report/gene_qc_summary.tsv",
        filtered="genes/map-pool.filtered.fas",
        sample_lists="report/genome-list-pass.txt"
    threads:
        4
    log:
        "logs/gene_qc.log"
    shell:
        """
        python scripts/genes_qc.py \
            {input.fasta} \
            {input.ref} \
            {output.detail} \
            {output.summary} \
            {output.filtered} \
            {output.sample_lists} \
            {log}
        """

rule prepare_tree_input:
    input:
        loci="genes/map-pool.filtered.fas",
        ref="db/ref-genes.fas"
    output:
        "genes/map-pool-ref.fas"
    run:
        import shutil

        shutil.copy(input.loci, output[0])

        if config.get("include_reference", False):
            with open(output[0], "a") as out:
                with open(input.ref) as ref:
                    out.write(ref.read())


rule align:
    input:
        "genes/map-pool-ref.fas"
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
        fasta_autoconcatenate -r='{autoconcatenate_regex}' {input} > {output.fas} 2> {output.tab}
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
        cat {input} | perl -ne '{parition_regex}' > {output}
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
        "results/MLSA.nwk"
    threads: 
        4
    log:
        "logs/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """

include: "rules/fastANI.smk"
include: "rules/pyANI.smk"
include: "rules/skANI.smk"
