BOOTSTRAP = config.get("tree", {}).get("bootstrap", 1000)

rule iqtree:
    input:
        "genes/concat.fas"
    output:
        tree="phylogeny/iqtree.treefile"
    threads:
        workflow.cores
    log:
        "logs/iqtree.log"
    conda:
        "../envs/iqtree.yaml"
    shell:
        """
        iqtree \
            -s {input} \
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
        "logs/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """