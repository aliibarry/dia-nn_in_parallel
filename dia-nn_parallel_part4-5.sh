#!/bin/bash
#SBATCH -J diann
#SBATCH -N 1
#SBATCH --cpus-per-task=10
#SBATCH --partition=zen3_0512 #skylake_0096
#SBATCH --qos=zen3_0512 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-06:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

module load anaconda3/2022.05-gcc-12.2.0-oqiw76n
source activate $DATA/myenv

function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}

#module load openjdk/11.0.17_8-gcc-12.2.0-o2utqnb #updated java

LIB="timsTOF/libs"
INPUT="timsTOF/2023/334_samples"
OUT="mb_ms_longitudinal"

PART2="$OUT/part2"
PART4="$OUT/part4"

FILES=("$INPUT"/*.d)
OUTPUT_FILES=("$OUT/part2"/*.quant)

### need a better approach for setting --mass-acc et al. 

#step4 - second quantification using empirical library 
COMMON_PARAMS="--lib $OUT/empirical_library.tsv \
        --threads 10 --verbose 3 \
        --temp $PART4 \
        --mass-acc 12 --mass-acc-ms1 13 --window 12 \
        --no-ifs-removal \
        --no-main-report"

for FILE_PATH in "${FILES[@]}"; do
    ./bin/diann-1.8.1 $COMMON_PARAMS --f "$FILE_PATH" &
    pwait 12
done

wait

#part5
F_OPTIONS=""
for FILE_PATH in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH" .d)
    F_OPTIONS+=" --f $FILE_PATH"
done

#step5 - combine for outputs
./bin/diann-1.8.1 --lib $OUT/empirical_library.tsv \
	--fasta timsTOF/fasta/Combined_proteins_48970.fasta \
        --fasta timsTOF/fasta/Mouse_uniprot-proteome_UP000000589_2023.04.27.fasta \
       	$F_OPTIONS \
	--threads 2 --verbose 3 \
	--individual-windows --quick-mass-acc \
	--individual-mass-acc \
	--temp $PART4 \
       	--relaxed-prot-inf --pg-level 2 \
	--use-quant --matrices \
	--out $OUT/diann_report.tsv


