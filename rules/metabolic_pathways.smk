from bin.get_other_files_provided import get_fasta_files
from bin.get_other_files_provided import get_annotation_files
shell.executable("/bin/bash")
shell.prefix("source /usr/local/genome/Anaconda3/etc/profile.d/conda.sh;")
results = config['results_folder']
data = config['data_folder']
get_tmp_dir = config['tmp_dir']
count_tasks = f"{get_tmp_dir}/count_tasks.txt"
path_to_gdff_annot = os.environ.get("path_to_gdff_annot")
get_type_seq = get_list_data(data)
data = config['data_folder']
LIST_ILLUMINA = get_type_seq[0]; LIST_NANOPORE = get_type_seq[1]; LIST_ALL = get_type_seq[2]; LIST_HYBRIDE = get_type_seq[3]
ASSEMBLY_PROVIDED = get_fasta_files(data)
ANNOTATION_PROVIDED = get_annotation_files(data)
ASSEMBLY_NOT_ANNOTATION = [element for element in ASSEMBLY_PROVIDED if element not in ANNOTATION_PROVIDED]

LIST_MODEL=[]
config_multi=config['multi_species']
if config_multi != "":
    LIST_MODEL=process_config_file(config_multi)
else:
    if config['genus'] != "" and config['species'] != "" and config['taxon'] != "":
        LIST_MODEL = list(set(LIST_ALL) | set(ASSEMBLY_PROVIDED) | set(ASSEMBLY_NOT_ANNOTATION))
    for element in ANNOTATION_PROVIDED:
        if element in ASSEMBLY_PROVIDED:
            LIST_MODEL.append(element)

if config['skip_model'] == "false":
    rule gapseq_model:
        input:
            assembly=f"{results}/assembly/{{type}}/{{sample}}"
        output:
            directory=directory(f"{results}/gapseq_model/{{type}}/{{sample}}")
        threads: config['threads_gapseq']
        params:
            type=['short', 'long', 'hybrid', 'provided'],
            sample=lambda wildcards: LIST_ILLUMINA if wildcards.type == 'short' else (LIST_NANOPORE if wildcards.type == 'long' else (ASSEMBLY_PROVIDED if wildcards.type == 'provided' else LIST_HYBRIDE)),
            conda={config['gapseq']}
        shell:
            """
            pushd . > /dev/null 2>&1
            conda activate {params.conda} > /dev/null 2>&1
            mkdir -p {output.directory}
            cp {input.assembly}/{wildcards.sample}.fasta {output.directory}
            cd {output.directory}
            gapseq doall {wildcards.sample}.fasta  > /dev/null 2>&1
            conda deactivate
            popd > /dev/null 2>&1
            
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
    
            if [ -d "{results}/gapseq_model/{wildcards.type}/{wildcards.sample}.xml" ]; then
                printf "%-25s %-25s %-25s %-25s\n" "MODEL (GAPSEQ)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "MODEL (GAPSEQ)" "{wildcards.sample}" "FAIL" "$cpt_task"
            fi
            """

    rule get_gapseq_output:
        input:
            short=expand(f"{results}/gapseq_model/short/{{sample}}", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]),
            long=expand(f"{results}/gapseq_model/long/{{sample}}",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]),
            hybrid=expand(f"{results}/gapseq_model/hybrid/{{sample}}",sample=LIST_HYBRIDE),
            provided=expand(f"{results}/gapseq_model/provided/{{sample}}",sample=ASSEMBLY_PROVIDED)
        output:
            expand(f"{results}/gapseq_sbml",sample=LIST_ALL+ASSEMBLY_PROVIDED)
        threads: config['threads_gapseq']
        shell:
            """
            mkdir -p {output}/sbml > /dev/null 2>&1
            mv {input.short}/.xml {input.long}/.xml {input.hybrid}/.xml {input.provided}/.xml {output}/sbml > /dev/null 2>&1
            """

    rule pathway_tools_model:
        input:
            assembly=lambda wildcards: [
             f"{results}/assembly/short/{sample}"
             for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE and sample in LIST_MODEL
            ] + [
             f"{results}/assembly/long/{sample}"
             for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE and sample in LIST_MODEL
            ] + [
             f"{results}/assembly/hybrid/{sample}"
             for sample in LIST_HYBRIDE if sample in LIST_MODEL
            ] + [
             f"{results}/assembly/provided/{sample}"
             for sample in ASSEMBLY_PROVIDED if sample in LIST_MODEL
            ],
            annot=lambda wildcards: [
             f"{results}/annotation/short/{sample}/{sample}.gbff"
             for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE and sample not in ANNOTATION_PROVIDED and sample in LIST_MODEL
            ] + [
             f"{results}/annotation/long/{sample}/{sample}.gbff"
             for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE and sample not in ANNOTATION_PROVIDED and sample in LIST_MODEL
            ] + [
             f"{results}/annotation/hybrid/{sample}/{sample}.gbff"
             for sample in LIST_HYBRIDE if sample not in ANNOTATION_PROVIDED and sample in LIST_MODEL
            ] + [
             f"{results}/annotation/provided/{sample}/{sample}.gbff"
             for sample in ASSEMBLY_NOT_ANNOTATION if sample in ASSEMBLY_PROVIDED and sample in LIST_MODEL
            ],
            prov_annot_time=expand(f"{get_tmp_dir}/annotation_provided/.get_{{sample}}_done",sample=ANNOTATION_PROVIDED) if len(ANNOTATION_PROVIDED) > 0 else []
        output:
            out_directory=directory(f"{get_tmp_dir}/pathway_tmp"),
            directory=directory(f"{results}/pathway_model"),
        threads: config['threads_pathway_tools']
        log:
            f"{results}/logs/pathway_model/pathway_tools.log"
        params:
            conda={config['m2m']}
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            mkdir -p {output.out_directory}
            cp -r {input.assembly} {output.out_directory} > /dev/null 2>&1
            bash {path_to_gdff_annot}/bin/find_dir_pathway.sh {results} {get_tmp_dir} > /dev/null 2>&1
            
            conda activate {params.conda} > /dev/null 2>&1
            m2m recon -g {output.out_directory} -o {output.directory} -c {threads} -p --clean > {log} 2>&1
            conda deactivate
            
            mv {results}/pathway_model/m2m_recon.log {results}/logs/pathway_model > /dev/null 2>&1
            
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
            
            if [ ! -d "{results}/pathway_model/sbml" ]; then
                printf "%-25s %-25s %-25s %-25s\n" "MODEL (PATHWAY-TOOLS)" "ALL" "FAIL" "$cpt_task"
                echo "error: Pathway-tools failed. Check if you have correctly specified the taxonomy code for each file."
                exit 1
            else
                printf "%-25s %-25s %-25s %-25s\n" "MODEL (PATHWAY-TOOLS)" "ALL" "SUCCESS" "$cpt_task"
            fi
            """

    if config['skip_model_analysis'] == "false" and (config['pathway_tools_model'] == "true") or config['gapseq_model'] == "true":
        rule individual_analysis:
            input:
                expand(f"{results}/pathway_model") if config['pathway_tools_model'] == "true" else[],
                expand(f"{results}/gapseq_sbml") if config['gapseq_model'] == "true" else []
            output:
                directory=directory(f"{results}/indiv_scopes")
            threads: config['threads_indiv_scopes']
            log:
                f"{results}/logs/model/indiv_scopes.log"
            params:
                conda={config['m2m']},
                seeds= lambda wildcards: f"-s {config['seeds']}" if config.get('seeds','') else '',
            resources: tmpdir=f"{get_tmp_dir}"
            shell:
                """
                conda activate {params.conda} > /dev/null 2>&1
                m2m iscope -n {input}/sbml -o {output.directory} -c {threads} {params.seeds} > {log} 2>&1
                conda deactivate
                
                mv {results}/indiv_scopes/m2m_iscope.log {results}/logs/model > /dev/null 2>&1
        
                cpt_task=$(cat {count_tasks})
                cpt_task=$((cpt_task + 1))
                echo "$cpt_task" > {count_tasks}
                
                if [ ! -d "{results}/indiv_scopes" ]; then
                    printf "%-25s %-25s %-25s %-25s\n" "INDIVIDUAL SCOPES" "ALL" "FAIL" "$cpt_task"
                    echo "error: Missing input information (MeneTools). Check that you have correctly provided the genus and species name, and the taxonomic code."
                    exit 1
                else
                    printf "%-25s %-25s %-25s %-25s\n" "INDIVIDUAL SCOPES" "ALL" "SUCCESS" "$cpt_task"
                fi
                """

        rule community_analysis:
            input:
                expand(f"{results}/pathway_model") if config['pathway_tools_model'] == "true" else [],
                expand(f"{results}/gapseq_sbml") if config['gapseq_model'] == "true" else []
            output:
                directory=directory(f"{results}/community_analysis")
            threads: config['threads_community_analysis']
            log:
                f"{results}/logs/model/community_analysis.log"
            params:
                conda={config['m2m']},
                seeds= lambda wildcards: f"-s {config['seeds']}" if config.get('seeds','') else '',
            resources: tmpdir=f"{get_tmp_dir}"
            shell:
                """
                conda activate {params.conda} > /dev/null 2>&1
                m2m cscope -n {input}/sbml -o {output.directory} {params.seeds} > {log} 2>&1
                conda deactivate
                
                mv {results}/community_analysis/m2m_cscope.log {results}/logs/model > /dev/null 2>&1
        
                cpt_task=$(cat {count_tasks})
                cpt_task=$((cpt_task + 1))
                echo "$cpt_task" > {count_tasks}
                
                if [ ! -d "{results}/community_analysis/community_analysis" ]; then
                    printf "%-25s %-25s %-25s %-25s\n" "COMMUNITY ANALYSIS" "ALL" "FAIL" "$cpt_task"
                    echo "error: Missing input information (Miscoto). Check that you have correctly provided the genus and species name, and the taxonomic code."
                    exit 1
                else
                    printf "%-25s %-25s %-25s %-25s\n" "COMMUNITY ANALYSIS" "ALL" "SUCCESS" "$cpt_task"
                fi
                """
