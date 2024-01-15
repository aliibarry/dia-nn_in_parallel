# Parallelization of DIA-NN

_with input from Feng Xian_

DIA-NN parallelization through a 5-part analysis protocol. Based on discussions in https://github.com/bigbio/quantms/issues/164.

Part 1 : generate a spectral library based on FASTA. Only needs to be run once per FASTA combination
Part 2 : initial quantification step, runs in parellel.
Part 3 : generate an empirical spectral library, based on quantification files in part 2
Part 4 : second pass quantification; requires flag inputs from part 3 for mass-acc, etc. Currently manual.
Part 5 : generate final report

