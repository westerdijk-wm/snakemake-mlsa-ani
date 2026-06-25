rule skani:
    input:
        "results/QC/genome-list-pass.txt",
    output:
        "results/ANI/skani/skani_pairs.tsv",
    log:
        "logs/ANI/skani.log",
    conda:
        "../envs/skani.yaml"
    threads: workflow.cores
    shell:
        """
        skani triangle -l {input} -t {threads} -E >{output} 2>{log}
        """