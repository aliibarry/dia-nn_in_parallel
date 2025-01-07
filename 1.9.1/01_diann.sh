#!/bin/bash
#SBATCH -J Protegi-SpecLib
#SBATCH -N 1
#SBATCH --partition=zen3_0512 #skylake_0096
#SBATCH --qos=zen3_0512 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-06:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

#        --dir /data/timsTOF/2024/Protegi-1/DATA \

cd /gpfs/data/fs72233/barrya/ #have to be in data, use relative paths from there
mkdir "timsTOF/2024/Protegi-1/out"
OUT="/data/timsTOF/2024/Protegi-1/out"

echo "DIANN part 1. Generate Spec Lib."

module load singularity/3.8.7-gcc-12.2.0-h4t6dps

# --------------------------------------------------------------

singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux \
	--gen-spec-lib --predictor --fasta-search \
	--threads 128 --verbose 1 \
	--out $OUT \
	--out-lib $OUT \
	--fasta /data/timsTOF/2024/Protegi-1/FASTA/Classical-DB_Fractioncombined_137511.fasta \
	--fasta /data/timsTOF/2024/Protegi-1/FASTA/Human_uniprot-proteome_UP000005640_validated.fasta \
	--min-fr-mz 100 --max-fr-mz 1700 --met-excision --min-pep-len 7 --max-pep-len 50 \
	--min-pr-mz 350 --max-pr-mz 1150 --min-pr-charge 2 --max-pr-charge 4 \
	--cut K*,R* --missed-cleavages 1 --unimod4 --var-mods 2 \
	--var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n \
	--peptidoforms --reanalyse --relaxed-prot-inf --rt-profiling --pg-level 1

