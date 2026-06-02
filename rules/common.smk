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


# CHECKS
ANI_METHOD = config.get("ani_method", "none").lower()

VALID_ANI_METHODS = {
    "none",
    "fastani",
    "pyani",
    "skani"
}

if ANI_METHOD not in VALID_ANI_METHODS:
    raise ValueError(
        f"Invalid ani_method '{ANI_METHOD}'. "
        f"Choose from: {', '.join(sorted(VALID_ANI_METHODS))}"
    )


def ani_targets():
    if ANI_METHOD == "fastani":
        return ["ANI/fastani_table.tsv", "ANI/fastANI.pdf"]

    if ANI_METHOD == "pyani":
        return ["results/pyani_ANI.pdf", "results/pyani_cov_plot.pdf"]

    if ANI_METHOD == "skani":
        return ["ANI/skani_results.tsv"]

    return []

# Definitions
samrealign = "scripts/sam-realign.pl"
gff3extract = "scripts/gff3-extract-cds.pl"
gff3filter = "scripts/gff3-filter-yaml.pl"
rename = "scripts/rename-extracted-gff-fasta.pl"
rename2 = "scripts/rename-extracted-hit-fasta.pl"
script_code = r'if (/>([^\|]+)\|(\S+)/) { $h{$1}->{$2}++}; END{for my $a (sort keys %h) { for (keys %{$h{$a}}) {print "$a\t$_\t" . $h{$a}->{$_} . "\n"}}}'
sp_perl = r's/\ /_/g; s/^(\S+)\t/$1\t$1_/; print'
parition_regex=r's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;'
autoconcatenate_regex=r'^>([^\|]*)'