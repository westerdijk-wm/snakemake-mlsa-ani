rule skani:
    input:
        "QC/genome-list-pass.txt",
    output:
        "ANI/skani/skani_pairs.tsv",
    log:
        "logs/ANI/skani.log",
    conda:
        "../envs/skani.yaml"
    threads: workflow.cores
    shell:
        """
        skani triangle -l {input} -t {threads} -E >{output} 2>{log}
        """


rule skani_table:
    input:
        "ANI/skani/skani_pairs.tsv",
    output:
        "ANI/skani/skani_table.tsv",
    shell:
        """
        python workflow/scripts/ani2table.py {input} {output}
        """


rule skani_plot:
    input:
        tree="phylogenetics/MLSA.nwk",
        ani="ANI/skani/skani_table.tsv",
    output:
        pdf=report("ANI/skani/skani.pdf", caption="../report/ani.rst", category="ANI"),
    log:
        "logs/ANI/skani_plot.log",
    threads: min(4, workflow.cores)
    params:
        labels=config.get("sample_labels", ""),
    script:
        "../scripts/tree-ANI-heatmap.R"
