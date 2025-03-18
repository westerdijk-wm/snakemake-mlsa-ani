# Scripts used for the workflow

## Missing scripts

Added (need to test):

- gff3-extract-cds.pl
- sam-realign.pl

Need to rewrite:

- gff3-filter-yaml.pl
- rename-extracted-gff-fasta.pl
- rename-extracted-hit-fasta.pl

### gff3-filter-yaml.pl

```bash
perl gff3-filter-yaml.pl "annotation/{strain}/{strain}.gff" mlsa.yml > filtered.gff
```

Should keep the relevant lines for the selected genes.

The expected structure of `mlsa.yml`

```yaml
genes:
- adk
- egl
```

```
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


rule sam_extract_hit_seq:
    input:
        IN="sam_realign/{sample}_realigned_mapping.sam"
    output:
        OUT="genes/map/{sample}.fas"
    shell:
       """
       sam-extract-hit-seq.pl {input.IN} | {rename2} - -strain={wildcards.sample} > {output.OUT}
       """
```
