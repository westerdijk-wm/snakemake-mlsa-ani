#!/usr/bin/env python3

import os
import shutil

data_path = "download/ncbi_dataset/data/"
ids = [f for f in os.listdir(data_path) if f.startswith('GC')]
# check that parent dirs are there
final_path = "download/renamed/"
for folder_path in [final_path, "genomes", "annotation"]:
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)

# Go through genome data and move to expected location
for id in ids:
    dest_path = final_path + id
    if not os.path.exists(dest_path):
        os.makedirs(dest_path)
    files = os.listdir(data_path + id)
    for file in files:
        if file.endswith('_genomic.fna'):
            shutil.move(f'{data_path}{id}/{file}', f'{dest_path}/{id}.fna')
    gff = "genomic.gff"
    if gff in files:
        shutil.move(f'{data_path}{id}/{gff}', f'{dest_path}/{id}.gff')
    else:
        print(f'WARNING: {id} has no annotation')

print('Done creating renamed files')