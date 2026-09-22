module smkwf_oligo_screening:
    snakefile:
        github(
            "b-brankovics/smkwf-oligo-screening",
            path="workflow/Snakefile",
            branch="main",
        )
    config:
        config


use rule * from smkwf_oligo_screening exclude all, lastal_nucl_x_nucl, extract_amplicon_seqs, get_genome as oligo_*


# use rule * from smkwf_oligo_screening exclude all, lastal_nucl_x_nucl, extract_amplicon_seqs as oligo_*


use rule lastal_nucl_x_nucl from smkwf_oligo_screening with:
    input:
        # data="resources/genomes/{sample}.fas",
        data=genome_file,
        lastdb="resources/lastaldb.prj",


use rule extract_amplicon_seqs from smkwf_oligo_screening with:
    input:
        genome=genome_file,
        regions="results/amplicon/{sample}/regions",


rule label_amplicon_seqs:
    """
    Label amplicon sequences with sample name for downstream processing.
    """
    input:
        "results/amplicon/{sample}/amplicons.fas",
    output:
        "results/amplicon/{sample}/amplicons_labeled.fas",
    log:
        "logs/label_amplicon_seqs/{sample}.log",
    conda:
        "../envs/global.yaml"
    shell:
        """
        cat {input} | sed -E 's/>(\\S+) (\\S+)/>{wildcards.sample}|\\2 \\1/' >{output} 2>{log}
        """


rule genes_deduplicate:
    """
    Remove exact-duplicate gene sequences within each sample.
    """
    input:
        "results/amplicon/{sample}/amplicons_labeled.fas",
    output:
        "results/amplicon/deduplicated/{sample}.fas",
    log:
        "logs/genes_deduplicate/{sample}.log",
    conda:
        "../envs/biopython.yaml"
    script:
        "../scripts/genes_deduplicate.py"


rule combine_all:
    """
    Concatenate per-sample gene FASTAs into a single pool for joint QC and alignment.
    """
    input:
        expand("results/amplicon/deduplicated/{sample}.fas", sample=SAMPLES),
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
