#!/bin/bash
RESULTS="$1"
TMP="$2"
find ${RESULTS}/annotation/{hybrid,long,short,provided} -name '*.gbff' -exec sh -c 'cp "{}" "'${TMP}'/pathway_tmp/$(basename "$(dirname "{}")")/"' \; > /dev/null 2>&1
