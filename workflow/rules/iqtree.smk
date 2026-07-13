BOOTSTRAP = config["tree"]["bootstrap"]


rule iqtree:
    """
    Infer a partitioned maximum-likelihood tree with bootstrapping using IQ-TREE.
    """
    input:
        fas="results/genes/concat/concat.fas",
        part="results/genes/concat/concat.part",
    output:
        "results/phylogenetics/iqtree/iqtree.ckp.gz",
        tree="results/phylogenetics/iqtree/iqtree.treefile",
        dir=directory("results/phylogenetics/iqtree"),
    log:
        "logs/iqtree/iqtree.log",
    conda:
        "../envs/iqtree.yaml"
    threads: workflow.cores
    params:
        bootstrap=BOOTSTRAP,
    shell:
        """
        iqtree \
            -s {input.fas} \
            -p {input.part} \
            -m MFP \
            -B {params.bootstrap} \
            -T {threads} \
            --prefix results/phylogenetics/iqtree/iqtree \
            >{log} 2>&1
        """


rule nwk_copy:
    input:
        tree="results/phylogenetics/iqtree/iqtree.treefile",
        dir=directory("results/phylogenetics/iqtree"),
    output:
        "results/phylogenetics/iqtree.nwk",
    log:
        "logs/iqtree/copy.log",
    conda:
        "../envs/global.yaml"
    shell:
        """
        cp {input.tree} {output} 2>{log}
        """
