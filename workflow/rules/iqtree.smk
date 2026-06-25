BOOTSTRAP = config["tree"]["bootstrap"]


rule iqtree:
    input:
        fas="results/genes/concat/concat.fas",
        part="results/genes/concat/concat.part",
    output:
        "results/phylogenetics/iqtree/iqtree.ckp.gz",
        tree="results/phylogenetics/iqtree/iqtree.treefile",
    log:
        "logs/iqtree/iqtree.log",
    conda:
        "../envs/iqtree.yaml"
    threads: workflow.cores
    params:
        bootstrap=BOOTSTRAP
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
