#!/bin/bash

if [ $# -ne 2 ]; then
    echo -e "error: Please specify a data folder as the first argument and an output file as the second argument."
    exit 1
fi

data_folder="$1"
output_file="$2"

if [ ! -d "$data_folder" ]; then
    echo -e "error: The folder $data_folder does not exist. Please specify a valid data folder."
    exit 1
fi

find "$data_folder" -type f \( -name "*.fastq.gz" -o -name "*.fasta" -o -name "*.gbff" \) | xargs -I {} basename {} | sed 's/\.[^.]*$//' | awk -F'_1|_2|.fastq' '{print $1}' | awk '!seen[$0]++' > "$output_file"

sed -i 's/$/\tNA\tNA\tNA\tNA/' "$output_file"

echo -e "\nusage: The list of the various input files has been successfully copied to the configuration file $output_file. Please specify in it, for the necessary files the genus, the species, the taxon and the path to a fasta of protein for annotation separated by a tab. If the information is not known, leave the instruction NA (not available).\nIf input files do not appear in the configuration file, please check that you have reads or assemblies with the extensions required by GDFF-annot (fastq.gz or fasta).\n"
