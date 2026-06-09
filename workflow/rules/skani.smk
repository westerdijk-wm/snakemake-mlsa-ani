rule skani:
    input:
        "report/genome-list-pass.txt"
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
        "phylogenetics/MLSA.nwk",
        "ANI/skani/skani_table.tsv"
    output:
        "ANI/skani/skani.pdf"
    threads: 
        4
    log:
        "logs/ANI/skani_plot.log"
    shell:
        """
        Rscript workflow/scripts/tree-ANI-heatmap.R {input} {output} 2> {log}
        """
