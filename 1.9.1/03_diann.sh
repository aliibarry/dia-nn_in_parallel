#!/bin/bash
#SBATCH -J Protegi-part3
#SBATCH -N 1
#SBATCH --partition=zen3_1024 #skylake_0096
#SBATCH --qos=zen3_1024 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-02:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

cd /gpfs/data/fs72233/barrya/ #have to be in data, use relative paths from there

INPUT="timsTOF/2024/Protegi-1/Data"
OUT="timsTOF/2024/Protegi-1/out"
LIB="/data/timsTOF/2024/Protegi-1"

echo "DIANN part 3, Lib."

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

#----------------------------------------------------------------

PART2_PARAMS="--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
        --lib $LIB/out.predicted.speclib \
        --min-pr-mz 350 --max-pr-mz 1150 --min-fr-mz 100 --max-fr-mz 1700 \
        --threads 32 --verbose 3 --pg-level 1 \
        --missed-cleavages 1 --min-pep-len 7 --max-pep-len 50 \
        --min-pr-charge 2 --max-pr-charge 4 \
	--var-mods 2 --peptidoforms \
	--var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n \
        --individual-windows \
        --temp $PART2 \
        --min-corr 2.0 --corr-diff 1.0 --time-corr-only \
        --quick-mass-acc \
        --individual-mass-acc"

COMMON_PARAMS="--lib $LIB/out.predicted.speclib \
	--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
        --min-pr-mz 350 --max-pr-mz 1150 --min-fr-mz 100 --max-fr-mz 1700 \
        --threads 96 \
        --out-lib $LIB/empirical_library.tsv \
        --missed-cleavages 1 --min-pep-len 7 --max-pep-len 50 \
        --min-pr-charge 2 --max-pr-charge 4 --var-mods 2 --verbose 3 \
        --min-corr 2.0 --corr-diff 1.0 \
	--rt-profiling \
        --temp $PART2 \
        --use-quant --quick-mass-acc --peptidoforms \
        --individual-mass-acc --individual-windows --gen-spec-lib"

singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux \
		$COMMON_PARAMS $F_OPTIONS

# --------------------------------------------------------------

