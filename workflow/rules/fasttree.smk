rule fasttree:
    input:
        "genes/concat/concat.fas"
    output:
        "phylogeny/fasttree.nwk"
    threads:
        workflow.cores
    log:
        "logs/fasttree/fasttree.log"
    conda:
        "../envs/fasttree.yaml"
    shell:
        """
        FastTree \
            -gtr \
            -gamma \
            {input} \
            > {output} \
            2> {log}
        """

rule reroot_tree:
    input:
        "phylogeny/fasttree.nwk"
    output:
        "results/MLSA.nwk"
    log:
        "logs/fasttree/reroot_tree.log"
    conda:
        "../envs/fasttree.yaml"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """