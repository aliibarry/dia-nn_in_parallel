#!/bin/bash
#SBATCH -J diann_fcs
#SBATCH -N 1
#SBATCH --partition=zen3_0512 #cascadelake_0384 #skylake_0096
#SBATCH --qos=zen3_0512 #cascadelake_0384 #skylake_0096
#SBATCH --time=0-48:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

##############################################
module purge

function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}
###############################################

# set working directories 

mkdir "mb_ms_longitudinal"

LIB="timsTOF/libs/"
INPUT="/gpfs/data/fs72233/barrya/timsTOF/2023/334_samples/fecespool"
#INPUT="/gpfs/data/fs72233/barrya/timsTOF/2023/334_samples/2023/20230417"
OUT="mb_ms_longitudinal"

echo "$INPUT"

###############################################

mkdir "$OUT/part2"
mkdir "$OUT/part4"

PART2="$OUT/part2"
PART4="$OUT/part4"
FILES=("$INPUT"/*.d)

F_OPTIONS=""
for FILE_PATH in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH" .d)
    F_OPTIONS+=" --f $FILE_PATH"
done

################################################

# --min-corr 2.0 --corr-diff 1.0 --time-corr-only \ for high speed, low RAM mode (re. Vadim recommendation) 

PART2_PARAMS="--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
        --lib $LIB/lib.predicted.speclib \
        --min-pr-mz 400 --max-pr-mz 1250 --min-fr-mz 100 --max-fr-mz 1700 \
        --threads 32 \
        --missed-cleavages 2 --min-pep-len 7 --max-pep-len 50 \
        --min-pr-charge 2 --max-pr-charge 4 --var-mods 2 --verbose 3 \
        --individual-windows \
        --temp $PART2 \
        --min-corr 2.0 --corr-diff 1.0 --time-corr-only \ 
        --quick-mass-acc \
        --individual-mass-acc"

### step2 - analysing each run separately with the in silico library generated in step 1, generate quant files

for FILE in "${FILES[@]}"; do
    BASENAME_FILE=$(basename "$FILE" .d)
    
    # Check if the output file already exists (partial match)
    if ! ls "$PART2" | grep -q "$BASENAME_FILE"; then
        ./bin/diann-1.8.1 $PART2_PARAMS --f "$FILE" --out "$OUT/step2-$(basename "$FILE" .d)" &
        pwait 12
    else
        echo "Skipping $FILE as an output file with a matching string already exists in $PART2"
    fi
done

wait
