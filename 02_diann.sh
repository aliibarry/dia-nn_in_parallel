#!/bin/bash
#SBATCH -J Protegi-Quant1_continue
#SBATCH -N 1
#SBATCH --partition=zen3_1024 #skylake_0096
#SBATCH --qos=zen3_1024 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-72:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

cd /gpfs/data/fs72233/barrya/ #have to be in data, use relative paths from there

INPUT="timsTOF/2024/Protegi-1/Data"
OUT="timsTOF/2024/Protegi-1/out"
LIB="/data/timsTOF/2024/Protegi-1"

echo "DIANN part 2. Round 1 quantification."

module purge
module load singularity/3.8.7-gcc-12.2.0-h4t6dps

#---------------------------------------------------------------

echo "$INPUT"
mkdir "$OUT/part2"
mkdir "$OUT/part4"

PART2="/data/$OUT/part2"
PART4="/data/$OUT/part4"
FILES=("$INPUT"/*.d)

F_OPTIONS=""
for FILE_PATH in "${FILES[@]}"; do
    FILENAME=$(basename "$FILE_PATH" .d)
    F_OPTIONS+=" --f $FILE_PATH"
done

function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}

#----------------------------------------------------------------

PART2_PARAMS="--cut K*,R* --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n --monitor-mod UniMod:1 \
        --lib $LIB/out.predicted.speclib --use-quant \
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

### step2 - analysing each run separately with the in silico library generated in step 1, generate quant files

for FILE in "${FILES[@]}"; do
    BASENAME_FILE=$(basename "$FILE" .d)

    # Check if the output file already exists (partial match)
    if ! ls "$PART2" | grep -q "$BASENAME_FILE"; then
        singularity exec --env LANG=C.UTF-8,LC_ALL=C.UTF-8 -B ${PWD}:/data /gpfs/data/fs72233/barrya/bin/diann-1.9.1.sif diann-linux \
		$PART2_PARAMS --f "/data/$FILE" --out "/data/$OUT/step2-$(basename "$FILE" .d)" &
        pwait 4
    else
        echo "Skipping $FILE as an output file with a matching string already exists in $PART2"
    fi
done

wait

# --------------------------------------------------------------

