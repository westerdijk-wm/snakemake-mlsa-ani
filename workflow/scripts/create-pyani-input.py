from pathlib import Path
import shutil

outdir = Path(snakemake.output[0])
outdir.mkdir(parents=True, exist_ok=True)

with open(snakemake.input.genomes) as f:
    for genome in map(str.strip, f):
        if not genome:
            continue

        src = Path(genome)
        dst = outdir / src.name

        shutil.copy2(src, dst)
