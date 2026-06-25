BOOTSTRAP = config["tree"]["bootstrap"]


rule raxml_bootstrap:
    input:
        fas="results/genes/concat/concat.fas",
        part="results/genes/concat/concat.part",
    output:
        boot="results/phylogenetics/raxml/RAxML_bootstrap.analysis-bs",
        tree="results/phylogenetics/raxml/RAxML_bestTree.analysis-bs",
    log:
        "logs/raxml/raxml_bootstrap.log",
    conda:
        "../envs/raxml.yaml"
    threads: workflow.cores
    shell:
        """
        raxmlHPC-PTHREADS \
            -T {threads} \
            -m GTRGAMMA \
            -p 12345 \
            -x 12345 \
            -f a \
            -# {BOOTSTRAP} \
            -q {input.part} \
            -s {input.fas} \
            -n analysis-bs \
            -w $(pwd)/results/phylogenetics/raxml \
            >{log} 2>&1
        """


rule raxml_bipartitions:
    input:
        tree="results/phylogenetics/raxml/RAxML_bestTree.analysis-bs",
        boot="results/phylogenetics/raxml/RAxML_bootstrap.analysis-bs",
    output:
        "results/phylogenetics/raxml/RAxML_bipartitions.analysis-ML-bs",
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
        """
