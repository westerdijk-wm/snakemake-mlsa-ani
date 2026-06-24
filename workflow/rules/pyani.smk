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


rule pyani_distance:
    input:
        "ANI/pyani/ANIm_percentage_identity.tab",
    output:
        "ANI/pyani/pyani_dist.phy",
        "ANI/pyani/pyani_dist.tsv",
        "ANI/pyani/pyani_dist.nwk",
    threads: min(4, workflow.cores)
    shell:
        """
        workflow/scripts/ani2distance-phylip.pl {input} >{output[0]}
        tail -n +2 {output[0]} >{output[1]}
        workflow/scripts/nj-for-dist-matrix.R {output[1]} {output[2]}
        """
