import os


def get_list_data(data_folder):
    SET_ILLUMINA = set()
    SET_NANOPORE = set()
    SET_HYBRIDE = set()

    for name in os.listdir(data_folder):
        if name.endswith('.fastq.gz') or name.endswith('.fq.gz'):
            if '_1.' in name and '_2.' in name and '_ont.' in name:
                name_prefix = name.split('_1.')[0]
                SET_HYBRIDE.add(name_prefix)
            elif '_1.' in name and os.path.exists(os.path.join(data_folder, name.replace('_1.', '_2.'))):
                name_prefix = name.split('_1.')[0]
                SET_ILLUMINA.add(name_prefix)
                if name_prefix in SET_NANOPORE:
                    SET_HYBRIDE.add(name_prefix)
            elif '_2.' in name and os.path.exists(os.path.join(data_folder, name.replace('_2.', '_1.'))):
                name_prefix = name.split('_2.')[0]
                SET_ILLUMINA.add(name_prefix)
                if name_prefix in SET_NANOPORE:
                    SET_HYBRIDE.add(name_prefix)
            elif '_1.' in name and not os.path.exists(os.path.join(data_folder, name.replace('_1.', '_2.'))):
                new_name = name.replace('_1.', '_ont.')
                os.rename(os.path.join(data_folder, name), os.path.join(data_folder, new_name))
                name_prefix = new_name.split('_ont.')[0]
                SET_NANOPORE.add(name_prefix)
                if name_prefix in SET_ILLUMINA:
                    SET_HYBRIDE.add(name_prefix)
            elif '_2.' in name and not os.path.exists(os.path.join(data_folder, name.replace('_2.', '_1.'))):
                new_name = name.replace('_2.', '_ont.')
                os.rename(os.path.join(data_folder, name), os.path.join(data_folder, new_name))
                name_prefix = new_name.split('_ont.')[0]
                SET_NANOPORE.add(name_prefix)
                if name_prefix in SET_ILLUMINA:
                    SET_HYBRIDE.add(name_prefix)
            else:
                name_prefix = name.split('_ont.')[0]
                SET_NANOPORE.add(name_prefix)
                if name_prefix in SET_ILLUMINA:
                    SET_HYBRIDE.add(name_prefix)

    SET_ALL = SET_ILLUMINA.union(SET_NANOPORE).union(SET_HYBRIDE)

    LIST_ILLUMINA = list(SET_ILLUMINA)
    LIST_NANOPORE = list(SET_NANOPORE)
    LIST_ALL = list(SET_ALL)
    LIST_HYBRIDE = list(SET_HYBRIDE)

    return LIST_ILLUMINA, LIST_NANOPORE, LIST_ALL, LIST_HYBRIDE
