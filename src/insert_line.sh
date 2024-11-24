#!/usr/bin/env bash

line_number=$1
line_to_insert="$2"
input_file=$3
output_file=$4

if ! [[ "$#" -eq "4" ]]; then
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

insert_cmd="${line_number}i\\"
number_of_lines=$(wc -l < "$input_file")

if [[ $line_to_insert == "" ]]; then
    line_to_insert="\\"
fi

if [[ $line_number -eq $(( number_of_lines + 1 )) ]]; then
    insert_cmd='$a\'
fi

tmp_file=$(mktemp)
sed -e "${insert_cmd}${line_to_insert}" "$input_file" > "$tmp_file"
cp "$tmp_file" "$output_file"
