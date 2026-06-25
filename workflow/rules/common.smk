from pathlib import Path

GENOME_EXTS = [".fna", ".fasta", ".fas", ".fa"]

PUBLIC_GENOMES_FILE = config.get("public_genomes", None)

if PUBLIC_GENOMES_FILE:
    with open(PUBLIC_GENOMES_FILE) as f:
        PUBLIC_GENOMES = [
            line.strip() for line in f if line.strip() and not line.startswith("#")
        ]
else:
    PUBLIC_GENOMES = []

PUBLIC_GENOME_TARGETS = [f"public_genomes/{acc}.fna" for acc in PUBLIC_GENOMES]

genomes_dir = Path("genomes")
genomes_dir.mkdir(exist_ok=True)

LOCAL_GENOMES = sorted(
    str(p) for p in genomes_dir.iterdir() if p.suffix.lower() in GENOME_EXTS
)

GENOMES = LOCAL_GENOMES + PUBLIC_GENOME_TARGETS

LOCAL_SAMPLES = {
    p.stem for p in Path("genomes").iterdir() if p.suffix.lower() in GENOME_EXTS
}

SAMPLES = sorted(LOCAL_SAMPLES | set(PUBLIC_GENOMES))


def genome_file(wildcards):

    for ext in GENOME_EXTS:

        local = Path("genomes") / f"{wildcards.sample}{ext}"

        if local.exists():
            return str(local)

    if wildcards.sample in PUBLIC_GENOMES:
        return f"public_genomes/{wildcards.sample}.fna"

    raise FileNotFoundError(f"No genome found for sample '{wildcards.sample}'")


# ANI helper functions and variables
ANI_METHOD = config.get("ani_method", "none").lower()

VALID_ANI_METHODS = {"none", "fastani", "pyani", "skani"}

if ANI_METHOD not in VALID_ANI_METHODS:
    raise ValueError(f"Invalid ani_method '{ANI_METHOD}'.")

ANI_RULES = []
ANI_TARGETS = []

if ANI_METHOD == "fastani":

    ANI_RULES.append("rules/fastani.smk")

    ANI_TARGETS.extend(["ANI/fastani/fastani_table.tsv", "ANI/fastani/fastani.pdf"])

elif ANI_METHOD == "pyani":

    ANI_RULES.append("rules/pyani.smk")

    ANI_TARGETS.extend(
        ["ANI/pyani/pyani_percentage_identity_plot.pdf", "ANI/pyani/pyani_cov_plot.pdf"]
    )

elif ANI_METHOD == "skani":

    ANI_RULES.append("rules/skani.smk")

    ANI_TARGETS.extend(["ANI/skani/skani_table.tsv", "ANI/skani/skani.pdf"])

elif ANI_METHOD == "none":

    print("INFO: ANI analysis is disabled. No ANI rules will be included.")


# ANI plot input help
ANI_PLOT_INPUT = {}  # maps output pdf -> {tree, ani}

if ANI_METHOD == "fastani":
    ANI_PLOT_INPUT["ANI/fastani/fastani.pdf"] = {
        "tree": "phylogenetics/MLSA.nwk",
        "ani": "ANI/fastani/fastani_table.tsv",
    }
elif ANI_METHOD == "skani":
    ANI_PLOT_INPUT["ANI/skani/skani.pdf"] = {
        "tree": "phylogenetics/MLSA.nwk",
        "ani": "ANI/skani/skani_table.tsv",
    }
elif ANI_METHOD == "pyani":
    ANI_PLOT_INPUT["ANI/pyani/pyani_percentage_identity_plot.pdf"] = {
        "tree": "ANI/pyani/pyani_dist.nwk",
        "ani": "ANI/pyani/ANIm_percentage_identity.tab",
    }
    ANI_PLOT_INPUT["ANI/pyani/pyani_cov_plot.pdf"] = {
        "tree": "ANI/pyani/pyani_dist.nwk",
        "ani": "ANI/pyani/ANIm_alignment_coverage.tab",
    }

ANI_TABLE_INPUT = {}  # maps output tsv -> input pairs tsv

if ANI_METHOD == "fastani":
    ANI_TABLE_INPUT["ANI/fastani/fastani_table.tsv"] = "ANI/fastani/fastani_pairs.tsv"
elif ANI_METHOD == "skani":
    ANI_TABLE_INPUT["ANI/skani/skani_table.tsv"] = "ANI/skani/skani_pairs.tsv"

# Tree helper functions and variables
VALID_TREE_METHODS = {"raxml", "iqtree", "fasttree"}

TREE_RULES = None
TREE_TARGETS = ["phylogenetics/MLSA.nwk"]

TREE_CFG = config.get("tree", {})
TREE_METHOD = TREE_CFG.get("method", "iqtree").lower()
BOOTSTRAP = TREE_CFG.get("bootstrap")

if TREE_METHOD == "raxml":
    TREE_RULES = "rules/raxml.smk"

    print(
        f"INFO: Building MLSA tree with RAxML " f"({BOOTSTRAP} bootstrap replicates)."
    )

    if BOOTSTRAP < 1:
        print("ERROR: Bootstrap replicates below 1 not allowed for RAxML.")

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
        print("ERROR: Bootstrap replicates below 100 not allowed for IQ-TREE.")

    elif BOOTSTRAP < 1000:
        print(
            "WARNING: IQ-TREE ultrafast bootstrap values "
            "below 1000 are generally not recommended."
        )

elif TREE_METHOD == "fasttree":
    TREE_RULES = "rules/fasttree.smk"

    print("INFO: Building MLSA tree with FastTree.")

    if BOOTSTRAP is not None:
        print("WARNING: tree.bootstrap is ignored when " "using FastTree.")

# Define tree output
TREE_OUTPUT = None
if TREE_METHOD == "raxml":
    TREE_RULES = "rules/raxml.smk"
    TREE_OUTPUT = "phylogenetics/raxml/RAxML_bipartitions.analysis-ML-bs"
elif TREE_METHOD == "iqtree":
    TREE_RULES = "rules/iqtree.smk"
    TREE_OUTPUT = "phylogenetics/iqtree/iqtree.treefile"
elif TREE_METHOD == "fasttree":
    TREE_RULES = "rules/fasttree.smk"
    TREE_OUTPUT = "phylogenetics/fasttree/fasttree.nwk"

# Definitions
parition_regex = r"s/^\d+\t/DNA, /; s/\t/=/; s/\t/-/; print;"
autoconcatenate_regex = r"^>([^\|]*)"
