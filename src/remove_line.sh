#!/usr/bin/env bash

line_number=$1
input_file=$2
output_file=$3

if [[ -z $line_number || -z $input_file || -z $output_file ]]; then
    exit 3
fi

number_of_lines=$(awk 'END{print NR}' "$input_file")

if [[ $line_number -gt $number_of_lines ]]; then
    exit 2
elif [[ $line_number -lt 0 ]]; then
    exit 1
fi

removed_line=$(sed -n "${line_number}p" "$input_file")
sed "${line_number}d" "$input_file" > "$output_file"

echo "$removed_line"
