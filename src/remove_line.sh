#!/usr/bin/env bash

root_dir="src"

line_number=$1
input_file=$2
output_file=$3

ERROR_LINE_NR_NEGATIVE=1
ERROR_LINE_NR_GT_MAX=2
ERROR_WRONG_PARAMETERS=3

function is_comment() {
    local line="$1"
    if [[ "$line" =~ ^\s*# ]]; then
        return 0
    else
        return 1
    fi
}

if [[ -z $line_number || -z $input_file || -z $output_file ]]; then
    exit $ERROR_WRONG_PARAMETERS
fi

number_of_lines=$(jq -n '[inputs.line_number] | max' "$input_file")

if [[ $line_number -gt $number_of_lines ]]; then
    exit $ERROR_LINE_NR_GT_MAX
elif [[ $line_number -lt 0 ]]; then
    exit $ERROR_LINE_NR_NEGATIVE
fi

while [ "$line_number" -le "$number_of_lines" ]; do
    line_state=$(jq -c -r --argjson ln "$line_number" 'select(.line_number == $ln).state' "$input_file")
    line_content=$(jq -r --argjson ln "$line_number" 'select(.line_number == $ln).line' "$input_file")
    if [[ "$line_state" == "removed" ]] || [[ "$line_state" == "ignore" ]] ; then
        line_number=$(( line_number + 1 ))
    else
        jq -c --argjson ln "$line_number" 'if .line_number == $ln then .state = "removed" else . end' "$input_file" | sponge "$input_file"
        tmp_file=$(mktemp)
        ${root_dir}/jsonl_conv.sh decode "$input_file" "$tmp_file"
        cp "$tmp_file" "$output_file"

        echo "$line_number"
        exit 0
    fi
done


