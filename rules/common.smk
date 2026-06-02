from pathlib import Path

GENOME_EXTS = [".fna", ".fasta", ".fas", ".fa"]

SAMPLES = sorted({
    p.stem
    for p in Path("genomes").iterdir()
    if p.suffix.lower() in GENOME_EXTS
})

def genome_file(wildcards):
    for ext in GENOME_EXTS:
        fn = Path("genomes") / f"{wildcards.sample}{ext}"
        if fn.exists():
            return str(fn)

    raise FileNotFoundError(
        f"No genome found for sample '{wildcards.sample}'"
    )

GENOMES = sorted(
    str(p)
    for p in Path("genomes").iterdir()
    if p.suffix.lower() in GENOME_EXTS
)

FASTANI_OUTPUTS = ["report/fastani_table.tsv"] if config.get("run_fastani", False) else []
fastani_perl = r's/\R//g; @a = map{s/^.*\///; s/\.fna$//; $_} split/\t/; $a[2] /= 100; print join("\t", @a), "\n"'
samrealign = "scripts/sam-realign.pl"
gff3extract = "scripts/gff3-extract-cds.pl"
gff3filter = "scripts/gff3-filter-yaml.pl"
rename = "scripts/rename-extracted-gff-fasta.pl"
rename2 = "scripts/rename-extracted-hit-fasta.pl"
script_code = r'if (/>([^\|]+)\|(\S+)/) { $h{$1}->{$2}++}; END{for my $a (sort keys %h) { for (keys %{$h{$a}}) {print "$a\t$_\t" . $h{$a}->{$_} . "\n"}}}'
sp_perl = r's/\ /_/g; s/^(\S+)\t/$1\t$1_/; print'
parition_regex=r's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;'
autoconcatenate_regex=r'^>([^\|]*)'