from bin.make_config_input import get_list_data
from bin.get_other_files_provided import get_fasta_files
data = config['data_folder']
get_type_seq = get_list_data(data)
LIST_ILLUMINA = get_type_seq[0]; LIST_NANOPORE = get_type_seq[1]; LIST_ALL = get_type_seq[2]; LIST_HYBRIDE = get_type_seq[3]
ASSEMBLY_PROVIDED = get_fasta_files(data)
ANNOTATION_PROVIDED = get_annotation_files(data)
shell.executable("/bin/bash")
shell.prefix("source /usr/local/genome/Anaconda3/etc/profile.d/conda.sh;")
results = config['results_folder']
get_tmp_dir = config['tmp_dir']
count_tasks = f"{get_tmp_dir}/count_tasks.txt"

rule short_reads_assembly:
    input:
        short_assembly1=f"{results}/trimmed_fastq/{{sample}}_1_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_1.fastq.gz",
        short_assembly2=f"{results}/trimmed_fastq/{{sample}}_2_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_2.fastq.gz",
        header=f"{get_tmp_dir}/.header"
    output:
        directory(f"{results}/assembly/short/{{sample}}"),
        f"{results}/assembly/short/{{sample}}/{{sample}}.fasta"
    threads: config['threads_assembly']
    log:
        f"{results}/logs/assembly/{{sample}}_short_reads_assembly.log"
    params:
        conda={config['unicycler']}
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        conda activate {params.conda}
        unicycler --threads {threads} --mode normal --keep 0 --min_fasta_length 150 --out "{results}/assembly/short/{wildcards.sample}" -1 {input.short_assembly1} -2 {input.short_assembly2} > {log} 2>&1
        conda deactivate
        
        mv {results}/assembly/short/{wildcards.sample}/assembly.fasta {results}/assembly/short/{wildcards.sample}/{wildcards.sample}.fasta
        
        rm -rf "{results}/assembly/short/{wildcards.sample}/miniasm_assembly"
        mv "{results}/assembly/short/{wildcards.sample}/unicycler.log" "{results}/assembly/short/{wildcards.sample}/{wildcards.sample}_unicycler.log"
        mv "{results}/assembly/short/{wildcards.sample}/{wildcards.sample}_unicycler.log" "{results}/logs/assembly/"
        
        cpt_task=$(cat {count_tasks})
        cpt_task=$((cpt_task + 1))
        echo "$cpt_task" > {count_tasks}
        
        if [ $? -eq 0 ]; then
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (SHORT READS)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
        else
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (SHORT READS)" "{wildcards.sample}" "FAIL" "$cpt_task"
            exit 1
        fi
        """

rule long_reads_assembly:
    input:
        long_assembly=f"{results}/trimmed_fastq/{{sample}}_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_ont.fastq.gz",
        header=f"{get_tmp_dir}/.header"
    output:
        directory(f"{results}/assembly/long/{{sample}}"),
        f"{results}/assembly/long/{{sample}}/{{sample}}.fasta"
    threads: config['threads_assembly']
    log:
        f"{results}/logs/assembly/{{sample}}_long_reads_assembly.log"
    params:
        conda={config['unicycler']}
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        conda activate {params.conda}
        unicycler --threads {threads} --mode normal --keep 0 --min_fasta_length 150 --out "{results}/assembly/long/{wildcards.sample}" --long {input.long_assembly} > {log} 2>&1
        conda deactivate
        
        rm -rf "{results}/assembly/long/{wildcards.sample}/miniasm_assembly"
        mv "{results}/assembly/long/{wildcards.sample}/unicycler.log" "{results}/assembly/long/{wildcards.sample}/{wildcards.sample}_unicycler.log"
        mv "{results}/assembly/long/{wildcards.sample}/{wildcards.sample}_unicycler.log" "{results}/logs/assembly/"
        mv {results}/assembly/long/{wildcards.sample}/assembly.fasta {results}/assembly/long/{wildcards.sample}/{wildcards.sample}.fasta
        
        cpt_task=$(cat {count_tasks})
        cpt_task=$((cpt_task + 1))
        echo "$cpt_task" > {count_tasks}
        
        if [ $? -eq 0 ]; then
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (LONG READS)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
        else
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (LONG READS)" "{wildcards.sample}" "FAIL" "$cpt_task"
            exit 1
        fi
        """

rule hybrid_assembly:
    input:
        short_assembly1=f"{results}/trimmed_fastq/{{sample}}_1_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_1.fastq.gz",
        short_assembly2=f"{results}/trimmed_fastq/{{sample}}_2_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_2.fastq.gz",
        long_assembly=f"{results}/trimmed_fastq/{{sample}}_trimmed.fastq.gz" if config['skip_trim'] == "false" else f"{data}/{{sample}}_ont.fastq.gz",
        header=f"{get_tmp_dir}/.header"
    output:
        directory(f"{results}/assembly/hybrid/{{sample}}"),
        f"{results}/assembly/hybrid/{{sample}}/{{sample}}.fasta"
    threads: config['threads_assembly']
    log:
        f"{results}/logs/assembly/{{sample}}_hybrid_assembly.log"
    params:
        conda={config['unicycler']}
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        conda activate {params.conda}
        unicycler --threads {threads} --mode normal --keep 0 --min_fasta_length 150 --out "{results}/assembly/hybrid/{wildcards.sample}" -1 {input.short_assembly1} -2 {input.short_assembly2} --long {input.long_assembly} > {log} 2>&1
        conda deactivate
        
        rm -rf "{results}/assembly/hybrid/{wildcards.sample}/miniasm_assembly"
        mv "{results}/assembly/hybrid/{wildcards.sample}/unicycler.log" "{results}/assembly/hybrid/{wildcards.sample}/{wildcards.sample}_unicycler.log"
        mv "{results}/assembly/hybrid/{wildcards.sample}/{wildcards.sample}_unicycler.log" "{results}/logs/assembly/"
        mv {results}/assembly/hybrid/{wildcards.sample}/assembly.fasta {results}/assembly/hybrid/{wildcards.sample}/{wildcards.sample}.fasta
        
        cpt_task=$(cat {count_tasks})
        cpt_task=$((cpt_task + 1))
        echo "$cpt_task" > {count_tasks}
        
        if [ $? -eq 0 ]; then
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (HYBRID)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
        else
            printf "%-25s %-25s %-25s %-25s\n" "ASSEMBLY (HYBRID)" "{wildcards.sample}" "FAIL" "$cpt_task"
            exit 1
        fi
       """

rule get_existing_fasta:
    input:
        expand(f"{data}/{{sample}}.fasta", sample=ASSEMBLY_PROVIDED)
    output:
        directory(expand(f"{results}/assembly/provided/{{sample}}", sample=ASSEMBLY_PROVIDED)),
        expand(f"{results}/assembly/provided/{{sample}}/{{sample}}.fasta", sample=ASSEMBLY_PROVIDED)
    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        mkdir -p {output[0]}
        bash {path_to_gdff_annot}/bin/touch_assembly_provided_dir.sh {data} {results}
        """

rule all_assembly_finished:
    input:
        expand(f"{results}/assembly/short/{{sample}}/", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/long/{{sample}}/", sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/hybrid/{{sample}}/", sample=LIST_HYBRIDE),
        expand(f"{results}/assembly/provided/{{sample}}/", sample=ASSEMBLY_PROVIDED)
    output:
        f"{results}/assembly/.all_assembly_finished"
    resources: tmpdir=f"{get_tmp_dir}"
    run:
        with open(output[0], 'w') as f:
            pass