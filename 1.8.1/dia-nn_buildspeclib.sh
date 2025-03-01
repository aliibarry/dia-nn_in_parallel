#!/bin/bash
#SBATCH -J speclib
#SBATCH -N 1
#SBATCH --partition=skylake_0096
#SBATCH --qos=skylake_0096 #skylake_0096_devel
#SBATCH --time=0-12:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

mkdir "timsTOF/libs/hg-yeast"
OUT="timsTOF/libs/hg-yeast"

# for mouse microbiome
# --fasta timsTOF/fasta/Combined_proteins_48970.fasta \
# --fasta timsTOF/fasta/Mouse_uniprot-proteome_UP000000589_2023.04.27.fasta \

# example from human-yeast ground truth
# step1 - generate .speclib based off fasta, no experimental ms data files requires
./bin/diann-1.8.1 --gen-spec-lib --predictor --fasta-search \
	--fasta timsTOF/fasta/20231212_uniprot_hg_559292.fasta \
	--fasta timsTOF/fasta/20231212_uniprot_yeast_9606.fasta \
	--cut K*,R* --missed-cleavages 2 \
	--min-pep-len 7 --max-pep-len 50 --min-pr-mz 400 --max-pr-mz 1250 \
	--min-pr-charge 2 --max-pr-charge 4 --var-mods 2 \
	--var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
	--out $OUT

