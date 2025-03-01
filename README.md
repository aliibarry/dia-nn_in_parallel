# Serial processing of DIA-NN
Example scripts available:  
1.8.1 `/1.8.1/dia-nn_sampleserial.sh`  
1.9.1 `/1.9.1/dia-nn_sampleserial_1.9.1.sh` run through singularity

# Parallelization of DIA-NN

_with input from Feng Xian_

For shorter jobs, samples can be processed in serial (`dia-nn_sampleserial.sh`). Run time depends on search space, can likely run 50-100 samples within 72 hr vsc timelimit.   

DIA-NN parallelization through a 5-part analysis protocol. Based on discussions in https://github.com/bigbio/quantms/issues/164.

Set output folder ($OUT). Part3 spec-lib and final results saved in main output folder. Quantification files saved in $PART2 or $PART4 subdirectories. 

```
PART2="$OUT/part2"
PART4="$OUT/part4"
```
Slurm output logs for part2 and part4 contain overlapping outputs due to parallelization. Part2 quantificant logs are therefore also generated independantly per sample to facilitate qc checks. 

### 1.8.1
For diann1.8.1, see scripts in `1.8.1`:  
Part 1 : `dia-nn_buildspeclib.sh`: generate a spectral library based on FASTA. Only needs to be run once per FASTA combination  
Part 2 : `dia-nn_parallel_part2.sh`: initial quantification step, runs in parallel.  
Part 3 : `dia-nn_parallel_part3.sh`: generate an empirical spectral library, based on quantification files in part 2  
Part 4 : `dia-nn_parallel_part4-5.sh`: second pass quantification; requires flag inputs from part 3 for mass-acc, etc. Currently manual.  
Part 5 : `dia-nn_parallel_part4-5.sh`: generate final report; can also run separately

### 1.9.1
For diann1.9.1, see scripts in `1.9.1` for example scripts adjusted for use with singularity. 

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
* `zen3_0512` is a standard vsc-5 node. Wait times ranged between 10 sec to 3 days for 72 hr jobs; single node. 512 GB RAM
* Test run on `zen3_1024` with `pwait 24` queue time can be faster than 0512, not always. 1 TB RAM
* Test run on `zen3_2048` with `pwait 48` queue time can be faster than 0512, not always. 2 TB RAM
    * Extremely slow per-sample timing, as CPU isn't increased on fat nodes. Overall processing time isn't faster running so many samples in parallel on a single node. 
* Full node details available at https://wiki.vsc.ac.at/doku.php?id=doku:vsc5_queue.
* Can split samples by names (eg. 78*, 79*) and run as separate jobs (eg. `"78*.d`) to get running across multiple nodes. Clunky but functional.

***

## Part 1 Spectral library

Generate a general spectral library based on FASTAs. Only need to run once, but can specify `--min-pr-mz XXX --max-pr-mz XXX` to match part 2. For reduced search spaces, can re-run with modified paramters as it will increase quantification speed due to smaller overall spectral library. Takes 6-24 hours, depending on the FASTAs providing + size of the search space (possibly longer, without providing an `--min-pr-mz XXX --max-pr-mz XXX`).

## Part 2 Quantification

```
FILES=("$INPUT"/*.d)

PART2_PARAMS = XXX # can change parameters as needed. They need to match identically to part 3

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
* Default `pwait 12`, can probably up to 15 for default config, and adjust higher depending on the node configuration
    * need about 25-30 GB RAM per sample, but on fat nodes # threads still important for speed.   
* Parameters need to be an identical to part 3 (including integer vs floats), otherwise it will re-run quantification step (but not in parallel).
* Unclear if all files need to be in the same repository; they were all moved to one folder during de-bugging process and not retested in their original folders.
* Longest processing step, parallelization here is key.
* `--min-corr 2.0 --corr-diff 1.0 --time-corr-only`: Low RAM & high speed mode, recommended by Vadim for parallelization
* for PTM add `--var-mod declaration` and `--monitor-mod`


## Part 3 Empirical spec lib

Based on the quantification files generted in part 2, `dia-nn_parallel_part3.sh` generates a new "empirical" spectral library to be used for the second pass quantification.

Notes
* If quantification files are being generated again, it is (very likely) because there is a mis-match with the parameters between part 2 & 3
* Job should only take ~10-15 min to run with pre-quantified files
* `--f` only required for naming purposes. Original files don't actually need to be accessible (according to Vadim, see github issue discussions above)
* Output log line for "Averaged recommended settings for this experiment: Mass accuracy = XXppm, MS1 accuracy = Xppm, Scan window = X" used for part 4 paramters

## Part 4 Second Quantification

Notes
* Quantification significantly shorter than part 2, not yet optimized for memory usage per node
* `--mass-acc XXX --mass-acc-ms1 XXX --window XXX`: requires manual input from part 3 log, see script for notes. Not currently automated
* MB run took ~3 hours with current set-up. Can probably be faster with parallelization tweaks.
* `--f` only required for naming purposes, see github issue discussions above

## Part 5 Report Generation
* Like Part 3, takes ~10-15 min.
* Report generation tweaked of `--pg-level 1` and `--verbose 1` to match dia-nn ui version
* `--q-value 0.01` specified here, unclear if UI default is also used here, so set explicitly
* `--f` only required for naming purposes, see github issue discussions above
* `--relaxed-prot-inf` is similar to the protein inference used in Fragpipe and can be added, but omitted here (feedback from FX to use default DIA-NN algorithm)

## Debugging
Sample errors, updated as they arise
* Excessively long run time per sample; check MS QC - is it worth omitting the file already?
* Exit Code 139, `segmentation fault`; check to ensure only DIA files are in the directory.
