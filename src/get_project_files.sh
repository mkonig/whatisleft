#!/usr/bin/env bash

project_folder=$1
output_file=$2

error_msg=""

create_output_file() {
    exec 2>/dev/null
    local output_file="$1"
    mkdir -p "$(dirname "$output_file")"
    touch "$output_file"
}

if [[ -z "$project_folder" ]]; then
    error_msg="No project folder defined."
elif ! [[ -d "$project_folder" ]]; then
    error_msg="Project folder does not exist."
fi

if [[ -z "$output_file" ]]; then
    if [[ -n "$error_msg" ]]; then
        error_msg="${error_msg} No output folder defined."
    else
        error_msg="No output folder defined."
    fi
elif ! create_output_file "$output_file"; then
    if [[ -n "$error_msg" ]]; then
        error_msg="${error_msg} Output folder can not be created."
    else
        error_msg="Output folder can not be created."
    fi
fi

if [[ -n "$error_msg" ]]; then
    echo "$error_msg"
    exit 1
fi

fd -c never -t f -e 'py' -E 'test_*' --base-directory "$project_folder" > "${output_file}"
