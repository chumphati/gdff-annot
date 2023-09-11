from bin.make_config_input import get_list_data
from bin.get_other_files_provided import get_fasta_files
shell.executable("/bin/bash")
shell.prefix("source /usr/local/genome/Anaconda3/etc/profile.d/conda.sh;")
path_to_gdff_annot = os.environ.get("path_to_gdff_annot")
data = config['data_folder']
get_type_seq = get_list_data(data)
LIST_ILLUMINA = get_type_seq[0]; LIST_NANOPORE = get_type_seq[1]; LIST_ALL = get_type_seq[2]; LIST_HYBRIDE = get_type_seq[3]
cpt_task = 0
results = config['results_folder']
get_tmp_dir = config['tmp_dir']
count_tasks = f"{get_tmp_dir}/count_tasks.txt"
ASSEMBLY_PROVIDED = get_fasta_files(data)
ANNOTATION_PROVIDED = get_annotation_files(data)
CONFIG_MULTI_SPECIES = config['multi_species']

rule initialize:
    output:
        expand(f"{get_tmp_dir}/.header")
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        printf "%-25s %-25s %-25s %-25s\n" "STEP" "SAMPLE" "STATUS" "PROGRESSION COUNT"
        echo "-----------------------------------------------------------------------------------------------\n"
        mkdir -p "{results}/logs"
        touch "{get_tmp_dir}/count_tasks.txt"
        touch "{get_tmp_dir}/.header"
        """

if config['skip_reports'] == "false":
    rule raw_fastqc:
        input:
            data=f"{data}/{{sample}}.fastq.gz",
            header=f"{get_tmp_dir}/.header"
        output:
            f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.zip",
            f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.html"
        threads: config['threads_fastqc']
        log:
            f"{results}/logs/quality_control/{{sample}}_raw_fastqc.log"
        params:
            conda={config['fastqc']}
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            conda activate {params.conda}
            fastqc -t {threads} {input.data} -o "{results}/reports/fastqc/RAW/" > {log} 2>&1
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
            
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "RAW FASTQ QC" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "RAW FASTQ QC" "{wildcards.sample}" "FAIL" "$cpt_task"
                exit 1
            fi
            """

    if config['skip_trim'] == "false":
        rule trimmed_fastqc:
            input:
                f"{results}/trimmed_fastq/{{sample}}.fastq.gz"
            output:
                f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.zip",
                f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.html"
            threads: config['threads_fastqc']
            log:
                f"{results}/logs/quality_control/{{sample}}_trimmed_fastqc.log"
            params:
                conda={config['fastqc']}
            resources: tmpdir=f"{get_tmp_dir}"
            shell:
                """
                conda activate {params.conda}
                fastqc -t {threads} {input} -o "{results}/reports/fastqc/TRIMMED/" > {log} 2>&1
                conda deactivate
        
                cpt_task=$(cat {count_tasks})
                cpt_task=$((cpt_task + 1))
                echo "$cpt_task" > {count_tasks}
                
                if [ $? -eq 0 ]; then
                    printf "%-25s %-25s %-25s %-25s\n" "TRIMMED FASTQ QC" "{wildcards.sample}" "SUCCESS" "$cpt_task"
                else
                    printf "%-25s %-25s %-25s %-25s\n" "TRIMMED FASTQ QC" "{wildcards.sample}" "FAIL" "$cpt_task"
                    exit 1
                fi
                """

    rule quast_assembly:
        input:
            assembly=lambda wildcards: [
                f"{results}/assembly/short/{sample}/{sample}.fasta"
                for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE
            ] + [
                f"{results}/assembly/long/{sample}/{sample}.fasta"
                for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE
            ] + [
                f"{results}/assembly/hybrid/{sample}/{sample}.fasta"
                for sample in LIST_HYBRIDE
            ] + [
                f"{results}/assembly/provided/{sample}/{sample}.fasta"
                for sample in ASSEMBLY_PROVIDED
            ],
            all_assembly=f"{results}/assembly/.all_assembly_finished"
        output:
            directory(f"{results}/reports/quast_report/")
        threads: config['threads_quast']
        params:
            ref= "" if config.get('reference','') == "" else f"-r {config['reference']}",
            conda=config['quast']
        log:
            f"{results}/logs/quality_control/quast_assembly.log"
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            pushd . > /dev/null 2>&1
            conda activate {params.conda} > /dev/null 2>&1
            popd > /dev/null 2>&1
            echo {input.assembly} | xargs -I {{}} sh -c 'quast -o {output} --threads {threads} --glimmer --contig-thresholds 0,1000,10000,100000,250000,1000000 --plots-format pdf {params.ref} "$@" {{}}' >> {log} 2>&1
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
    
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY QC (QUAST)" "ALL" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY QC (QUAST)" "ALL" "FAIL" "$cpt_task"
                exit 1
            fi
            """

    rule checkm_assembly:
        input:
            assembly=f"{results}/assembly/{{type}}/{{sample}}",
            all_assembly=f"{results}/assembly/.all_assembly_finished"
        output:
            directory(f"{results}/reports/checkm_report/{{sample}}_{{type}}_checkm")
        threads: config['threads_checkm']
        log:
            f"{results}/logs/quality_control/{{sample}}_{{type}}_checkm_assembly.log"
        params:
            type=['short', 'long', 'hybrid', 'provided'],
            sample=lambda wildcards: LIST_ILLUMINA if wildcards.type == 'short' else (LIST_NANOPORE if wildcards.type == 'long' else (ASSEMBLY_PROVIDED if wildcards.type == 'provided' else LIST_HYBRIDE)),
            conda={config['checkm']}
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            conda activate {params.conda}
            checkm lineage_wf "{results}/assembly/{wildcards.type}/{wildcards.sample}/" {output} --alignment_file {output}/checkm_multi-copy_genes_AAI.aln --file {output}/checkm_results.txt --threads {threads} --pplacer_threads {threads} --unique 10 --multi 10 --aai_strain 0.9 --length 0.7 --reduced_tree -x fasta > {log} 2>&1
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
    
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY QC (CHECKM)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY QC (CHECKM)" "{wildcards.sample}" "FAIL" "$cpt_task"
                exit 1
            fi
            """

    rule multiqc:
        input:
            f"{path_to_gdff_annot}/bin/multiqc_config.yaml",
            f"{results}/annotation/.bakta_log" if config['skip_annotation'] == "false" else [],
            expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.zip",sample=[f"{sample}_1" for sample in LIST_ILLUMINA] + [f"{sample}_2" for sample in LIST_ILLUMINA]),
            expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.html",sample=[f"{sample}_1" for sample in LIST_ILLUMINA] + [f"{sample}_2" for sample in LIST_ILLUMINA]),
            expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.zip",sample=[f"{sample}_ont" for sample in LIST_NANOPORE]),
            expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.html",sample=[f"{sample}_ont" for sample in LIST_NANOPORE]),
            expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.zip",sample=[f"{sample}_1_trimmed" for sample in LIST_ILLUMINA] + [f"{sample}_2_trimmed" for sample in LIST_ILLUMINA]) if config['skip_trim'] == "false" else [],
            expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.html",sample=[f"{sample}_1_trimmed" for sample in LIST_ILLUMINA] + [f"{sample}_2_trimmed" for sample in LIST_ILLUMINA]) if config['skip_trim'] == "false" else [],
            expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.zip",sample=[f"{sample}_trimmed" for sample in LIST_NANOPORE]) if config['skip_trim'] == "false" else [],
            expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.html",sample=[f"{sample}_trimmed" for sample in LIST_NANOPORE]) if config['skip_trim'] == "false" else [],
            expand(f"{results}/reports/quast_report/",sample=LIST_ALL),
            expand(f"{results}/reports/bakta/short/{{sample}}/{{sample}}_bakta.txt", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
            expand(f"{results}/reports/bakta/long/{{sample}}/{{sample}}_bakta.txt",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
            expand(f"{results}/reports/bakta/hybrid/{{sample}}/{{sample}}_bakta.txt",sample=LIST_HYBRIDE) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
            expand(f"{results}/reports/bakta/provided/{{sample}}/{{sample}}_bakta.txt",sample=[sample for sample in ASSEMBLY_PROVIDED if sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else []
        output:
            directory(f"{results}/reports/multiqc")
        log:
            f"{results}/logs/quality_control/multiqc.log"
        params:
            conda={config['multiqc']}
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            conda activate {params.conda}
            multiqc "{results}/reports/" -c {input[0]} -o {output} > {log} 2>&1
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
    
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "QC REPORT (MULTIQC)" "ALL" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "QC REPORT (MULTIQC)" "ALL" "FAIL" "$cpt_task"
                exit 1
            fi
            """
