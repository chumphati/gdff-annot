from bin.get_other_files_provided import get_fasta_files
from bin.get_other_files_provided import get_annotation_files
shell.executable("/bin/bash")
shell.prefix("source /usr/local/genome/Anaconda3/etc/profile.d/conda.sh;")
results = config['results_folder']
path_to_gdff_annot = os.environ.get("path_to_gdff_annot")
get_tmp_dir = config['tmp_dir']
count_tasks = f"{get_tmp_dir}/count_tasks.txt"
ASSEMBLY_PROVIDED = get_fasta_files(data)
ANNOTATION_PROVIDED = get_annotation_files(data)
ASSEMBLY_NOT_ANNOTATION = [element for element in ASSEMBLY_PROVIDED if element not in ANNOTATION_PROVIDED]
CONFIG_MULTI_SPECIES = config['multi_species']

if config['skip_annotation'] == "false":
    rule annotation_bakta:
        input:
            assembly=f"{results}/assembly/{{type}}/{{sample}}"
        output:
            directory=directory(f"{results}/annotation/{{type}}/{{sample}}"),
            report=f"{results}/annotation/{{type}}/{{sample}}/{{sample}}.txt",
            gbff=f"{results}/annotation/{{type}}/{{sample}}/{{sample}}.gbff"
        threads: config['threads_annotation']
        log:
            f"{results}/logs/annotation/{{sample}}_{{type}}_annotation_bakta.log"
        params:
            species=lambda wildcards: f"--species {config['species']}.faa" if config.get('species', '') else '',
            genus=lambda wildcards: f"--genus {config['genus']}" if config.get('genus', '') else '',
            protein_fasta=lambda wildcards: f"--proteins {config['protein_fasta']}" if config.get('protein_fasta', '') else '',
            conda= config['bakta'],
            taxon=config['taxon'],
            multi_species_path=config['multi_species']
        shell:
            """
            conda activate {params.conda} > /dev/null 2>&1
            
            species="{params.species}"
            genus="{params.genus}" > /dev/null 2>&1
            protein_fasta="{params.protein_fasta}" > /dev/null 2>&1
            taxon="{params.taxon}" > /dev/null 2>&1
            CONFIG_MULTI={params.multi_species_path} > /dev/null 2>&1
            SAMPLE_VALUE={wildcards.sample} > /dev/null 2>&1
            if [[ $CONFIG_MULTI != "" ]]; then
                sample_line=$(grep "^$SAMPLE_VALUE" "$CONFIG_MULTI" | head -n 1)
                
                species_value=$(echo "$sample_line" | awk '{{print $3}}')
                genus_value=$(echo "$sample_line" | awk '{{print $2}}')
                protein_fasta_value=$(echo "$sample_line" | awk '{{print $5}}')
                taxon=$(echo "$sample_line" | awk '{{print $4}}')
                
                if [[ "$species_value" != "NA" ]]; then
                    species="--species $species_value.faa"
                fi
                if [[ "genus_value" != "NA" ]]; then
                    genus="--genus $genus_value"
                fi
                if [[ "$protein_fasta_value" != "NA" ]]; then
                    protein_fasta="--proteins $protein_fasta_value"
                fi
            fi
            
            bakta --output {output.directory} --min-contig-length 1 --threads {threads} --prefix {wildcards.sample} --db /db/outils/bakta-1.7.0/db/ $genus $species $protein_fasta {input.assembly}/*.fasta > {log} 2>&1
            tmpfile=$(mktemp)
            awk -v taxon="$taxon" -f {path_to_gdff_annot}/bin/add_db_xref.awk {output.gbff} > "$tmpfile"
            mv "$tmpfile" {output.gbff}
            conda deactivate
            
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
            
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "ANNOTATION (BAKTA)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "ANNOTATION (BAKTA)" "{wildcards.sample}" "FAIL" "$cpt_task"
                exit 1
            fi
            """

    if config['skip_reports'] == "false":
        rule bakta_log_report:
            input:
                annotation=f"{results}/annotation/{{type}}/{{sample}}/{{sample}}.txt"
            output:
                log_bakta=f"{results}/reports/bakta/{{type}}/{{sample}}/{{sample}}_bakta.txt"
            threads: 1
            shell:
                """
                input_file="{input.annotation}"
                output_file="{output.log_bakta}"
                config_file="{path_to_gdff_annot}/config.yaml"
                touch "$output_file"
                bash {path_to_gdff_annot}/bin/create_bakta_log_for_multiqc.sh "$input_file" "$output_file" "$config_file"
                """

        rule all_log_annot_finished:
            input:
                expand(f"{results}/reports/bakta/short/{{sample}}/{{sample}}_bakta.txt",sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]),
                expand(f"{results}/reports/bakta/long/{{sample}}/{{sample}}_bakta.txt",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]),
                expand(f"{results}/reports/bakta/hybrid/{{sample}}/{{sample}}_bakta.txt",sample=LIST_HYBRIDE),
                expand(f"{results}/annotation/provided/{{sample}}", sample=ASSEMBLY_NOT_ANNOTATION)
            output:
                f"{results}/annotation/.bakta_log"
            threads: 1
            resources: tmpdir=f"{get_tmp_dir}"
            run:
                with open(output[0], 'w') as f:
                    pass

rule get_existing_annotation:
    input:
        f"{data}/{{sample}}.gbff",
        f"{results}/assembly/.all_assembly_finished"
    output:
        touch(f"{get_tmp_dir}/annotation_provided/.get_{{sample}}_done")
    params:
        taxon = config['taxon'],
        multi_species_path = config['multi_species']
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        taxon="{params.taxon}" > /dev/null 2>&1
        CONFIG_MULTI={params.multi_species_path} > /dev/null 2>&1
        SAMPLE_VALUE={wildcards.sample} > /dev/null 2>&1
        if [[ $CONFIG_MULTI != "" ]]; then
            sample_line=$(grep "^$SAMPLE_VALUE" "$CONFIG_MULTI" | head -n 1)
            taxon=$(echo "$sample_line" | awk '{{print $4}}')
        fi
            
        mkdir -p "{results}/annotation/provided/{wildcards.sample}/"
        cp "{input[0]}" "{results}/annotation/provided/{wildcards.sample}/"
        tmpfile=$(mktemp)
        taxon={params.taxon}
        awk -v taxon="$taxon" -f "{path_to_gdff_annot}/bin/add_db_xref.awk" "{results}/annotation/provided/{wildcards.sample}/{wildcards.sample}.gbff" > "$tmpfile"
        mv "$tmpfile" "{results}/annotation/provided/{wildcards.sample}/{wildcards.sample}.gbff"
        touch {output}
        """