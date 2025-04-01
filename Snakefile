configfile: "mlsa.yml"

samrealign = "scripts/sam-realign.pl"
gff3extract = "scripts/gff3-extract-cds.pl"


gff3filter = "scripts/gff3-filter-yaml.pl"
rename = "scripts/rename-extracted-gff-fasta.pl"
rename2 = "scripts/rename-extracted-hit-fasta.pl"


# Annotate genomes
rule prokka:
    """
    Annotate genome assemblies using prokka
    """
    input:
        "genomes/{strain}.fna"
    output:
        "annotation/{strain}/{strain}.fna", # Genome sequences (with contig names matching with gff)
        #"annotation/{strain}/{strain}.log", # log
        #"annotation/{strain}/{strain}.faa", # Protein sequences
        #"annotation/{strain}/{strain}.ffn",  # gene sequences also rRNA
        "annotation/{strain}/{strain}.gff" # GFF annotation
    threads: 8
    shell:
        "prokka {input} --force --cpus {threads} --outdir annotation/{wildcards.strain} --prefix {wildcards.strain} --centre BioInt --compliant"


# Assembly quality check
rule fasta_assembly_statistics:
    input:
        "assemblies/{strain}/contigs.fasta"
    output:
        "assembly_qc/{strain}.stats"
    shell:
        "fasta_assembly_statistics {input} >{output}"


rule gff:
    input:
        "annotation/{strain}/{strain}.gff",
        "mlsa.yml",
        "annotation/{strain}/{strain}.fna"
    output:
        "genes/gff/{strain}.fas"
    shell:
        """
        perl {gff3filter} {input[0]} {input[1]} |
        perl {gff3extract} - {input[2]} |
        {rename} - -strain={wildcards.strain} > {output}
        """


FILES = glob_wildcards('genomes/{strain}.fna')


rule gff_all:
    input:
        expand("genes/gff/{strain}.fas", strain=FILES.strain)
    output:
        "genes/gff-pool.fas"
    shell:
        "cat {input} > {output}"


rule minimap:
    input:
        IN_GENOME="genomes/{sample}.fna",
        IN_DATABASE="db/ref-genes.fas"
    output:
        OUT_SAM="minimap/{sample}_mapping.sam",
        F_SAM="minimap/{sample}_mapping_filtered.sam",
    threads: workflow.cores
    shell:
        """
        minimap2 -a -x map-ont {input.IN_GENOME} {input.IN_DATABASE} > {output.OUT_SAM}  # Map locus pool onto the genome
        samtools view {output.OUT_SAM} -F4 -h |   # Filter away unmapped locus sequences 
        sam-flip.pl | sam-keep-best.pl -rid -l -n=1 -po=0.1 > {output.F_SAM}      # Make the locus sequences the reference, and keep best hit for query (contig) per region => best fitting reference, based on ref-identity value 
        """


rule sam_realign:
    input:
        IN_HITS="minimap/{sample}_mapping_filtered.sam",
        IN_DATABASE="db/ref-genes.fas",
        IN_QUERY="genomes/{sample}.fna"
    output:
        OUT_SAM="sam_realign/{sample}_realigned_mapping.sam"
    shell:
        """
        {samrealign} {input.IN_HITS} {input.IN_DATABASE} {input.IN_QUERY} >{output.OUT_SAM}
        """


## extract locus sequences
rule sam_extract_hit_seq:
    input:
        IN="sam_realign/{sample}_realigned_mapping.sam"
    output:
        OUT="genes/map/{sample}.fas"
    shell:
        """
        cat {input.IN} | sam-filter.pl -minsim=0.8 | sam-extract-hit-seq.pl | {rename2} - -strain={wildcards.sample} > {output.OUT}
        """


rule map_all:
    input:
        expand("genes/map/{strain}.fas", strain=FILES.strain)
    output:
        "genes/map/mapped-all.log",
        "genes/map-pool.fas"
    shell:
        "cat {input} > {output[1]}; touch {output[0]}"

rule align:
    input:
        "genes/map-pool.fas"
    output:
        "genes/aligned/{gene}.fas"
    shell:
        """
        cat {input} | fasta_grep {wildcards.gene} | muscle > {output}
        """

rule concat:
    input:
        expand("genes/aligned/{gene}.fas", gene=config["genes"])
    output:
        "genes/concat.fas",
        "genes/concat.tab"
    shell:
        """
        fasta_autoconcatenate -r='^>([^\|]*)' {input} >{output[0]} 2>{output[1]}
        """

# ANI
rule pyani:
    input:
        expand("genomes/{strain}.fna", strain=FILES.strain)
    output:
        "report/pyani/ANIm_percentage_identity.tab",
        "report/pyani/ANIm_alignment_coverage.tab"
    shell:
        "average_nucleotide_identity.py -f -i genomes/ -o report/pyani -m ANIm"


rule ani_distance:
    input:
        "report/pyani/ANIm_percentage_identity.tab"
    output:
        "report/pyani_dist.phy",
        "report/pyani_dist.tsv",
        "report/pyani_dist.nwk"
    shell:
        """
        scripts/ani2distance-phylip.pl {input} >{output[0]}
        tail -n +2 {output[0]} >{output[1]}
        # scripts/nj-for-phylip-distance-matrix.pl {output[0]} | nw_reroot - > {output[1]}
        scripts/nj-for-dist-matrix.R {output[1]} {output[2]}
        """


rule ani_plot:
    input:
        "report/pyani_dist.nwk",
        "report/pyani/ANIm_percentage_identity.tab"
    output:
        "results/pyani_ANI.pdf"
    shell:
        """
        tree-ANI-heatmap.R {input} {output}
        """

rule cov_plot:
    input:
        "report/pyani_dist.nwk",
        "report/pyani/ANIm_alignment_coverage.tab"
    output:
        "results/pyani_cov_plot.pdf"
    shell:
        """
        tree-heatmap.R {input} {output}
        """


rule fastani:
    input:
        expand("genomes/{strain}.fna", strain=FILES.strain)
    output:
        "report/genome-list.txt",
        "report/fastani_pairs.tsv"
    threads: 30
    shell:
        """
        ls {input} > {output[0]}
        fastANI --rl {output[0]} --ql {output[0]} -o {output[1]} -t {threads}
        """

fastani_perl = 's/\R//g; @a = map{s/^.*\///; s/\.fna$//; $_} split/\t/; $a[2] /= 100; print join("\t", @a), "\n"'

rule fastani_table:
    input:
        "report/fastani_pairs.tsv"
    output:
        "report/fastani_table.tsv"
    threads: 30
    shell:
        """
        less {input} | cut -f1-3 | sort | perl -ne '{fastani_perl}' | table-cast.pl -s > {output}
        """

        
rule spcall:
    input:
        "db/types.tsv",
        "report/fastani_table.tsv"
    output:
        "report/sp_calls_long.tsv"        
    shell:
        """
        ani-typer.pl -type {input[0]} -ani {input[1]} | cut -f1,2 >{output}
        """

script_code = 'if (/>([^\|]+)\|(\S+)/) { $h{$1}->{$2}++}; END{for my $a (sort keys %h) { for (keys %{$h{$a}}) {print "$a\t$_\t" . $h{$a}->{$_} . "\n"}}}'
        
rule extract_report:
    input:
        "genes/{method}-pool.fas"
    output:
        "report/{method}-report.tsv"
    shell:
        """
        perl -ne '{script_code}' {input} > {output}
        """

rule overview:
    input:
        "report/{method}-report.tsv",
        "report/sp_calls_long.tsv"
    output:
        "report/overview_{method}.csv"
    shell:
        """
        cut -f1,2 {input[1]} | perl -ne 's/\t/\ttaxon\t/; print' >report/sp
        cat report/sp {input[0]} | table-cast.pl -s | perl -ne 's/^\t/ID\t/; print' | sed 's/\t/,/g' > {output}
        rm report/sp
        """

sp_perl = 's/\ /_/g; s/^(\S+)\t/$1\t$1_/; print'

rule sp_tags:
    input:
        "report/overview_map.csv"
    output:
        "report/sp-tags.tsv"
    shell:
        """
        cat {input} | csvq -f TSV 'select id,taxon FROM stdin ORDER BY taxon' | grep -v taxon | perl -ne '{sp_perl}' >{output}
        """

rule rename_tree:
    input:
        "report/sp-tags.tsv",
        "report/{tree}.nwk"
    output:
        "report/{tree}-sp-tagged.nwk"
    shell:
        """
        rename-ids.pl {input} > {output}
        """

