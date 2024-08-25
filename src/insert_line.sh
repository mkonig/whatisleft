#!/usr/bin/env bash

line_number=$1
line_to_insert="$2"
input_file=$3
output_file=$4

insert_cmd="${line_number}i\\"

if ! [[ -f "$input_file" ]]; then
    exit 1
fi

number_of_lines=$(wc -l < "$input_file")

if [[ $line_number -eq $(( number_of_lines + 1 )) ]]; then
    insert_cmd='$a\'
fi

sed -e "${insert_cmd}${line_to_insert}" "$input_file" > "$output_file"
