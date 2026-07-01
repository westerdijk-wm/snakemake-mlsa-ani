# Troubleshooting

This page lists potential issues when running snakemake-MLSA-ANI,
along with possible causes and solutions.

If an error is not covered here, check the relevant log file in `logs/` first,
and the Snakemake execution log in `.snakemake/log/` for the full error trace
and command that failed.

## General debugging

- **Check `logs/`**: each rule writes its own log file (e.g.
  `logs/QUAST/{sample}.log`, `logs/iqtree/iqtree.log`,
  `logs/ANI/skani.log`). These contain the stdout/stderr of the underlying
  tool and are usually the fastest way to identify the root cause.
- **Check `.snakemake/log/`**: Snakemake writes a timestamped log for every
  invocation, including the full shell command and Python traceback for any
  internal errors (e.g. config validation, wildcard resolution).
- **Dry run first**: use `snakemake -n` to verify the DAG builds correctly
  before launching a full run, especially after changing `config.yaml`.
- **Inspect executed commands**: add `--printshellcmds` (`-p`) to see exactly
  which shell commands are run.


## Configuration errors

### `Invalid ani_method '...'`

The value of `ani_method` in `config.yaml` is not one of `skani`, `fastani`,
`pyani`, or `none`. Check for typos; the value is lowercased automatically but
the spelling must match exactly.

### `ERROR: Bootstrap replicates below ... not allowed`

`tree.bootstrap` is set below the minimum required for the selected
`tree.method` (100 for IQ-TREE, 1 for RAxML). Increase the value in
`config.yaml`.

### `WARNING: IQ-TREE ultrafast bootstrap values below 1000 are generally not recommended`

`tree.bootstrap` is set between 100 and 999 for IQ-TREE. The run will
proceed, but ultrafast bootstrap support values may be less reliable. Set
`bootstrap: 1000` or higher for publishable results.

### Gene not found / pipeline fails at `align` or `concat`

Every entry in `genes` in `config.yaml` must exactly match a gene name in the
`>{strain}|{gene}` headers of `config/ref-genes.fas`. Gene names are
case-sensitive. Check for typos and rerun `validate_ref_genes` after fixing
the database.


## Reference gene database errors

### `results/QC/ref_genes.validated` reports an error

This indicates a problem with `config/ref-genes.fas`, most commonly:

- A header does not follow the `>{strain}|{gene}` format (missing `|` or
  extra spaces around it).
- Duplicate `strain|gene` combinations exist in the file.

Inspect `logs/ref_genes_validation.log` for details on which header(s) caused
the issue, fix `config/ref-genes.fas`, and re-run.

## Genome QC errors

### All or most genomes fail gene QC

`results/QC/genome-list-pass.txt` is empty or contains very few entries. This
usually means:

- The reference genes in `config/ref-genes.fas` are too divergent from the
  input genomes (hits filtered out by the 70% similarity threshold in
  `sam_extract_hit_seq`).
- Genome assemblies are highly fragmented, causing loci to be classified as
  fragmented (coverage < 0.95 or length ratio < 0.90).

Check `results/QC/gene-qc-detail.tsv` to see which loci and samples are
failing and why. Consider using more closely related reference sequences or
reviewing assembly quality via `results/QC/quast/`.

### `MISSING` gene for a genome that should contain it

Check `logs/minimap/{sample}_minimap2.log` and
`logs/sam_realign/{sample}.log` for mapping issues. This can occur if the
assembly is incomplete at that locus or if the reference sequence for that
gene is poor quality.

### A locus is marked `DUPLICATED` across many or all genomes

If `results/QC/gene-qc-detail.tsv` shows two copies of the same gene for most
genomes, typically on different contigs with different lengths, this usually
indicates that `config/ref-genes.fas` contains **two reference sequences with
the same gene name that are actually different paralogs** — e.g. two β-tubulin
paralogs both labeled `tubA` from different source strains.

Each genome genuinely contains both paralogs, so the workflow correctly finds
two hits per genome and flags them as duplicated.

**How to check**: inspect `results/genes/map-pool/map-pool.fas` for the
affected `{sample}|{gene}` entries. If the two hits are on different
contigs, have substantially different lengths, and each match a different
strain's reference sequence (visible in the `ref:` field of the FASTA header),
this points to a reference database labeling issue.

**Fix**: review `config/ref-genes.fas` for the affected gene. If two entries
with the same gene name represent different paralogs, remove or rename the
mismatched entry so only true orthologs share a gene name. Re-run from
`validate_ref_genes` after fixing the database.


## Public genome download errors

### Download fails or produces an empty FASTA

- Verify the accession in `config/public_genomes.txt` is a valid, currently
  available NCBI assembly accession (`GCA_` or `GCF_` prefix).
- Confirm internet access is available from the execution environment (compute
  nodes on a cluster may lack outbound internet access).
- Check `logs/datasets/{sample}.log` for the `datasets` or `unzip` error.

### Re-running fails because a partial download directory already exists

If a previous download was interrupted, a leftover partial directory or `.zip`
file under `resources/datasets/` can cause the download rule to fail on
re-run. Remove the relevant entries manually:

```bash
rm -rf resources/datasets/{sample} resources/datasets/{sample}.zip
rm -f resources/public_genomes/{sample}.fna
```

Then re-run Snakemake.


## Phylogenetic inference errors

### RAxML refuses to run because output files already exist

RAxML refusse to overwrite existing output files. If Snakemake
re-triggers either rule (e.g. after a config change) and previous output
remains, the rule will fail.

**Fix**: delete the relevant output directory before re-running:

```bash
rm -rf results/phylogenetics/raxml/
```

### Switching `tree.method` between runs

Changing `tree.method` in `config.yaml` does not remove output from a
previously used method. Old output directories may remain on disk but will not
affect the new run. Remove them manually if disk space is a concern.


## ANI errors

### No ANI output generated

Confirm `ani_method` is not set to `none` in `config.yaml`. When set to
`none`, no ANI rules are included in the workflow.

### Few or no genomes appear in the ANI matrix

ANI analysis only includes genomes listed in `results/QC/genome-list-pass.txt`.
If many genomes failed gene QC, they will be absent from the ANI results. See
[Genome QC errors](#genome-qc-errors) above.

### ANI matrix contains missing values

If `logs/ANI/{method}/ani2table.log` reports missing values in the matrix,
some pairwise comparisons may not have been computed. For skani and FastANI
this can occur when genome sequences are too short or too divergent for a
reliable sketch-based estimate. Check the raw pairs file
(`results/ANI/{method}/{method}_pairs.tsv`) to identify which pairs are absent.



## Getting further help

1. Check the rule-specific log in `logs/`.
2. Check `.snakemake/log/` for the full Snakemake execution trace.
3. Open a GitHub issue with the relevant log excerpts and your `config.yaml`.