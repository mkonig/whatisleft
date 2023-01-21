#!/usr/bin/env bash

language=$1
project_folder=$2

validate_test_framework() {
    framework=$1
    local valid_frameworks=("python")

    for valid_framework in "${valid_frameworks[@]}"; do
        if [[ "$framework" = "$valid_framework" ]]; then
            exit 0
        else
            echo "\"${framework}\" is not a supported test framework."
            exit 1
        fi
    done
}

move_project_to_tmp_folder() {
    project_folder=$1
    tmp_folder=$(mktemp -d)
    cp -R "${project_folder}/." "$tmp_folder"
    echo "$tmp_folder"
}

run_main() {
    if ! [ -d "$project_folder" ]; then
        echo "No project folder defined."
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    run_main
fi
