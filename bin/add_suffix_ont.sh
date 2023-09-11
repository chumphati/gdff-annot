#!/bin/bash

DATA="$1"

for file in "${DATA}"/* ; do
    if [[ $file != *_1* && $file != *_2* && $file != *_ont* ]]; then
        mv "$file" "${file/.fastq/_ont.fastq}"
    fi
done
