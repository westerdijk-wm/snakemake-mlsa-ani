BOOTSTRAP = config["tree"]["bootstrap"]

rule iqtree:
    input:
        fas="genes/concat/concat.fas",
        part="genes/concat/concat.part"
    output:
        tree="phylogeny/iqtree.treefile"
    threads:
        workflow.cores
    log:
        "logs/iqtree/iqtree.log"
    conda:
        "../envs/iqtree.yaml"
    shell:
        """
        iqtree \
            -s {input.fas} \
            -p {input.part} \
            -m MFP \
            -B {BOOTSTRAP} \
            -T {threads} \
            --prefix phylogeny/iqtree \
            > {log} 2>&1
        """

rule reroot_tree:
    input:
        "phylogeny/iqtree.treefile"
    output:
        "results/MLSA.nwk"
    log:
        "logs/iqtree/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """