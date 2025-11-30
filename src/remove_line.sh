#!/usr/bin/env bash

# REFACTOR-5: Magic Numbers - Define error codes as constants for clarity
# readonly E_SUCCESS=0
# readonly E_INVALID_LINE_NUMBER=1
# readonly E_LINE_NUMBER_OUT_OF_BOUNDS=2
# readonly E_MISSING_PARAMETERS=3
# Then use: exit $E_INVALID_LINE_NUMBER instead of exit 1

root_dir="src"

line_number=$1
input_file=$2
output_file=$3

if [[ -z $line_number || -z $input_file || -z $output_file ]]; then
    exit 3
fi

number_of_lines=$(jq -n '[inputs.line_number] | max' "$input_file")

if [[ $line_number -gt $number_of_lines ]]; then
    exit 2
elif [[ $line_number -lt 0 ]]; then
    exit 1
fi

jq -c --argjson ln "$line_number" 'if .line_number == $ln then .state = "removed" else . end' "$input_file" | sponge "$input_file"
removed_line=$(jq -r --argjson ln "$line_number" 'select(.line_number == $ln).line' "$input_file")
tmp_file=$(mktemp)
${root_dir}/jsonl_conv.sh decode "$input_file" "$tmp_file"
# sed "${line_number}d" "$input_file" > "$tmp_file"
cp "$tmp_file" "$output_file"

echo "$removed_line"
