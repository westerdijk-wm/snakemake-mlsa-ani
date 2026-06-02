
# ANI
rule pyani:
    input:
        "report/genome-list-pass.txt"
    output:
        "ANI/pyani/ANIm_percentage_identity.tab",
        "ANI/pyani/ANIm_alignment_coverage.tab"
    threads: 
        workflow.cores
    shell:
        """
        average_nucleotide_identity.py \
            -f \
            -i {input} \
            -o ANI/pyani \
            -m ANIm
        """

rule ani_distance:
    input:
        "ANI/pyani/ANIm_percentage_identity.tab"
    output:
        "ANI/pyani_dist.phy",
        "ANI/pyani_dist.tsv",
        "ANI/pyani_dist.nwk"
    threads: 
        8
    shell:
        """
        scripts/ani2distance-phylip.pl {input} >{output[0]}
        tail -n +2 {output[0]} >{output[1]}
        # scripts/nj-for-phylip-distance-matrix.pl {output[0]} | nw_reroot - > {output[1]}
        scripts/nj-for-dist-matrix.R {output[1]} {output[2]}
        """

rule ani_plot:
    input:
        "ANI/pyani_dist.nwk",
        "ANI/pyani/ANIm_percentage_identity.tab"
    output:
        "results/pyani_ANI.pdf"
    threads: 
        4
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """

rule cov_plot:
    input:
        "ANI/pyani_dist.nwk",
        "ANI/pyani/ANIm_alignment_coverage.tab"
    output:
        "results/pyani_cov_plot.pdf"
    threads: 
        4
    shell:
        """
        tree-heatmap.R {input} {output}
        """
