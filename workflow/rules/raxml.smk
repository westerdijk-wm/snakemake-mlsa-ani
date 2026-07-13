BOOTSTRAP = config["tree"]["bootstrap"]


rule raxml_bootstrap:
    """
    Infer the best-scoring ML tree and bootstrap replicates with RAxML under GTRGAMMA.

    """
    input:
        fas="results/genes/concat/concat.fas",
        part="results/genes/concat/concat.part",
    output:
        boot="results/phylogenetics/raxml/RAxML_bootstrap.analysis-bs",
        tree="results/phylogenetics/raxml/RAxML_bestTree.analysis-bs",
        dir=directory("results/phylogenetics/raxml"),
    log:
        "logs/raxml/raxml_bootstrap.log",
    conda:
        "../envs/raxml.yaml"
    threads: workflow.cores
    params:
        bootstrap=BOOTSTRAP,
    shell:
        """
        raxmlHPC-PTHREADS \
            -T {threads} \
            -m GTRGAMMA \
            -p 12345 \
            -x 12345 \
            -f a \
            -# {params.bootstrap} \
            -q {input.part} \
            -s {input.fas} \
            -n analysis-bs \
            -w $(pwd)/results/phylogenetics/raxml \
            >{log} 2>&1
        """


rule raxml_bipartitions:
    """
    Map bootstrap support values onto the best-scoring tree to produce the final bipartitions tree.

    """
    input:
        tree="results/phylogenetics/raxml/RAxML_bestTree.analysis-bs",
        boot="results/phylogenetics/raxml/RAxML_bootstrap.analysis-bs",
        dir=directory("results/phylogenetics/raxml"),
    output:
        tree="results/phylogenetics/raxml.nwk",
    log:
        "logs/raxml/raxml_bipartitions.log",
    conda:
        "../envs/raxml.yaml"
    threads: workflow.cores
    shell:
        """
        raxmlHPC \
            -m GTRGAMMA \
            -p 12345 \
            -f b \
            -t {input.tree} \
            -z {input.boot} \
            -n analysis-ML-bs \
            -w $(pwd)/results/phylogenetics/raxml \
            >{log} 2>&1
        cp results/phylogenetics/raxml/RAxML_bipartitions.analysis-ML-bs {output.tree} 2>>{log}
        """
