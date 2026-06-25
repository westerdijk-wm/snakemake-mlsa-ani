rule pyani_input_dir:
    input:
        genomes="results/QC/genome-list-pass.txt",
    output:
        temp(directory("results/ANI/pyani_input")),
    script:
        "../scripts/create-pyani-input.py"


rule pyani:
    input:
        "results/ANI/pyani_input",
    output:
        "results/ANI/pyani/ANIm_percentage_identity.tab",
        "results/ANI/pyani/ANIm_alignment_coverage.tab",
    log:
        "logs/ANI/pyani.log",
    conda:
        "../envs/pyani.yaml"
    threads: workflow.cores
    shell:
        """
        average_nucleotide_identity.py \
            -f \
            -i {input} \
            -o results/ANI/pyani \
            -m ANIm \
            -v 2>{log}
        """


rule pyani_to_phylip:
    input:
        "results/ANI/pyani/ANIm_percentage_identity.tab",
    output:
        "results/ANI/pyani/pyani_dist.phy",
    threads: min(4, workflow.cores)
    script:
        "../scripts/ani2distance-phylip.sh"


rule phylip_to_tsv:
    input:
        "results/ANI/pyani/pyani_dist.phy",
    output:
        "results/ANI/pyani/pyani_dist.tsv",
    threads: min(4, workflow.cores)
    shell:
        """
        tail -n +2 {input} >{output}
        """


rule nj_tree:
    input:
        tsv="results/ANI/pyani/pyani_dist.tsv",
    output:
        tree="results/ANI/pyani/pyani_dist.nwk",
    conda:
        "../envs/ani-typer.yaml"
    script:
        "../scripts/nj-for-dist-matrix.R"
