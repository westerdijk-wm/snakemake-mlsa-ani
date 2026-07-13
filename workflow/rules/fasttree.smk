rule fasttree:
    """
    Infer a rapid maximum-likelihood tree from the supermatrix alignment using FastTree.

    """
    input:
        alignment="results/genes/concat/concat.fas",
    output:
        tree="results/phylogenetics/fasttree/fasttree.nwk",
    log:
        "logs/fasttree/fasttree.log",
    conda:
        "../envs/fasttree.yaml"
    params:
        extra="-gtr -nt -gamma",
    wrapper:
        "v7.3.0/bio/fasttree"


rule nwk_copy:
    input:
        tree="results/phylogenetics/fasttree/fasttree.nwk",
    output:
        "results/phylogenetics/fasttree.nwk",
    log:
        "logs/fasttree/copy.log",
    conda:
        "../envs/global.yaml"
    shell:
        """
        cp {input.tree} {output} 2>{log}
        """
