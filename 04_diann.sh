#!/bin/bash
#SBATCH -J Protigi-1_diann_p5
#SBATCH -N 1
#SBATCH --cpus-per-task=64
#SBATCH --partition=zen3_0512 #skylake_0096
#SBATCH --qos=zen3_0512_devel #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-00:10:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

cd /gpfs/data/fs72233/barrya/ #have to be in data, use relative paths from there

INPUT="timsTOF/2024/Protegi-1/Data"
OUT="timsTOF/2024/Protegi-1/out"
LIB="/data/timsTOF/2024/Protegi-1"

echo "DIANN part 5, Protigi-1."

module purge
module load singularity/3.8.7-gcc-12.2.0-h4t6dps

#---------------------------------------------------------------

echo "$INPUT"

PART2="/data/$OUT/part2"
PART4="/data/$OUT/part4"
FILES=("$INPUT"/*.d)
OUTPUT_FILES=("$OUT/part2"/*.quant)

F_OPTIONS=""
for FILE_PATH in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH" .d)
    F_OPTIONS+=" --f /data/$FILE_PATH"
done

function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}

#--------------------------------------------------------------

# from slurm-4598289.out 
# [1:32] Averaged recommended settings for this experiment: Mass accuracy = 11ppm, MS1 accuracy = 12ppm, Scan window = 14

# part4 - second quantification using empirical library 

COMMON_PARAMS="--lib $LIB/empirical_library.parquet \
        --threads 32 --verbose 3 \
        --temp $PART4 \
        --mass-acc 11 --mass-acc-ms1 12 --window 14 \
        --no-ifs-removal \
        --no-main-report"

#for FILE_PATH in "${FILES[@]}"; do
#    singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux \
#	    $COMMON_PARAMS --f "/data/$FILE_PATH" &
#    pwait 4
#done
#
#wait

#---------------------------------------------------------------

# part 5

singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux \
	--lib $LIB/empirical_library.parquet \
       	--fasta /data/timsTOF/2024/Protegi-1/FASTA/Classical-DB_Fractioncombined_137511.fasta \
        --fasta /data/timsTOF/2024/Protegi-1/FASTA/Human_uniprot-proteome_UP000005640_validated.fasta \
	$F_OPTIONS \
	--threads 16 --verbose 3 \
	--individual-windows --quick-mass-acc \
	--individual-mass-acc \
	--temp $PART4 \
       	--qvalue 0.01 --pg-level 1 \
	--use-quant \
	--out /data/$OUT/report.tsv
