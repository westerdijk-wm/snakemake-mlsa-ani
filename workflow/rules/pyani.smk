rule pyani_input_dir:
    input:
        genomes="report/genome-list-pass.txt"
    output:
        temp(directory("ANI/pyani_input"))
    script:
        "workflow/scripts/create_pyani_input.py"

rule pyani:
    input:
        "ANI/pyani_input"
    output:
        "ANI/pyani/ANIm_percentage_identity.tab",
        "ANI/pyani/ANIm_alignment_coverage.tab"
    threads: 
        workflow.cores
    log:
        "logs/ANI/pyani.log"
    shell:
        """
        average_nucleotide_identity.py \
            -f \
            -i {input} \
            -o ANI/pyani \
            -m ANIm \
            -v -l {log} \
        """

rule pyani_distance:
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
        workflow/scripts/ani2distance-phylip.pl {input} >{output[0]}
        tail -n +2 {output[0]} >{output[1]}
        workflow/scripts/nj-for-dist-matrix.R {output[1]} {output[2]}
        """

rule pyani_plot:
    input:
        "ANI/pyani_dist.nwk",
        "ANI/pyani/ANIm_percentage_identity.tab"
    output:
        "results/pyani_percentage_identity_plot.pdf"
    threads: 
        4
    log:
        "logs/ANI/pyani_plot.log"
    shell:
        """
        tree-ANI-heatmap.R {input} {output} 2> {log}
        """

rule pyani_cov_plot:
    input:
        "ANI/pyani_dist.nwk",
        "ANI/pyani/ANIm_alignment_coverage.tab"
    output:
        "results/pyani_cov_plot.pdf"
    threads: 
        4
    log:
        "logs/ANI/pyani_cov_plot.log"
    shell:
        """
        tree-heatmap.R {input} {output} 2> {log}
        """
