rule fastani:
    input:
        "results/QC/genome-list-pass.txt",
    output:
        "results/ANI/fastani/fastani_pairs.tsv",
    log:
        "logs/ANI/fastani.log",
    threads: workflow.cores
    conda:
        "../envs/fastani.yaml"
    shell:
        """
        fastANI \
            --rl {input} \
            --ql {input} \
            -o {output} \
            -t {threads} \
            >{log} 2>&1
        """
