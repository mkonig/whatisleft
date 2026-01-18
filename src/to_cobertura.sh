#!/usr/bin/env bash

project_file="$1"
output_file="$2"
xml_header='<?xml version="1.0" encoding="utf-8"?> <!DOCTYPE coverage SYSTEM "https://raw.githubusercontent.com/cobertura/cobertura/refs/heads/master/cobertura/src/site/htdocs/xml/coverage-04.dtd"> <coverage version="0.1.0" timestamp="" lines-valid="" lines-covered="2" line-rate="" branches-covered="0" branches-valid="0" branch-rate="0" complexity="0"> <sources/><packages> <package name="." line-rate="0" branch-rate="0" complexity="0"> <classes>'
xml_footer="</classes> </package> </packages> </coverage>"

mapfile -t project_files <"${project_file}"
basedir=$(dirname "${project_file}")

function file_xml() {
    local number_of_lines
    number_of_lines=$(jq -n '[inputs.line_number] | max' "$current_jsonl_file")
    local line_coverage=""
    local line_nr=1
    while [ "$line_nr" -le "$number_of_lines" ]; do
        line_state=$(jq -c -r --argjson ln "$line_nr" 'select(.line_number == $ln).state | if . == "removed" then 0 else 1 end' "$current_jsonl_file")

        line_coverage="${line_coverage}<line number=\"${line_nr}\" hits=\"${line_state}\"/>"
        line_nr=$((line_nr + 1))
    done
    echo "<class name=\"${current_file}\" filename=\"${current_file}\" complexity=\"0\" line-rate=\"0\" branch-rate=\"0\"> <methods/> <lines>${line_coverage}</lines></class>"
}

function make_xml() {
    echo "$xml_header" >"$output_file"
    for file in "${project_files[@]}" ; do
        current_file=${file}
        current_jsonl_file="${basedir}/${current_file}.jsonl"
        file_xml >>"$output_file"
    done
    echo "$xml_footer" >>"$output_file"
    xmlstarlet fo "$output_file" | sponge "$output_file"
}

make_xml
