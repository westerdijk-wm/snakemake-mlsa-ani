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


rule reroot_tree:
    input:
        "phylogenetics/fasttree/fasttree.nwk",
    output:
        "phylogenetics/MLSA.nwk",
    log:
        "logs/fasttree/reroot_tree.log",
    shell:
        """
        nw_reroot -s {input} >{output} 2>{log}
        """
