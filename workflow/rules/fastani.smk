rule fastani:
    input:
        "report/genome-list-pass.txt"
    output:
        "ANI/fastani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/ANI/fastani.log"
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
        python workflow/scripts/ani2table.py {input} {output}
        """

rule fastANI_plot:
    input:
        "results/MLSA.nwk",
        "ANI/fastani_table.tsv"
    output:
        "ANI/fastani.pdf"
    threads: 
        4
    log:
        "logs/ANI/fastani_plot.log"
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """
