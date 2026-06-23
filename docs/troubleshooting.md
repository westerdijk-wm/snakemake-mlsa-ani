# Troubleshooting

This page lists common issues encountered when running snakemake-MLSA-ANI, along with possible causes and solutions.

If an error is not covered here, check the relevant log file in `logs/` first, and the Snakemake execution log in `.snakemake/log/` for the full error trace and command that failed.

## General debugging

- **Check `logs/`**: each rule writes its own log file (e.g. `logs/quast.log`, `logs/iqtree/iqtree.log`, `logs/ANI/skani.log`). These contain the stdout/stderr of the underlying tool and are usually the fastest way to identify the root cause.
- **Check `.snakemake/log/`**: Snakemake writes a timestamped log for every invocation, including the full shell command, working directory, and Python traceback for any internal errors (e.g. config validation, wildcard resolution).
- **Dry run first**: use `snakemake -n` to check that the DAG builds correctly before launching a full run, especially after changing `config.yaml`.
- **Re-run with `-p` and `--verbose`**: add `--printshellcmds (-p)` and `--verbose` to see exactly which commands are executed.

## Configuration errors

### `Invalid ani_method '...'`

The value of `ani_method` in `config.yaml` is not one of `skani`, `fastani`, `pyani`, or `none`. Check for typos and correct casing is not required (the value is lowercased automatically), but the spelling must match.

### `ERROR: Bootstrap replicates below ... not allowed`

`tree.bootstrap` is set below the minimum required for the selected `tree.method` (100 for IQ-TREE, 1 for RAxML). Increase the value in `config.yaml`.

### Gene not found / pipeline fails at `align` or `concat`

Check that every entry in `config["genes"]` exactly matches a `gene` field in the `db/ref-genes.fas` headers (`>{strain}|{gene}`). Gene names are case-sensitive and must match exactly — see [Configuration](configuration.md).

## Reference gene database errors

### `QC/ref_genes.validated` reports an error instead of `OK`

This indicates a problem with `db/ref-genes.fas`, most commonly:

- A header does not follow the `>{strain}|{gene} {optional description}` format (missing `|`).
- Duplicate `strain|gene` combinations exist in the file.

Inspect `logs/ref_genes_validation.log` and `QC/ref_genes.validated` for details on which header(s) caused the issue, then fix `db/ref-genes.fas` and re-run.

## Genome QC errors

### All / most genomes fail gene QC (empty `QC/genome-list-pass.txt`)

This usually means:

- The reference genes in `db/ref-genes.fas` are too divergent from your input genomes (low similarity hits filtered out by the 70% similarity threshold).
- Genome assemblies are highly fragmented, causing genes to be classified as `FRAGMENTED`.

Check `QC/gene-qc-detail.tsv` and `QC/gene-qc-summary.tsv` to see which loci/genomes are failing and why, and consider using more closely related reference sequences or reviewing assembly quality via `QC/quast/report.pdf`.

### `MISSING` genes for a genome that should contain the gene

Check the corresponding `logs/minimap/{sample}.log` and `logs/sam_realign/{sample}.log` for mapping issues. This can occur if the genome assembly is incomplete at that locus, or if the reference sequence for that gene is poor quality.

### A locus is incorrectly marked `DUPLICATED` for many/all genomes

If `QC/gene-qc-detail.tsv` shows `Status=DUPLICATED` for the same gene across most or all genomes, with the two hits located on **different contigs/chromosomes**, this usually indicates that `db/ref-genes.fas` contains **two reference sequences for the same gene name that are actually different (paralogous) genes** — e.g. two β-tubulin paralogs both labeled `tubA` from different source strains.

Each genome genuinely contains both paralogous loci, so each correctly produces two hits — one per paralog — both labeled with the same `gene` name from `ref-genes.fas`. `genes-qc.py` then counts these as 2 copies of the same gene and flags the sample as `DUPLICATED`, even though no real duplication occurred.

**How to check**: inspect `genes/map-pool/map-pool.fas` for the affected `{sample}|{gene}` entries. If the two hits:

- are on different contigs/chromosomes, and
- have substantially different lengths, and
- each match a *different* strain's reference sequence for that gene (see the `ref:` field in the header)

...this points to a reference database labeling issue rather than true gene duplication.

**Fix**: review the reference sequences for that gene in `db/ref-genes.fas`. If two strains' sequences for the "same" gene name are actually different paralogs (e.g. `tubA` vs `tubB`), remove or correctly rename the mismatched entry so that `db/ref-genes.fas` contains only true orthologs under each gene name. Re-run `validate_ref_genes` and the affected samples after fixing the database.


## Public genome download issues

### Download fails or produces an empty/incorrect `public_genomes/{accession}.fna`

- Verify the accession in `db/public_genomes.txt` is a valid, currently available NCBI assembly accession (`GCA_` or `GCF_` prefix).
- Confirm internet access is available from the execution environment (e.g. compute nodes on a cluster may lack outbound internet access).
- Check `logs/` for the corresponding download rule for the `datasets`/`unzip` error message.

### Re-running fails because `public_genomes/{accession}/` already exists

If a previous download was interrupted, a leftover (possibly empty) `public_genomes/{accession}/` directory or partial `.zip` file can cause the download rule to fail or behave unexpectedly on re-run. Manually remove the leftover accession folder and any `{accession}.zip` file from `public_genomes/` before re-running.

## Phylogenetic inference issues

### Re-running IQ-TREE or RAxML fails because output files already exist

Both IQ-TREE and RAxML refuse to overwrite their own output files (`phylogenetics/iqtree/` or `phylogenetics/raxml/`) if a previous run left files behind, even if Snakemake wants to re-trigger the rule (e.g. after a config change).

**Workaround**: manually delete the relevant method's output directory (`phylogenetics/iqtree/` or `phylogenetics/raxml/`) before re-running.

### Switching `tree.method` between runs

Changing `tree.method` in `config.yaml` does not automatically remove output from a previously used method. Old `phylogenetics/{method}/` directories may remain on disk even though they are no longer part of the active DAG. This does not affect the new run, but can be removed manually to save space.

## ANI issues

### `ANI/.../*.pdf` not generated

Confirm `ani_method` is not set to `none` in `config.yaml` — when set to `none`, no ANI rules are included in the workflow and no ANI output is produced.

### Few/no genomes in the ANI matrix

ANI analysis only uses genomes listed in `QC/genome-list-pass.txt`. If many genomes failed gene QC, they will be absent from the ANI results. See [Genome QC errors](#genome-qc-errors) above.

## Getting further help

If you encounter an issue not listed here:

1. Check the rule-specific log in `logs/`.
2. Check `.snakemake/log/` for the full Snakemake execution trace.
3. Open a GitHub issue with the relevant log excerpts and your `config.yaml`.