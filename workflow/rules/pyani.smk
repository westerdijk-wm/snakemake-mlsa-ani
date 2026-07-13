rule pyani_input_dir:
    """
    Copy passing genomes into a flat input directory for pyANI.
    """
    input:
        genomes="results/QC/genome-list-pass.txt",
    output:
        temp(directory("results/ANI/pyani_input")),
    script:
        "../scripts/create-pyani-input.py"


rule pyani:
    """
    Compute pairwise ANI for all passing genomes using pyANI (ANIm method).
    """
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
    """
    Convert the pyANI percentage identity matrix to PHYLIP distance format.
    """
    input:
        "results/ANI/pyani/ANIm_percentage_identity.tab",
    output:
        "results/ANI/pyani/pyani_dist.phy",
    script:
        "../scripts/ani2distance-phylip.sh"


rule phylip_to_tsv:
    """
    Strip the PHYLIP header to produce a plain TSV distance matrix.
    """
    input:
        "results/ANI/pyani/pyani_dist.phy",
    output:
        "results/ANI/pyani/pyani_dist.tsv",
    shell:
        """
        tail -n +2 {input} >{output}
        """


rule nj_tree:
    """
    Infer a neighbour-joining tree from the ANI distance matrix.
    """
    input:
        tsv="results/ANI/pyani/pyani_dist.tsv",
    output:
        tree="results/ANI/pyani/pyani_dist.nwk",
    conda:
        "../envs/ani-typer.yaml"
    script:
        "../scripts/nj-for-dist-matrix.R"
