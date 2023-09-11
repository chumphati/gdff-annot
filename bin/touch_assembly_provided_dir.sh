#!/bin/bash
DATA_INPUT="$1"
RESULTS="$2"
find ${DATA_INPUT} -name '*.fasta' -exec sh -c 'base=$(basename "{}" .fasta); cp "{}" "'${RESULTS}'/assembly/provided/$base/"' \;
