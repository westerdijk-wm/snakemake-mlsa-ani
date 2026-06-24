rule fasttree:
    input:
        "genes/concat/concat.fas",
    output:
        "phylogenetics/fasttree/fasttree.nwk",
    log:
        "logs/fasttree/fasttree.log",
    conda:
        "../envs/fasttree.yaml"
    threads: workflow.cores
    shell:
        """
        FastTree \
            -gtr \
            -nt \
            -gamma \
            {input} \
            >{output} \
            2>{log}
        """