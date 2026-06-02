# ANI
rule fastani:
    input:
        GENOMES
    output:
        "report/genome-list.txt",
        "report/fastani_pairs.tsv"
    threads:
        workflow.cores
    log:
        "logs/fastANI.log"
    shell:
        """
        ls {input} > {output[0]}
        fastANI --rl {output[0]} --ql {output[0]} \
            -o {output[1]} \
            -t {threads} \
            > {log} 2>&1
        """

rule fastani_table:
    input:
        "report/fastani_pairs.tsv"
    output:
        "report/fastani_table.tsv"
    threads: 
        workflow.cores
    shell:
        """
        less {input} | cut -f1-3 | sort | perl -ne '{fastani_perl}' | table-cast.pl -s > {output}
        """

rule fastANI_plot:
    input:
        "report/MLSA.nwk",
        "report/fastani_table.tsv"
    output:
        "results/fastANI.pdf"
    threads: 
        4
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """