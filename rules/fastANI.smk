rule fastani:
    input:
        "report/genome-list-pass.txt"
    output:
        "ANI/fastani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/fastANI.log"
    shell:
        """
        fastANI \
            --rl {input} \
            --ql {input} \
            -o {output} \
            -t {threads} \
            > {log} 2>&1
        """

rule fastani_table:
    input:
        "ANI/fastani_pairs.tsv"
    output:
        "ANI/fastani_table.tsv"
    shell:
        """
        python scripts/ani2table.py {input} {output}
        """

rule fastANI_plot:
    input:
        "results/MLSA.nwk",
        "ANI/fastani_table.tsv"
    output:
        "ANI/fastANI.pdf"
    threads: 
        4
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """
