#!/bin/bash

export path_to_gdff_annot=$(echo $CONDA_PREFIX)

if [[ "$@" == *"--local"* ]]; then
    cores=1
    reference=""
    genus=""
    species=""
    protein_fasta=""
    threads_trimming=""
    threads_fastqc=""
    threads_quast=""
    threads_checkm=""
    threads_assembly=""
    threads_annotation=""
    threads_gapseq=""
    threads_pathway_tools=""
    threads_indiv_scopes=""
    threads_community_analysis=""
    general_cores_specified=false
    tmp_dir=""
    data_folder=""
    results_folder=""
    seeds=""
    taxon=""
    skip_trim=""
    skip_annotation=""
    skip_reports=""
    skip_model=""
    skip_model_analysis=""
    multi_species=""

    for arg in "$@"; do
        if [[ "$arg" == "--general_cores" ]]; then
            general_cores_specified=true
        elif [[ "$general_cores_specified" == true ]]; then
            cores="$arg"
            general_cores_specified=false
        elif [[ "$arg" == "--reference" ]]; then
            reference_specified=true
        elif [[ "$reference_specified" == true ]]; then
            reference="$arg"
            reference_specified=false
        elif [[ "$arg" == "--multi_species" ]]; then
            multi_species_specified=true
        elif [[ "$multi_species_specified" == true ]]; then
            multi_species="$arg"
            multi_species_specified=false
        elif [[ "$arg" == "--seeds" ]]; then
            seeds_specified=true
        elif [[ "$seeds_specified" == true ]]; then
            seeds="$arg"
            seeds_specified=false
        elif [[ "$arg" == "--genus" ]]; then
            genus_specified=true
        elif [[ "$genus_specified" == true ]]; then
            genus="$arg"
            genus_specified=false
        elif [[ "$arg" == "--species" ]]; then
            species_specified=true
        elif [[ "$species_specified" == true ]]; then
            species="$arg"
            species_specified=false
        elif [[ "$arg" == "--taxon" ]]; then
            taxon_specified=true
        elif [[ "$taxon_specified" == true ]]; then
            taxon="$arg"
            taxon_specified=false
        elif [[ "$arg" == "--protein_fasta" ]]; then
            protein_fasta_specified=true
        elif [[ "$protein_fasta_specified" == true ]]; then
            protein_fasta="$arg"
            protein_fasta_specified=false
        elif [[ "$arg" == "--threads_trimming" ]]; then
            threads_trimming_specified=true
        elif [[ "$threads_trimming_specified" == true ]]; then
            threads_trimming="$arg"
            threads_trimming_specified=false
        elif [[ "$arg" == "--threads_fastqc" ]]; then
            threads_fastqc_specified=true
        elif [[ "$threads_fastqc_specified" == true ]]; then
            threads_fastqc="$arg"
            threads_fastqc_specified=false
        elif [[ "$arg" == "--threads_quast" ]]; then
            threads_quast_specified=true
        elif [[ "$threads_quast_specified" == true ]]; then
            threads_quast="$arg"
            threads_quast_specified=false
        elif [[ "$arg" == "--threads_checkm" ]]; then
            threads_checkm_specified=true
        elif [[ "$threads_checkm_specified" == true ]]; then
            threads_checkm="$arg"
            threads_checkm_specified=false
        elif [[ "$arg" == "--threads_gapseq" ]]; then
            threads_gapseq_specified=true
        elif [[ "$threads_gapseq_specified" == true ]]; then
            threads_gapseq="$arg"
            threads_gapseq_specified=false
        elif [[ "$arg" == "--threads_pathway_tools" ]]; then
            threads_pathway_tools_specified=true
        elif [[ "$threads_pathway_tools_specified" == true ]]; then
            threads_pathway_tools="$arg"
            threads_pathway_tools_specified=false
        elif [[ "$arg" == "--threads_assembly" ]]; then
            threads_assembly_specified=true
        elif [[ "$threads_assembly_specified" == true ]]; then
            threads_assembly="$arg"
            threads_assembly_specified=false
        elif [[ "$arg" == "--threads_annotation" ]]; then
            threads_annotation_specified=true
        elif [[ "$threads_annotation_specified" == true ]]; then
            threads_annotation="$arg"
            threads_annotation_specified=false
        elif [[ "$arg" == "--threads_indiv_scopes" ]]; then
            threads_indiv_scopes_specified=true
        elif [[ "$threads_indiv_scopes_specified" == true ]]; then
            threads_indiv_scopes="$arg"
            threads_indiv_scopes_specified=false
        elif [[ "$arg" == "--threads_community_analysis" ]]; then
            threads_community_analysis_specified=true
        elif [[ "$threads_community_analysis_specified" == true ]]; then
            threads_community_analysis="$arg"
            threads_community_analysis_specified=false
        elif [[ "$arg" == "--tmp_dir" ]]; then
            tmp_dir_specified=true
        elif [[ "$tmp_dir_specified" == true ]]; then
            tmp_dir="$arg"
            tmp_dir_specified=false
        elif [[ "$arg" == "--data_folder" ]]; then
            data_folder_specified=true
        elif [[ "$data_folder_specified" == true ]]; then
            data_folder="$arg"
            data_folder_specified=false
        elif [[ "$arg" == "--results_folder" ]]; then
            results_folder_specified=true
        elif [[ "$results_folder_specified" == true ]]; then
            results_folder="$arg"
            results_folder_specified=false
        elif [[ "$arg" == "--gapseq_model" ]]; then
            gapseq_model_specified=true
        elif [[ "$arg" == "--pathway_tools_model" ]]; then
            pathway_tools_model_specified=true
        elif [[ "$arg" == "--gapseq_model" ]]; then
            gapseq_model_specified=true

        elif [[ "$arg" == "--skip_trim" ]]; then
            skip_trim_specified=true
        elif [[ "$arg" == "--skip_annotation" ]]; then
            skip_annotation_specified=true
        elif [[ "$arg" == "--skip_reports" ]]; then
            skip_reports_specified=true
        elif [[ "$arg" == "--skip_model" ]]; then
            skip_model_specified=true
        elif [[ "$arg" == "--skip_model_analysis" ]]; then
            skip_model_analysis_specified=true
        fi
    done

    if [[ -z "$results_folder" || -z "$data_folder" || -z "$tmp_dir" ]]; then
        echo "Error: '--results_folder', '--tmp_dir' and '--data_folder' parameters are mandatory."
        exit 1
    fi

    if [[ "$@" == *"--verbose"* ]]; then
        verbose=true
    fi

    config_options=""
    if [ -n "$reference" ]; then
        config_options+=" reference=$reference"
    fi
    if [ -n "$multi_species" ]; then
        config_options+=" multi_species=$multi_species"
    fi
    if [ -n "$seeds" ]; then
        config_options+=" seeds=$threads_checkm"
    else
        config_options+=" seeds=$path_to_gdff_annot/bin/seeds_default.sbml"
    fi
    if [ -n "$genus" ]; then
        config_options+=" genus=$genus"
    fi
    if [ -n "$species" ]; then
        config_options+=" species=$species"
    fi
    if [ -n "$taxon" ]; then
        config_options+=" taxon=$taxon"
    else
        config_options+=" taxon=NA"
    fi
    if [ -n "$protein_fasta" ]; then
        config_options+=" protein_fasta=$protein_fasta"
    fi
    if [ -n "$threads_trimming" ]; then
        config_options+=" threads_trimming=$threads_trimming"
    else
        config_options+=" threads_trimming=1"
    fi
    if [ -n "$threads_fastqc" ]; then
        config_options+=" threads_fastqc=$threads_fastqc"
    else
        config_options+=" threads_fastqc=1"
    fi
    if [ -n "$threads_quast" ]; then
        config_options+=" threads_quast=$threads_quast"
    else
        config_options+=" threads_quast=1"
    fi
    if [ -n "$threads_checkm" ]; then
        config_options+=" threads_checkm=$threads_checkm"
    else
        config_options+=" threads_checkm=1"
    fi
    if [ -n "$threads_gapseq" ]; then
        config_options+=" threads_gapseq=$threads_gapseq"
    else
        config_options+=" threads_gapseq=1"
    fi
    if [ -n "$threads_pathway_tools" ]; then
        config_options+=" threads_pathway_tools=$threads_pathway_tools"
    else
        config_options+=" threads_pathway_tools=1"
    fi
    if [ -n "$threads_assembly" ]; then
        config_options+=" threads_assembly=$threads_assembly"
    else
        config_options+=" threads_assembly=1"
    fi
    if [ -n "$threads_annotation" ]; then
        config_options+=" threads_annotation=$threads_annotation"
    else
        config_options+=" threads_annotation=1"
    fi
    if [ -n "$threads_indiv_scopes" ]; then
        config_options+=" threads_indiv_scopes=$threads_indiv_scopes"
    else
        config_options+=" threads_indiv_scopes=1"
    fi
    if [ -n "$threads_community_analysis" ]; then
        config_options+=" threads_community_analysis=$threads_community_analysis"
    else
        config_options+=" threads_community_analysis=1"
    fi

    if [ "$gapseq_model_specified" == true ]; then
        config_options+=" gapseq_model=true"
        gapseq_value=true
    else
        config_options+=" gapseq_model=false"
        gapseq_value=false
    fi
    if [ "$pathway_tools_model_specified" == true ]; then
        config_options+=" pathway_tools_model=true"
        pathway_tools_value=true
    else
        config_options+=" pathway_tools_model=false"
        pathway_tools_value=false
    fi
    if [ "$gapseq_value" = false ] && [ "$pathway_tools_value" = false ]; then
        config_options+=" gapseq_model=true"
    fi

    if [ -n "$tmp_dir" ]; then
        config_options+=" tmp_dir=$tmp_dir"
    fi
    if [ -n "$data_folder" ]; then
        config_options+=" data_folder=$data_folder"
    fi
    if [ -n "$results_folder" ]; then
        config_options+=" results_folder=$results_folder"
    fi

    if [ "$skip_trim_specified" == true ]; then
        config_options+=" skip_trim=true"
    else
        config_options+=" skip_trim=false"
    fi
    if [ "$skip_annotation_specified" == true ]; then
        config_options+=" skip_annotation=true"
    else
        config_options+=" skip_annotation=false"
    fi
    if [ "$skip_reports_specified" == true ]; then
        config_options+=" skip_reports=true"
    else
        config_options+=" skip_reports=false"
    fi
    if [ "$skip_model_specified" == true ]; then
        config_options+=" skip_model=true"
    else
        config_options+=" skip_model=false"
    fi
    if [ "$skip_model_analysis_specified" == true ]; then
        config_options+=" skip_model_analysis=true"
    else
        config_options+=" skip_model_analysis=false"
    fi

    snakemake_command="snakemake --cores $cores --snakefile $path_to_gdff_annot/Snakefile --configfile $path_to_gdff_annot/config.yaml --latency-wait 180"

    if [ -n "$config_options" ]; then
        snakemake_command+=" --config $config_options"
    fi

    CONDA_ENV="snakemake-7.5.0"
    if [ "$verbose" == true ]; then
        conda run -n "${CONDA_ENV}" "$snakemake_command" --live
    else
        conda run -n "${CONDA_ENV}" --live "$snakemake_command" --quiet
    fi

elif [[ "$1" == "--cluster" ]]; then
    cores=32
    reference=""
    genus=""
    species=""
    protein_fasta=""
    threads_trimming=""
    threads_fastqc=""
    threads_quast=""
    threads_checkm=""
    threads_assembly=""
    threads_annotation=""
    threads_gapseq=""
    threads_pathway_tools=""
    threads_indiv_scopes=""
    threads_community_analysis=""
    general_cores_specified=false
    tmp_dir=""
    data_folder=""
    results_folder=""
    taxon=""
    skip_trim=""
    skip_annotation=""
    skip_reports=""
    skip_model=""
    skip_model_analysis=""
    multi_species=""

    for arg in "$@"; do
        if [[ "$arg" == "--general_cores" ]]; then
            general_cores_specified=true
        elif [[ "$general_cores_specified" == true ]]; then
            cores="$arg"
            general_cores_specified=false
        elif [[ "$arg" == "--reference" ]]; then
            reference_specified=true
        elif [[ "$reference_specified" == true ]]; then
            reference="$arg"
            reference_specified=false
        elif [[ "$arg" == "--seeds" ]]; then
            seeds_specified=true
        elif [[ "$seeds_specified" == true ]]; then
            seeds="$arg"
            seeds_specified=false
        elif [[ "$arg" == "--genus" ]]; then
            genus_specified=true
        elif [[ "$genus_specified" == true ]]; then
            genus="$arg"
            genus_specified=false
        elif [[ "$arg" == "--species" ]]; then
            species_specified=true
        elif [[ "$species_specified" == true ]]; then
            species="$arg"
            species_specified=false
        elif [[ "$arg" == "--taxon" ]]; then
            taxon_specified=true
        elif [[ "$taxon_specified" == true ]]; then
            taxon="$arg"
            taxon_specified=false
        elif [[ "$arg" == "--protein_fasta" ]]; then
            protein_fasta_specified=true
        elif [[ "$protein_fasta_specified" == true ]]; then
            protein_fasta="$arg"
            protein_fasta_specified=false
        elif [[ "$arg" == "--threads_trimming" ]]; then
            threads_trimming_specified=true
        elif [[ "$threads_trimming_specified" == true ]]; then
            threads_trimming="$arg"
            threads_trimming_specified=false
        elif [[ "$arg" == "--threads_fastqc" ]]; then
            threads_fastqc_specified=true
        elif [[ "$threads_fastqc_specified" == true ]]; then
            threads_fastqc="$arg"
            threads_fastqc_specified=false
        elif [[ "$arg" == "--threads_quast" ]]; then
            threads_quast_specified=true
        elif [[ "$threads_quast_specified" == true ]]; then
            threads_quast="$arg"
            threads_quast_specified=false
        elif [[ "$arg" == "--threads_checkm" ]]; then
            threads_checkm_specified=true
        elif [[ "$threads_checkm_specified" == true ]]; then
            threads_checkm="$arg"
            threads_checkm_specified=false
        elif [[ "$arg" == "--threads_gapseq" ]]; then
            threads_gapseq_specified=true
        elif [[ "$threads_gapseq_specified" == true ]]; then
            threads_gapseq="$arg"
            threads_gapseq_specified=false
        elif [[ "$arg" == "--threads_pathway_tools" ]]; then
            threads_pathway_tools_specified=true
        elif [[ "$threads_pathway_tools_specified" == true ]]; then
            threads_pathway_tools="$arg"
            threads_pathway_tools_specified=false
        elif [[ "$arg" == "--threads_assembly" ]]; then
            threads_assembly_specified=true
        elif [[ "$threads_assembly_specified" == true ]]; then
            threads_assembly="$arg"
            threads_assembly_specified=false
        elif [[ "$arg" == "--threads_annotation" ]]; then
            threads_annotation_specified=true
        elif [[ "$threads_annotation_specified" == true ]]; then
            threads_annotation="$arg"
            threads_annotation_specified=false
        elif [[ "$arg" == "--threads_indiv_scopes" ]]; then
            threads_indiv_scopes_specified=true
        elif [[ "$threads_indiv_scopes_specified" == true ]]; then
            threads_indiv_scopes="$arg"
            threads_indiv_scopes_specified=false
        elif [[ "$arg" == "--threads_community_analysis" ]]; then
            threads_community_analysis_specified=true
        elif [[ "$threads_community_analysis_specified" == true ]]; then
            threads_community_analysis="$arg"
            threads_community_analysis_specified=false
        elif [[ "$arg" == "--tmp_dir" ]]; then
            tmp_dir_specified=true
        elif [[ "$tmp_dir_specified" == true ]]; then
            tmp_dir="$arg"
            tmp_dir_specified=false
        elif [[ "$arg" == "--data_folder" ]]; then
            data_folder_specified=true
        elif [[ "$data_folder_specified" == true ]]; then
            data_folder="$arg"
            data_folder_specified=false
        elif [[ "$arg" == "--results_folder" ]]; then
            results_folder_specified=true
        elif [[ "$results_folder_specified" == true ]]; then
            results_folder="$arg"
            results_folder_specified=false
        elif [[ "$arg" == "--gapseq_model" ]]; then
            gapseq_model_specified=true
        elif [[ "$arg" == "--pathway_tools_model" ]]; then
            pathway_tools_model_specified=true

        elif [[ "$arg" == "--skip_trim" ]]; then
            skip_trim_specified=true
        elif [[ "$arg" == "--skip_annotation" ]]; then
            skip_annotation_specified=true
        elif [[ "$arg" == "--skip_reports" ]]; then
            skip_reports_specified=true
        elif [[ "$arg" == "--skip_model" ]]; then
            skip_model_specified=true
        elif [[ "$arg" == "--skip_model_analysis" ]]; then
            skip_model_analysis_specified=true

        elif [[ "$arg" == "--multi_species" ]]; then
            multi_species_specified=true
        elif [[ "$multi_species_specified" == true ]]; then
            multi_species="$arg"
            multi_species_specified=false
        fi
    done

    if [[ -z "$results_folder" || -z "$data_folder" || -z "$tmp_dir" ]]; then
        echo "Error: '--results_folder', '--tmp_dir' and '--data_folder' parameters are mandatory."
        exit 1
    fi

    config_options=""
    if [ -n "$reference" ]; then
        config_options+=" reference=$reference"
    fi
    if [ -n "$multi_species" ]; then
        config_options+=" multi_species=$multi_species"
    fi
    if [ -n "$seeds" ]; then
        config_options+=" seeds=$threads_checkm"
    else
        config_options+=" seeds=$path_to_gdff_annot/bin/seeds_default.sbml"
    fi
    if [ -n "$genus" ]; then
        config_options+=" genus=$genus"
    fi
    if [ -n "$species" ]; then
        config_options+=" species=$species"
    fi
    if [ -n "$taxon" ]; then
        config_options+=" taxon=$taxon"
    else
        config_options+=" taxon=NA"
    fi
    if [ -n "$protein_fasta" ]; then
        config_options+=" protein_fasta=$protein_fasta"
    fi
    if [ -n "$threads_trimming" ]; then
        config_options+=" threads_trimming=$threads_trimming"
    else
        config_options+=" threads_trimming=8"
    fi
    if [ -n "$threads_fastqc" ]; then
        config_options+=" threads_fastqc=$threads_fastqc"
    else
        config_options+=" threads_fastqc=4"
    fi
    if [ -n "$threads_quast" ]; then
        config_options+=" threads_quast=$threads_quast"
    else
        config_options+=" threads_quast=4"
    fi
    if [ -n "$threads_checkm" ]; then
        config_options+=" threads_checkm=$threads_checkm"
    else
        config_options+=" threads_checkm=4"
    fi
    if [ -n "$threads_gapseq" ]; then
        config_options+=" threads_gapseq=$threads_gapseq"
    else
        config_options+=" threads_gapseq=32"
    fi
    if [ -n "$threads_pathway_tools" ]; then
        config_options+=" threads_pathway_tools=$threads_pathway_tools"
    else
        config_options+=" threads_pathway_tools=32"
    fi
    if [ -n "$threads_assembly" ]; then
        config_options+=" threads_assembly=$threads_assembly"
    else
        config_options+=" threads_assembly=12"
    fi
    if [ -n "$threads_annotation" ]; then
        config_options+=" threads_annotation=$threads_annotation"
    else
        config_options+=" threads_annotation=10"
    fi
    if [ -n "$threads_indiv_scopes" ]; then
        config_options+=" threads_indiv_scopes=$threads_indiv_scopes"
    else
        config_options+=" threads_indiv_scopes=10"
    fi
    if [ -n "$threads_community_analysis" ]; then
        config_options+=" threads_community_analysis=$threads_community_analysis"
    else
        config_options+=" threads_community_analysis=10"
    fi

    if [ "$gapseq_model_specified" == true ]; then
        config_options+=" gapseq_model=true"
        gapseq_value=true
    else
        config_options+=" gapseq_model=false"
        gapseq_value=false
    fi
    if [ "$pathway_tools_model_specified" == true ]; then
        config_options+=" pathway_tools_model=true"
        pathway_tools_value=true
    else
        config_options+=" pathway_tools_model=false"
        pathway_tools_value=false
    fi
    if [ "$gapseq_value" = false ] && [ "$pathway_tools_value" = false ]; then
        config_options+=" gapseq_model=true"
    fi

    if [ -n "$tmp_dir" ]; then
        config_options+=" tmp_dir=$tmp_dir"
    fi
    if [ -n "$data_folder" ]; then
        config_options+=" data_folder=$data_folder"
    fi
    if [ -n "$results_folder" ]; then
        config_options+=" results_folder=$results_folder"
    fi

    if [ "$skip_trim_specified" == true ]; then
        config_options+=" skip_trim=true"
    else
        config_options+=" skip_trim=false"
    fi
    if [ "$skip_annotation_specified" == true ]; then
        config_options+=" skip_annotation=true"
    else
        config_options+=" skip_annotation=false"
    fi
    if [ "$skip_reports_specified" == true ]; then
        config_options+=" skip_reports=true"
    else
        config_options+=" skip_reports=false"
    fi
    if [ "$skip_model_specified" == true ]; then
        config_options+=" skip_model=true"
    else
        config_options+=" skip_model=false"
    fi
    if [ "$skip_model_analysis_specified" == true ]; then
        config_options+=" skip_model_analysis=true"
    else
        config_options+=" skip_model_analysis=false"
    fi

    cluster_command_base="qsub -V -cwd -N {rule} -pe thread {threads} -e gdff_exec -o gdff_out -q short.q"

    cluster_command="qsub -cwd -V -N gdff-annot -pe thread 4 -e gdff_exec -o gdff_out -q infinit.q -b y 'conda activate snakemake-7.5.0 && snakemake --quiet --cores $cores --snakefile $path_to_gdff_annot/Snakefile --configfile $path_to_gdff_annot/config.yaml --config $config_options --jobs 50 --keep-going --latency-wait 180 --cluster \"$cluster_command_base\" && conda deactivate'"

    eval "$cluster_command"

elif [ "$1" == "--help" ]; then
    cat "$path_to_gdff_annot"/bin/help.txt

else
    echo -e "\nusage:"
    echo "gdff-annot.sh --local --results_folder <path> --data_folder <path> --tmp_dir <path> <options>   : Lancer en local 'snakemake <params>...'"
    echo "gdff-annot.sh --cluster --results_folder <path> --data_folder <path> --tmp_dir <path> <options>   : Lancer sur le cluster de Migale 'qsub <params>...'"
    echo -e "gdff-annot.sh --help   : Run for more information.\n"
fi
