rule fastani:
    """
    Compute pairwise ANI for all passing genomes using fastANI.
    """
    input:
        "results/QC/genome-list-pass.txt",
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
            --rl {input} \
            --ql {input} \
            -o {output} \
            -t {threads} \
            >{log} 2>&1
        """
