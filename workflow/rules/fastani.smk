rule fastani:
    input:
        "QC/genome-list-pass.txt",
    output:
        "ANI/fastani/fastani_pairs.tsv",
    log:
        "logs/ANI/fastani.log",
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
