rule pyani_input_dir:
    input:
        genomes="QC/genome-list-pass.txt",
    output:
        temp(directory("ANI/pyani_input")),
    script:
        "../scripts/create-pyani-input.py"


rule pyani:
    input:
        "ANI/pyani_input",
    output:
        "ANI/pyani/ANIm_percentage_identity.tab",
        "ANI/pyani/ANIm_alignment_coverage.tab",
    log:
        "logs/ANI/pyani.log",
    threads: workflow.cores
    shell:
        """
        average_nucleotide_identity.py \
            -f \
            -i {input} \
            -o ANI/pyani \
            -m ANIm \
            -v 2>{log}
        """


rule pyani_to_phylip:
    input:
        "ANI/pyani/ANIm_percentage_identity.tab"
    output:
        "ANI/pyani/pyani_dist.phy"
    threads: min(4, workflow.cores)
    script:
        "../scripts/ani2distance-phylip.sh"

rule phylip_to_tsv:
    input:
        "ANI/pyani/pyani_dist.phy"
    output:
        "ANI/pyani/pyani_dist.tsv"
    threads: min(4, workflow.cores)
    shell:
        """
        tail -n +2 {input} > {output}
        """

rule nj_tree:
    input:
        tsv="ANI/pyani/pyani_dist.tsv"
    output:
        tree="ANI/pyani/pyani_dist.nwk"
    script:
        "../scripts/nj-for-dist-matrix.R"
