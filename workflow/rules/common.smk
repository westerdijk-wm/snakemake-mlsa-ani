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

ANI_RULES = []
ANI_TARGETS = []

if ANI_METHOD == "fastani":

    ANI_RULES.append(
        "rules/fastani.smk"
    )

    ANI_TARGETS.extend([
        "ANI/fastani_table.tsv",
        "ANI/fastani.pdf"
    ])

elif ANI_METHOD == "pyani":

    ANI_RULES.append(
        "rules/pyani.smk"
    )

    ANI_TARGETS.extend([
        "results/pyani_percentage_identity_plot.pdf",
        "results/pyani_cov_plot.pdf"
    ])

elif ANI_METHOD == "skani":

    ANI_RULES.append(
        "rules/skani.smk"
    )

    ANI_TARGETS.extend([
        "ANI/skani_table.tsv"
    ])

elif ANI_METHOD == "none":

    print(
        "INFO: ANI analysis is disabled. No ANI rules will be included."
    )

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

TREE_CFG = config.get("tree", {})
TREE_METHOD = TREE_CFG.get("method", "iqtree").lower()
BOOTSTRAP = TREE_CFG.get("bootstrap")

if TREE_METHOD == "raxml":
    TREE_RULES = "rules/raxml.smk"

    print(
        f"INFO: Building MLSA tree with RAxML "
        f"({BOOTSTRAP} bootstrap replicates)."
    )

    if BOOTSTRAP < 1:
        print(
            "ERROR: Bootstrap replicates below 1 not allowed for RAxML."
        )

    elif BOOTSTRAP < 100:
        print(
            "WARNING: Fewer than 100 bootstrap replicates "
            "may result in unstable support estimates."
        )

elif TREE_METHOD == "iqtree":
    TREE_RULES = "rules/iqtree.smk"

    print(
        f"INFO: Building MLSA tree with IQ-TREE "
        f"({BOOTSTRAP} ultrafast bootstrap replicates)."
    )

    if BOOTSTRAP < 100:
        print(
            "ERROR: Bootstrap replicates below 100 not allowed for IQ-TREE."
        )

    elif BOOTSTRAP < 1000:
        print(
            "WARNING: IQ-TREE ultrafast bootstrap values "
            "below 1000 are generally not recommended."
        )

elif TREE_METHOD == "fasttree":
    TREE_RULES = "rules/fasttree.smk"

    print(
        "INFO: Building MLSA tree with FastTree."
    )

    if BOOTSTRAP is not None:
        print(
            "WARNING: tree.bootstrap is ignored when "
            "using FastTree."
        )

# Definitions
gff3extract = "workflow/scripts/gff3-extract-cds.pl"
gff3filter = "workflow/scripts/gff3-filter-yaml.pl"
script_code = r'if (/>([^\|]+)\|(\S+)/) { $h{$1}->{$2}++}; END{for my $a (sort keys %h) { for (keys %{$h{$a}}) {print "$a\t$_\t" . $h{$a}->{$_} . "\n"}}}'
sp_perl = r's/\ /_/g; s/^(\S+)\t/$1\t$1_/; print'
parition_regex=r's/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;'
autoconcatenate_regex=r'^>([^\|]*)'