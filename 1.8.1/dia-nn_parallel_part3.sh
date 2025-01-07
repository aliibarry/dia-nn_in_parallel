#!/bin/bash
#SBATCH -J p3_test_short
#SBATCH -N 1
#SBATCH --cpus-per-task=96
#SBATCH --partition=zen3_0512 #skylake_0096
#SBATCH --qos=zen3_0512 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-00:10:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

# adjust directories as needed
LIB="timsTOF/libs"
INPUT="timsTOF/2023/334_samples"
OUT="mb_ms_longitudinal"

####################################
# automatically set locations to match other parts

PART2="$OUT/part2"
PART4="$OUT/part4"

FILES=("$INPUT"/*.d)
OUTPUT_FILES=("$OUT/part2"/*.quant)
####################################

#step3 Assemble an empirical .tsv spectral library from the .quant files. need --rt-profiling and --use-quant.
COMMON_PARAMS="--lib $LIB/lib.predicted.speclib \
	--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
        --min-pr-mz 400 --max-pr-mz 1250 --min-fr-mz 100 --max-fr-mz 1700 \
        --threads 96 \
        --out-lib $OUT/empirical_library.tsv \
        --missed-cleavages 2 --min-pep-len 7 --max-pep-len 50 \
        --min-pr-charge 2 --max-pr-charge 4 --var-mods 2 --verbose 3 \
        --min-corr 2.0 --corr-diff 1.0
	--rt-profiling \
        --temp $PART2 \
        --use-quant --quick-mass-acc \
        --individual-mass-acc --individual-windows --gen-spec-lib"


#PART2_PARAMS="--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
#        --lib $LIB/lib.predicted.speclib \
#        --min-pr-mz 400 --max-pr-mz 1250 --min-fr-mz 100 --max-fr-mz 1700 \
#        --threads 32 \
#        --missed-cleavages 2 --min-pep-len 7 --max-pep-len 50 \
#        --min-pr-charge 2 --max-pr-charge 4 --var-mods 2 --verbose 3 \
#        --individual-windows \
#        --temp $PART2 \
#        --min-corr 2.0 --corr-diff 1.0 \
#        --quick-mass-acc \
#        --individual-mass-acc \
#        --time-corr-only"

# Construct --f options
F_OPTIONS=""
for FILE_PATH in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH" .d)
    F_OPTIONS+=" --f $FILE_PATH"
done

# Run the next command
./bin/diann-1.8.1 $COMMON_PARAMS $F_OPTIONS


