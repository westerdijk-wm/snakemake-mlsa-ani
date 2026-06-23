rule fastani:
    input:
        "QC/genome-list-pass.txt"
    output:
        "ANI/fastani/fastani_pairs.tsv"
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
        "ANI/fastani/fastani_pairs.tsv"
    output:
        "ANI/fastani/fastani_table.tsv"
    shell:
        """
        python workflow/scripts/ani2table.py {input} {output}
        """

rule fastANI_plot:
    input:
        tree="phylogenetics/MLSA.nwk",
        ani="ANI/fastani/fastani_table.tsv"
    output:
        report(
            "ANI/fastani/fastani.pdf",
            caption="../report/ani.rst",
            category="ANI"
        )
    params:
        labels=config.get("sample_labels", "")
    threads: 
        min(4, workflow.cores)
    log:
        "logs/ANI/fastani_plot.log"
    shell:
        """
        Rscript workflow/scripts/tree-ANI-heatmap.R \
            {input.tree} \
            {input.ani} \
            {output} \
            {params.labels} \
            2> {log}
        """
