
rule minimap2:
    """
    Map reference genes against each genome assembly with minimap2.
    """
    input:
        target=genome_file,
        query="resources/db/ref-genes.validated.fas",
        validated_ref="results/QC/ref_genes.validated",
    output:
        "results/minimap2/{sample}_mapping.sam",
    log:
        "logs/minimap/{sample}_minimap2.log",
    threads: workflow.cores
    params:
        extra="-x map-ont -p 0.5",  # may need a more relaxed secondary hits '-p 0.5'
        sorting="none",
    wrapper:
        "v9.9.0/bio/minimap2/aligner"


rule sam_filter:
    """
    Filter SAM alignments: remove unmapped reads, flip strands, and keep the single best hit per locus.

    """
    input:
        IN_SAM=("results/minimap2/{sample}_mapping.sam"),
    output:
        F_SAM="results/minimap2/{sample}_mapping_filtered.sam",
    log:
        "logs/minimap/{sample}_samtools.log",
    conda:
        "../envs/sam-harmonization.yaml"
    threads: workflow.cores
    shell:
        """
        samtools view {input.IN_SAM} -F4 -h \
            | sam-flip.pl \
            | sam-keep-best.pl -rid -l -n=1 -po=0.1 \
                >{output.F_SAM} 2>>{log}
        """


rule sam_realign:
    """
    Realign filtered hits against the reference genes for accurate boundary trimming.
    """
    input:
        "results/minimap2/{sample}_mapping_filtered.sam",
        "resources/db/ref-genes.validated.fas",
        genome_file,
    output:
        "results/sam_realign/{sample}_realigned_mapping.sam",
    log:
        "logs/sam_realign/{sample}.log",
    conda:
        "../envs/realign.yaml"
    script:
        "../scripts/sam-realign.sh"


rule sam_extract_hit_seq:
    """
    Extract hit sequences from realigned SAM files.
    """
    input:
        "results/sam_realign/{sample}_realigned_mapping.sam",
    output:
        "results/genes/map_raw/{sample}.fas",
    log:
        "logs/sam_extract_hit_seq/{sample}.log",
    conda:
        "../envs/sam-harmonization.yaml"
    threads: min(4, workflow.cores)
    params:
        sim=0.7,
    shell:
        """
        cat {input} \
            | sam-filter.pl -minsim={params.sim} \
            | sam-extract-hit-seq.pl \
                >{output} 2>{log}
        """


rule rename_extracted_hit_seq:
    """
    Rename FASTA headers of extracted hit sequences to include the sample name.
    """
    input:
        "results/genes/map_raw/{sample}.fas",
    output:
        "results/genes/map/{sample}.fas",
    log:
        "logs/rename_extracted_hit_seq/{sample}.log",
    conda:
        "../envs/global.yaml"
    script:
        "../scripts/rename-extracted-hit-fasta.sh"


rule join_fragments:
    """
    Merge fragmented gene hits from the same locus into a single contiguous sequence.
    """
    input:
        "results/genes/map/{sample}.fas",
    output:
        "results/genes/join-fragments/{sample}.fas",
    log:
        "logs/join-fragments/{sample}.log",
    conda:
        "../envs/global.yaml"
    script:
        "../scripts/join-fragments.sh"


rule genes_deduplicate:
    """
    Remove exact-duplicate gene sequences within each sample.
    """
    input:
        "results/genes/join-fragments/{sample}.fas",
    output:
        "results/genes/deduplicated/{sample}.fas",
    log:
        "logs/genes_deduplicate/{sample}.log",
    conda:
        "../envs/biopython.yaml"
    script:
        "../scripts/genes_deduplicate.py"


rule map_all:
    """
    Concatenate per-sample gene FASTAs into a single pool for joint QC and alignment.
    """
    input:
        expand("results/genes/deduplicated/{sample}.fas", sample=SAMPLES),
    output:
        "results/genes/map-pool/map-pool.fas",
    log:
        "logs/map_all.log",
    conda:
        "../envs/global.yaml"
    shell:
        """
        cat {input} >{output} 2>{log}
        """
