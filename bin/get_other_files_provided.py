import os


def get_fasta_files(directory):
    provided_assembly = []
    for filename in os.listdir(directory):
        if filename.endswith(".fa") or filename.endswith(".fasta"):
            base_name = os.path.splitext(filename)[0]
            provided_assembly.append(base_name)
    return provided_assembly


def get_annotation_files(directory):
    provided_annotation = []
    for filename in os.listdir(directory):
        if filename.endswith(".gbff") or filename.endswith(".gbk"):
            base_name = os.path.splitext(filename)[0]
            provided_annotation.append(base_name)
    return provided_annotation