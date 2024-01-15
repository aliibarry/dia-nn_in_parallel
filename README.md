# Parallelization of DIA-NN

_with input from Feng Xian_

DIA-NN parallelization through a 5-part analysis protocol. Based on discussions in https://github.com/bigbio/quantms/issues/164.

Part 1 : `diann_buildspeclib.sh`: generate a spectral library based on FASTA. Only needs to be run once per FASTA combination  
Part 2 : `dia-nn_parallel_part2.sh`: initial quantification step, runs in parellel.  
Part 3 : generate an empirical spectral library, based on quantification files in part 2  
Part 4 : second pass quantification; requires flag inputs from part 3 for mass-acc, etc. Currently manual.  
Part 5 : generate final report  

Set output folder ($OUT). Part3 spec-lib and final results saved in main output folder. Quantification files saved in $PART2 or $PART4 subdirectories. 

```
PART2="$OUT/part2"
PART4="$OUT/part4"
```


***
## Memory allocation

Each sample is run through a separate DIA-NN instance for quantification steps. This requires the spectral library to be loaded for every sample, and is highly memory intensive. This appears to be the current limitation of the parallelization (with high memory nodes able to run more samples at once). 

To prevent memory allocation errors, `pwait` function used in quantification steps to limit number of samples being run at each step. Can either be added directly to a `.bashrc` or at the beginning of the script. Taken from https://stackoverflow.com/a/880864/9909326.
```
function pwait() {
    while [ $(jobs -p | wc -l) -ge $1 ]; do
        sleep 1
    done
}
```
Example: run 12 jobs at a time
```
for XXX
  script &
  pwait 12
end
```
Currently: 12 samples in parallel works for VSC-5 zen3_0512; 3-4 samples for VSC-4 standard nodes. 
* queue times for VSC-4 fat nodes were a few days (tried before christmas, likely shorter outside of peak usage times)
* `zen3_0512` is a standard vsc-5 node, other options available with more memory if needed. Wait times ranged between 10 sec to 3 days for 72 hr jobs; single node 
***

## Part 2 Quantification

```
FILES=("$INPUT"/*.d)

PART2_PARAMS = XXX # can change parameters as needed. There need to match identically to part 3

for FILE in "${FILES[@]}"; do
    BASENAME_FILE=$(basename "$FILE" .d) #extract basename for each mass spec `.d` file repository
    
    # Check if the output file already exists (partial match)
    if ! ls "$PART2" | grep -q "$BASENAME_FILE"; then #if the file is not found (ie, already analysed), run dia-nn with PART2_PARAMS
        ./bin/diann-1.8.1 $PART2_PARAMS --f "$FILE" --out "$OUT/step2-$(basename "$FILE" .d)" & 
        pwait 12 
    else
        echo "Skipping $FILE as an output file with a matching string already exists in $PART2"
    fi
done
```
Notes
* DIA-NN runs with individial output logs for each file (overall output file difficult to read due to parallelization)
* Will skip files that have already been processed (eg. if the job has timed out, and needs to be restarted)
* Default `pwait 12`, can adjust depending on the node configuration
* Parameters need to be an identical to part 3 (including integer vs floats), otherwise it will re-run quantification step (but not in parallel).
* Unclear if all files need to be in the same repository; they were all moved to one folder during de-bugging process and not retested in their original folders.



`diann_buildspeclib.sh`
