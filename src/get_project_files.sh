#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename "$0") <project folder> <config> <output file>"
    exit 1
fi

project_folder=$1
project_config=$2
output_file=$3

error_msg=""

create_output_file() {
    local output_file="$1"
    mkdir -p "$(dirname "$output_file")"
    touch "$output_file"
}

append_error_msg() {
    if [[ ${error_msg} ]]; then
        error_msg="${error_msg} $1"
    else
        error_msg=$1
    fi
}

if ! [[ -d "$project_folder" ]]; then
    append_error_msg "Project folder does not exist."
fi

if ! [[ -f "$project_config" ]]; then
    append_error_msg "Project config does not exist."
fi

if ! create_output_file "$output_file"; then
    append_error_msg "Output file can not be created."
fi

if [[ -n "$error_msg" ]]; then
    echo "$error_msg"
    exit 1
fi

pushd "$project_folder" > /dev/null || exit
xargs -a "$project_config" -I {} sh -c "ls {}" > "$output_file"
popd > /dev/null || exit
