rule fasttree:
    input:
        alignment="genes/concat/concat.fas",
    output:
        tree="phylogenetics/fasttree/fasttree.nwk",
    log:
        "logs/fasttree/fasttree.log",
    params:
        extra="-gtr -nt -gamma",
    wrapper:
        "v7.3.0/bio/fasttree"