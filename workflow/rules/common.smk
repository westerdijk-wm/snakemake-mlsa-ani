from pathlib import Path

# Genome helper functions and variables
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

# ANI helper functions and variables
ANI_METHOD = config.get("ani_method", "none").lower()

VALID_ANI_METHODS = {
    "none",
    "fastani",
    "pyani",
    "skani"
}

if ANI_METHOD not in VALID_ANI_METHODS:
    raise ValueError(
        f"Invalid ani_method '{ANI_METHOD}'."
    )

ANI_RULES = None
ANI_TARGETS = []

if ANI_METHOD == "fastani":

    ANI_RULES = "rules/fastani.smk"

    ANI_TARGETS = [
        "ANI/fastani_table.tsv",
        "ANI/fastani.pdf"
    ]

elif ANI_METHOD == "pyani":

    ANI_RULES = "rules/pyani.smk"

    ANI_TARGETS = [
        "results/pyani_percentage_identity_plot.pdf",
        "results/pyani_cov_plot.pdf"
    ]

elif ANI_METHOD == "skani":

    ANI_RULES = "rules/skani.smk"

    ANI_TARGETS = [
        "ANI/skani_table.tsv",
    ]

# Tree helper functions and variables
TREE_METHOD = config.get(
    "tree", {}
).get(
    "method",
    "iqtree"
).lower()

VALID_TREE_METHODS = {
    "raxml",
    "iqtree",
    "fasttree"
}

TREE_RULES = None
TREE_TARGETS = [
    "results/MLSA.nwk"
]

if TREE_METHOD not in VALID_TREE_METHODS:
    raise ValueError(
        f"Invalid tree method '{TREE_METHOD}'."
    )

if TREE_METHOD == "raxml":

    TREE_RULES = "rules/raxml.smk"

elif TREE_METHOD == "iqtree":

    TREE_RULES = "rules/iqtree.smk"

elif TREE_METHOD == "fasttree":

    TREE_RULES = "rules/fasttree.smk"

    if config.get("tree", {}).get("bootstrap") is not None:
        print(
            "INFO: tree.bootstrap is ignored for FastTree."
        )

# Definitions
gff3extract = "workflow/scripts/gff3-extract-cds.pl"
gff3filter = "workflow/scripts/gff3-filter-yaml.pl"
script_code = r'if (/>([^\|]+)\|(\S+)/) { $h{$1}->{$2}++}; END{for my $a (sort keys %h) { for (keys %{$h{$a}}) {print "$a\t$_\t" . $h{$a}->{$_} . "\n"}}}'
sp_perl = r's/\ /_/g; s/^(\S+)\t/$1\t$1_/; print'
parition_regex=r's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;'
autoconcatenate_regex=r'^>([^\|]*)'