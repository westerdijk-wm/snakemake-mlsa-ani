BOOTSTRAP = config["tree"]["bootstrap"]

rule iqtree:
    input:
        fas="genes/concat/concat.fas",
        part="genes/concat/concat.part"
    output:
        #dir=directory("phylogenetics/iqtree/"),
        "phylogenetics/iqtree/iqtree.ckp.gz",
        tree="phylogenetics/iqtree/iqtree.treefile"
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
            --prefix phylogenetics/iqtree/iqtree \
            > {log} 2>&1
        """

rule reroot_tree:
    input:
        "phylogenetics/iqtree/iqtree.treefile"
    output:
        "phylogenetics/MLSA.nwk"
    log:
        "logs/iqtree/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """