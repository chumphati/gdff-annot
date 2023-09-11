shell.executable("/bin/bash")
shell.prefix("source /usr/local/genome/Anaconda3/etc/profile.d/conda.sh;")
results = config['results_folder']
data = config['data_folder']
get_tmp_dir = config['tmp_dir']
count_tasks = f"{get_tmp_dir}/count_tasks.txt"

if config['skip_trim'] == "false":
    rule short_reads_pe_trimming:
        input:
            read1=f"{data}/{{sample}}_1.fastq.gz",
            read2=f"{data}/{{sample}}_2.fastq.gz",
            header=f"{get_tmp_dir}/.header"
        output:
            trimmed_read1=f"{results}/trimmed_fastq/{{sample}}_1_trimmed.fastq.gz",
            trimmed_read2=f"{results}/trimmed_fastq/{{sample}}_2_trimmed.fastq.gz",
            report_json=f"{results}/reports/fastp/{{sample}}_fastp.json",
            report_html=f"{results}/reports/fastp/{{sample}}_fastp.html"
        threads: config['threads_trimming']
        log:
            f"{results}/logs/trimming/{{sample}}_illumina_pe_trimming.log"
        params:
            conda=config['short_trimming']
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            conda activate {params.conda}
            fastp -i {input.read1} -I {input.read2} --out1 {output.trimmed_read1} --out2 {output.trimmed_read2} \\
                --thread {threads} \\
                --json {output.report_json} --html {output.report_html} > {log} 2>&1
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
            
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "TRIMMING (SHORT READS)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "TRIMMING (SHORT READS)" "{wildcards.sample}" "FAIL" "$cpt_task"
                exit 1
            fi
            """

    rule long_reads_trimming:
        input:
            read_ont=f"{data}/{{sample}}_ont.fastq.gz",
            header=f"{get_tmp_dir}/.header"
        output:
            trimmed_read=f"{results}/trimmed_fastq/{{sample}}_trimmed.fastq.gz"
        threads: config['threads_trimming']
        log:
            f"{results}/logs/trimming/{{sample}}_nanopore_trimming.log"
        params:
            conda=config['long_trimming']
        resources: tmpdir=f"{get_tmp_dir}"
        shell:
            """
            conda activate {params.conda}
            filtlong --min_length 500 --min_mean_q 85 --min_window_q 65 {input.read_ont} 2> {log} | gzip > {output}
            conda deactivate
    
            cpt_task=$(cat {count_tasks})
            cpt_task=$((cpt_task + 1))
            echo "$cpt_task" > {count_tasks}
            
            if [ $? -eq 0 ]; then
                printf "%-25s %-25s %-25s %-25s\n" "TRIMMING (LONG READS)" "{wildcards.sample}" "SUCCESS" "$cpt_task"
            else
                printf "%-25s %-25s %-25s %-25s\n" "TRIMMING (LONG READS)" "{wildcards.sample}" "FAIL" "$cpt_task"
                exit 1
            fi
            """
