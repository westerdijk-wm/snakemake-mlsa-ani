BOOTSTRAP = config.get("tree", {}).get("bootstrap", 150)

rule partition_file:
    input:
        "genes/concat.tab"
    output:
        "genes/concat.part"
    shell:
        """
        perl -ne '{parition_regex}' {input} > {output}
        """

rule raxml_bootstrap:
    input:
        fas="genes/concat.fas",
        part="genes/concat.part"
    output:
        boot="phylogeny/RAxML_bootstrap.analysis-bs",
        tree="phylogeny/RAxML_bestTree.analysis-bs"
    threads:
        workflow.cores
    log:
        "logs/raxml_bootstrap.log"
    conda:
        "../envs/raxml.yaml"
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
            -w `pwd`/phylogeny \
            > {log} 2>&1
        """

rule raxml_bipartitions:
    input:
        tree="phylogeny/RAxML_bestTree.analysis-bs",
        boot="phylogeny/RAxML_bootstrap.analysis-bs"
    output:
        "phylogeny/RAxML_bipartitions.analysis-ML-bs"
    threads:
        workflow.cores
    log:
        "logs/raxml_bipartitions.log"
    conda:
        "../envs/raxml.yaml"
    shell:
        """
        raxmlHPC \
            -m GTRGAMMA \
            -p 12345 \
            -f b \
            -t {input.tree} \
            -z {input.boot} \
            -n analysis-ML-bs \
            -w `pwd`/phylogeny \
            > {log} 2>&1
        """

rule reroot_tree:
    input:
        "phylogeny/RAxML_bipartitions.analysis-ML-bs"
    output:
        "results/MLSA.nwk"
    log:
        "logs/reroot_tree.log"
    shell:
        """
        nw_reroot -s {input} > {output} 2> {log}
        """