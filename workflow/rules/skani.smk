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
