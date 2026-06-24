BOOTSTRAP = config["tree"]["bootstrap"]


rule iqtree:
    input:
        fas="genes/concat/concat.fas",
        part="genes/concat/concat.part",
    output:
        #dir=directory("phylogenetics/iqtree/"),
        "phylogenetics/iqtree/iqtree.ckp.gz",
        tree="phylogenetics/iqtree/iqtree.treefile",
    log:
        "logs/iqtree/iqtree.log",
    conda:
        "../envs/iqtree.yaml"
    threads: workflow.cores
    shell:
        """
        iqtree \
            -s {input.fas} \
            -p {input.part} \
            -m MFP \
            -B {BOOTSTRAP} \
            -T {threads} \
            --prefix phylogenetics/iqtree/iqtree \
            >{log} 2>&1
        """