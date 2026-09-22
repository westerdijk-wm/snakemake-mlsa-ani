rule skani:
    """
    Compute pairwise ANI for all passing genomes using skani (sketch-based, optimised for large genome sets).

    """
    input:
        PUBLIC_GENOME_TARGETS,
        genome_list="results/QC/genome-list-pass.txt",
    output:
        "results/ANI/skani/skani_pairs.tsv",
    log:
        "logs/ANI/skani.log",
    conda:
        "../envs/skani.yaml"
    threads: workflow.cores
    shell:
        """
        skani dist --rl {input.genome_list} --ql {input.genome_list} -t {threads} >{output} 2>{log}
        """
