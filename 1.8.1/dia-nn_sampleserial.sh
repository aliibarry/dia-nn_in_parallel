#!/bin/bash
#SBATCH -J diann_tier2_serial
#SBATCH -N 1
#SBATCH --partition=zen3_0512 #skylake_0096
#SBATCH --qos=zen3_0512 #skylake_0096 #skylake_0096_devel
#SBATCH --time=0-72:00:00 #D-HH:MM:SS
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=allison.barry@univie.ac.at
#SBATCH --account=p72233

module purge

mkdir "diann_out/tier2"

#-rwxr-xr-x 1 barrya p72233  24M May 26  2023 timsTOF/2024/Combined_proteins_48970.fasta
#-rwxr-xr-x 1 barrya p72233 897K Jul 19  2023 timsTOF/2024/Ligilactobacillus-murinus_DSM_14221_1971_proteome.fasta
#-rwxr-xr-x 1 barrya p72233  12M Apr 27  2023 timsTOF/2024/Mouse_uniprot-proteome_UP000000589_2023.04.27.fasta
#-rwxr-xr-x 1 barrya p72233 1.4M Jul 19  2023 timsTOF/2024/SalinibacterRuber_UP000008674_2023_07_19.fasta

./bin/diann-1.8.1 --dir timsTOF/2024/tier2 \
	--lib timsTOF/2024/*.speclib \
	--fasta timsTOF/2024/Combined_proteins_48970.fasta \
	--fasta timsTOF/2024/Ligilactobacillus-murinus_DSM_14221_1971_proteome.fasta \
	--fasta timsTOF/2024/Mouse_uniprot-proteome_UP000000589_2023.04.27.fasta \
	--fasta timsTOF/2024/SalinibacterRuber_UP000008674_2023_07_19.fasta \
	--threads 128 --verbose 1 --qvalue 0.01 --matrices --reannotate \
	--gen-spec-lib --out-lib diann_out/tier2/report-lib.tsv \
	--out diann_out/tier2/report.tsv \
	--cut K*,R* --missed-cleavages 1 --min-pep-len 7 --max-pep-len 30 \
	--min-pr-mz 350 --max-pr-mz 800 --min-pr-charge 2 --max-pr-charge 4 \
	--unimod4 --var-mods 2 --var-mod UniMod:35,15.994915,M --var-mod UniMod:1,42.010565,*n \
	--monitor-mod UniMod:1 --var-mod SILAC_Lys,8.014199,K --var-mod SILAC_Arg,10.0082699,R \
	--reanalyse --rt-profiling --pg-level 1


