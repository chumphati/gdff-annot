import os
import subprocess
from bin.make_config_input import get_list_data
path_to_gdff_annot = os.environ.get("path_to_gdff_annot")
data = config['data_folder']
subprocess.run(["bash", f"{path_to_gdff_annot}/bin/add_suffix_ont.sh", f"{data}"], capture_output=True, text=True)
from bin.get_other_files_provided import get_fasta_files
from bin.get_other_files_provided import get_annotation_files
from bin.get_sample_model import process_config_file

if not os.path.exists(".name"):
    subprocess.run(["touch", ".name"])
    with open(f"{path_to_gdff_annot}/bin/name.txt", "r") as file:
        name = file.read()
    print(name)

configfile: f"{path_to_gdff_annot}/config.yaml"
include: "rules/clean_fastq.smk"
include: "rules/quality_control.smk"
include: "rules/assembly.smk"
include: "rules/annotation.smk"
include: "rules/metabolic_pathways.smk"

wildcard_constraints:
    sample = "[A-Za-z0-9_.-À-ÖØ-öø-ÿ]+"

get_type_seq = get_list_data(data)
LIST_ILLUMINA = get_type_seq[0]; LIST_NANOPORE = get_type_seq[1]; LIST_ALL = get_type_seq[2]; LIST_HYBRIDE = get_type_seq[3]
results = config['results_folder']
get_tmp_dir = config['tmp_dir']

ASSEMBLY_PROVIDED = get_fasta_files(data)
ANNOTATION_PROVIDED = get_annotation_files(data)

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

rule end:
    input:
        expand(f"{get_tmp_dir}/.header"),
        expand(f"{get_tmp_dir}/annotation_provided/.get_{{sample}}_done", sample=ANNOTATION_PROVIDED) if len(ANNOTATION_PROVIDED) > 0 else [],
        #fastqc raw reads
        expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.zip", sample=[f"{sample}_1" for sample in LIST_ILLUMINA] + [f"{sample}_2" for sample in LIST_ILLUMINA]) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.html", sample=[f"{sample}_1" for sample in LIST_ILLUMINA] + [f"{sample}_2" for sample in LIST_ILLUMINA]) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.zip", sample=[f"{sample}_ont" for sample in LIST_NANOPORE]) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/RAW/{{sample}}_fastqc.html", sample=[f"{sample}_ont" for sample in LIST_NANOPORE]) if config['skip_reports'] == "false" else [],
        #nettoyage des reads
        #illumina
        expand(f"{results}/trimmed_fastq/{{sample}}_1_trimmed.fastq.gz", sample=LIST_ILLUMINA) if config['skip_trim'] == "false" else [],
        expand(f"{results}/trimmed_fastq/{{sample}}_2_trimmed.fastq.gz", sample=LIST_ILLUMINA) if config['skip_trim'] == "false" else [],
        #nanopore
        expand(f"{results}/trimmed_fastq/{{sample}}_trimmed.fastq.gz", sample=LIST_NANOPORE) if config['skip_trim'] == "false" else [],
        #fastqc trimmed reads
        expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.zip", sample=[f"{sample}_1_trimmed" for sample in LIST_ILLUMINA] + [f"{sample}_2_trimmed" for sample in LIST_ILLUMINA]) if config['skip_trim'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.html", sample=[f"{sample}_1_trimmed" for sample in LIST_ILLUMINA] + [f"{sample}_2_trimmed" for sample in LIST_ILLUMINA]) if config['skip_trim'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.zip", sample=[f"{sample}_trimmed" for sample in LIST_NANOPORE]) if config['skip_trim'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/fastqc/TRIMMED/{{sample}}_fastqc.html", sample=[f"{sample}_trimmed" for sample in LIST_NANOPORE]) if config['skip_trim'] == "false" and config['skip_reports'] == "false" else [],
        #assemblage
        expand(f"{results}/assembly/short/{{sample}}", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/long/{{sample}}", sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/hybrid/{{sample}}", sample=LIST_HYBRIDE),
        expand(f"{results}/assembly/provided/{{sample}}", sample=ASSEMBLY_PROVIDED),
        expand(f"{results}/assembly/short/{{sample}}/{{sample}}.fasta", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/long/{{sample}}/{{sample}}.fasta",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]),
        expand(f"{results}/assembly/hybrid/{{sample}}/{{sample}}.fasta",sample=LIST_HYBRIDE),
        expand(f"{results}/assembly/provided/{{sample}}/{{sample}}.fasta",sample=ASSEMBLY_PROVIDED),
        # #qualité assemblage
        expand(f"{results}/assembly/.all_assembly_finished"),
        expand(f"{results}/reports/quast_report/") if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/checkm_report/{{sample}}_short_checkm", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/checkm_report/{{sample}}_long_checkm", sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/checkm_report/{{sample}}_hybrid_checkm", sample=LIST_HYBRIDE) if config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/checkm_report/{{sample}}_provided_checkm", sample=ASSEMBLY_PROVIDED) if config['skip_reports'] == "false" else [],
        # #annotation
        expand(f"{results}/annotation/short/{{sample}}", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/long/{{sample}}",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/hybrid/{{sample}}",sample=LIST_HYBRIDE) if config['skip_annotation'] == "false" and config['taxon'] != "NA" or len(CONFIG_MULTI_SPECIES)>0 else [],
        expand(f"{results}/annotation/provided/{{sample}}", sample=[sample for sample in ASSEMBLY_PROVIDED if sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/reports/bakta/short/{{sample}}/{{sample}}_bakta.txt", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/bakta/long/{{sample}}/{{sample}}_bakta.txt",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/bakta/hybrid/{{sample}}/{{sample}}_bakta.txt",sample=LIST_HYBRIDE) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/reports/bakta/provided/{{sample}}/{{sample}}_bakta.txt", sample=[sample for sample in ASSEMBLY_PROVIDED if sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
        expand(f"{results}/annotation/short/{{sample}}/{{sample}}.gbff", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE and sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/long/{{sample}}/{{sample}}.gbff",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE and sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/hybrid/{{sample}}/{{sample}}.gbff",sample=LIST_HYBRIDE) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/provided/{{sample}}/{{sample}}.gbff", sample=[sample for sample in ASSEMBLY_PROVIDED if sample not in ANNOTATION_PROVIDED]) if config['skip_annotation'] == "false" else [],
        expand(f"{results}/annotation/.bakta_log") if config['skip_annotation'] == "false" and config['skip_reports'] == "false" else [],
        #merge rapports
        expand(f"{results}/reports/multiqc") if config['skip_reports'] == "false" else [],
        #model
        expand(f"{results}/pathway_model") if config['pathway_tools_model'] == "true" and config['skip_model'] == "false" else[],
        expand(f"{results}/gapseq_model/short/{{sample}}", sample=[sample for sample in LIST_ILLUMINA if sample not in LIST_HYBRIDE]) if config['gapseq_model'] == "true" and config['skip_model'] == "false" else [],
        expand(f"{results}/gapseq_model/long/{{sample}}",sample=[sample for sample in LIST_NANOPORE if sample not in LIST_HYBRIDE]) if config['gapseq_model'] == "true" and config['skip_model'] == "false" else [],
        expand(f"{results}/gapseq_model/hybrid/{{sample}}",sample=LIST_HYBRIDE) if config['gapseq_model'] == "true" and config['skip_model'] == "false" else [],
        expand(f"{results}/gapseq_model/provided/{{sample}}", sample=ASSEMBLY_PROVIDED) if config['gapseq_model'] == "true" and config['skip_model'] == "false" else [],
        expand(f"{results}/gapseq_sbml") if config['gapseq_model'] == "true" and config['skip_model'] == "false" else [],
        #indiv scopes
        expand(f"{results}/indiv_scopes") if config['skip_model'] == "false" and config['skip_model_analysis'] == "false" and (config['pathway_tools_model'] == "true" or config['gapseq_model'] == "true") else [],
        #community analysis
        expand(f"{results}/community_analysis") if config['skip_model'] == "false" and config['skip_model_analysis'] == "false" and (config['pathway_tools_model'] == "true" or config['gapseq_model'] == "true") else []

    resources: tmpdir=f"{get_tmp_dir}"
    shell:
        """
        rm -rf .name
        rm -rf "{results}/tmp/"
        echo "___________________"
        echo "Analyses completed!"
        """
