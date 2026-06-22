rule skani:
    input:
        "QC/genome-list-pass.txt"
    output:
        "ANI/skani/skani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/ANI/skani.log"
    conda:
        "../envs/skani.yaml"
    shell:
        """
        skani triangle  -l {input} -t {threads} -E > {output} 2> {log}
        """

rule skani_table:
    input:
        "ANI/skani/skani_pairs.tsv"
    output:
        "ANI/skani/skani_table.tsv"
    shell:
        """
        python workflow/scripts/ani2table.py {input} {output}
        """

rule skani_plot:
    input:
        tree="phylogenetics/MLSA.nwk",
        ani="ANI/skani/skani_table.tsv"
    output:
        report(
            "ANI/skani/skani.pdf",
            caption="../report/ani.rst",
            category="ANI"
        )
    params:
        labels=config.get("sample_labels", "")
    threads: 
        min(4, workflow.cores)
    log:
        "logs/ANI/skani_plot.log"
    shell:
        """
        Rscript workflow/scripts/tree-ANI-heatmap.R \
            {input.tree} \
            {input.ani} \
            {output} \
            {params.labels} \
            2> {log}
        """
