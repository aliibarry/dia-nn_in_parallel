#!/bin/bash
#SBATCH -J diann_denovo
#SBATCH -N 1
#SBATCH --cpus-per-task=128
#SBATCH --partition=zen3_2048 #zen3_0512 #skylake_0096
#SBATCH --qos=zen3_2048 #zen3_0512 #skylake_0096 #skylake_0096_devel
#SBATCH --time=72:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

# --------------------------------------------------------------

mkdir denovo/
OUT='/data/denovo/'

module load singularity/3.8.7-gcc-12.2.0-h4t6dps
cd /gpfs/data/fs72233/barrya/ #have to be in data, use relative paths from there

#        --min-corr 2.0 --corr-diff 1.0 --time-corr-only \

# --------------------------------------------------------------

singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux --gen-spec-lib --fasta-search --predictor \
	--dir /data/timsTOF/2023/20230502_Bruker_Ultra_data \
	--fasta /data/timsTOF/fasta/NCBI_retrived_sequences_80pident_158204Sequences.fasta \
	--fasta /data/timsTOF/fasta/Combined_fasta_53502Sequences_MGnify.fasta \
	--fasta /data/timsTOF/fasta/crap.fasta \
	--fasta /data/timsTOF/fasta/Mouse_uniprot-proteome_UP000000589_2023.04.27.fasta \
	--threads 128 --verbose 1 --qvalue 0.01 --matrices \
	--min-fr-mz 100 --max-fr-mz 1700 \
	--out $OUT/report.tsv \
	--out-lib $OUT/report-lib.tsv \
	--cut K*,R* --missed-cleavages 1 --min-pep-len 7 --max-pep-len 30 --peptidoforms \
	--min-pr-mz 400 --max-pr-mz 1000 --min-pr-charge 2 --max-pr-charge 4 \
	--var-mods 1 --unimod4 --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n \
	--monitor-mod UniMod:1 --rt-profiling --reanalyse --met-excision \
	--pg-level 1 --no-ifs-removal --peak-center

