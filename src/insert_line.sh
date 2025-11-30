#!/usr/bin/env bash

# REFACTOR-2: Error Handling Consistency - All exit 1 errors should have distinct codes
# Consider:
# readonly E_SUCCESS=0
# readonly E_INVALID_PARAMS=1
# readonly E_INVALID_LINE_NUMBER=2
# readonly E_FILE_NOT_FOUND=3
# Then differentiate the various error conditions below

root_dir="src"

line_number=$1
input_file=$2
output_file=$3

if ! [[ "$#" -eq "3" ]]; then
    exit 1
fi
if ! [[ $line_number =~ ^[0-9]+$ ]]; then
    exit 1
fi
if ! [[ -f "$input_file" ]]; then
    exit 1
fi
if ! [[ -f "$output_file" ]]; then
    exit 1
fi

if ! jq -e --argjson ln "$line_number" 'select(.line_number == $ln)' "$input_file" > /dev/null 2>&1; then
    exit 1
fi

tmp_file=$(mktemp)
jq -c --argjson ln "$line_number" 'if .line_number == $ln then .state = "normal" else . end' "$input_file" | sponge "$input_file"
${root_dir}/jsonl_conv.sh decode "$input_file" "$tmp_file"
cp "$tmp_file" "$output_file"
