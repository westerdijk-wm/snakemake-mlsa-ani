rule fastani:
    """
    Compute pairwise ANI for all passing genomes using fastANI.
    """
    input:
        PUBLIC_GENOME_TARGETS,
        genome_list="results/QC/genome-list-pass.txt",
    output:
        "results/ANI/fastani/fastani_pairs.tsv",
    log:
        "logs/ANI/fastani.log",
    conda:
        "../envs/fastani.yaml"
    threads: workflow.cores
    shell:
        """
        fastANI \
            --rl {input.genome_list} \
            --ql {input.genome_list} \
            -o {output} \
            -t {threads} \
            >{log} 2>&1
        """
