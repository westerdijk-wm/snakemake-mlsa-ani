rule skani:
    input:
        "report/genome-list-pass.txt"
    output:
        "ANI/skani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/skani.log"
    conda:
        "../envs/skani.yaml"
    shell:
        """
        skani triangle  -l {input} -t {threads} -E > {output} 2> {log}
        """

rule skani_table:
    input:
        "ANI/skani_pairs.tsv"
    output:
        "ANI/skani_table.tsv"
    shell:
        """
        python ../scripts/ani2table.py {input} {output}
        """
