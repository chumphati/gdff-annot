def process_config_file(config_file):
    list_model = []

    with open(config_file, 'r') as file:
        for line in file:
            col1, col2, col3, col4, col5 = line.strip().split('\t')
            if col2 != "NA" and col3 != "NA" and col4 != "NA":
                list_model.append(col1)

    return list_model

