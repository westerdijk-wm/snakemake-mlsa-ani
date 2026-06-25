rule fasttree:
    input:
        alignment="results/genes/concat/concat.fas",
    output:
        tree="results/phylogenetics/fasttree/fasttree.nwk",
    log:
        "logs/fasttree/fasttree.log",
    params:
        extra="-gtr -nt -gamma",
    wrapper:
        "v7.3.0/bio/fasttree"