#!/bin/bash

input_file="$1"
output_file="$2"
config_file="$3"
patterns=("organism" "Count" "Length" "CDS" "rRNA" "tRNA" "tmRNA")

extract_number() {
  local line="$1"
  local pattern="$2"
  local number=$(echo "$line" | sed -n "s/${pattern} \([0-9]\+\)/\1/p")
  echo "${pattern}:${number}"
}

genus=$(awk 'genus {print $2}' "$config_file")
echo "organism: $genus" > "$output_file"

for pattern in "${patterns[@]}"; do
  while IFS= read -r line; do
    if [[ $line =~ $pattern ]]; then
      if [[ $pattern == "Count" ]]; then
        result=$(echo "$line" | cut -d':' -f2)
        echo "contigs: $result" >> "$output_file"
      elif [[ $pattern == "Length" ]]; then
        result=$(echo "$line" | cut -d':' -f2)
        echo "bases: $result" >> "$output_file"
      else
        extracted=$(extract_number "$line" "$pattern")
        result=$(echo "$line" | cut -d':' -f2)
        echo "$extracted $result" >> "$output_file"
      fi
    fi
  done < "$input_file"
done
