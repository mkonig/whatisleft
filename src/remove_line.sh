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

ERROR_LINE_NR_NEGATIVE=1
ERROR_LINE_NR_GT_MAX=2
ERROR_LINE_ALREADY_REMOVED=4
ERROR_WRONG_PARAMETERS=3
ERROR_LINE_EMPTY=5
ERROR_LINE_COMMENT=6

if [[ -z $line_number || -z $input_file || -z $output_file ]]; then
    exit $ERROR_WRONG_PARAMETERS
fi

number_of_lines=$(jq -n '[inputs.line_number] | max' "$input_file")

if [[ $line_number -gt $number_of_lines ]]; then
    exit $ERROR_LINE_NR_GT_MAX
elif [[ $line_number -lt 0 ]]; then
    exit $ERROR_LINE_NR_NEGATIVE
fi

line_state=$(jq -c -r --argjson ln "$line_number" 'select(.line_number == $ln).state' "$input_file")
if [ "$line_state" = "removed" ] ; then
    exit $ERROR_LINE_ALREADY_REMOVED
fi

function is_comment() {
    local line="$1"
    if [[ "$line" =~ ^\s*# ]]; then
        return 0
    else
        return 1
    fi
}

line_content=$(jq -r --argjson ln "$line_number" 'select(.line_number == $ln).line' "$input_file")
if [ -z "$line_content" ] ; then
    exit $ERROR_LINE_EMPTY
elif is_comment "$line_content" ; then
    exit $ERROR_LINE_COMMENT
fi

jq -c --argjson ln "$line_number" 'if .line_number == $ln then .state = "removed" else . end' "$input_file" | sponge "$input_file"
tmp_file=$(mktemp)
${root_dir}/jsonl_conv.sh decode "$input_file" "$tmp_file"
cp "$tmp_file" "$output_file"

echo "$line_content"
