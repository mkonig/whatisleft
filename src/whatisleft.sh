#!/usr/bin/env bash

test_framework=$1
project_folder=$2
output_folder=$3

validate_test_framework() {
    framework=$1
    local valid_frameworks=("pytest")

    for valid_framework in "${valid_frameworks[@]}"; do
        if [[ "$framework" = "$valid_framework" ]]; then
            exit 0
        else
            echo "\"${framework}\" is not a supported test framework."
            exit 1
        fi
    done
}

get_test_framework_runner() {
    framework=$1

    if [[ "$framework" == "pytest" ]]; then
        echo "pytest.sh"
    else
        return 1
    fi
}

move_project_to_output_folder() {
    project_folder=$1
    output_folder=$2
    cp -R "${project_folder}/." "$output_folder"
}

check_parameters() {
    if ! [ -d "$project_folder" ]; then
        echo "No project folder defined."
        exit 2
    fi
    if [ -z "$test_framework" ]; then
        echo "No project folder defined."
        exit 2
    fi
    if ! [ -d "$output_folder" ]; then
        echo "No project folder defined."
        exit 2
    fi
}

state_remove_line="remove_line"
state_remove_line_failed="remove_line_failed"
state_remove_line_success="remove_line_success"
state_run_runner="run_runner"
state_run_runner_failed="run_runner_failed"
state_run_runner_success="run_runner_success"
state_revert_remove="revert_remove"
state_unknown="unknown"
state_finished="finished"

next_state() {
    local last_state="$1"
    if [[ "$last_state" == "$state_remove_line_success" ]]; then
        echo "$state_run_runner"
    elif [[ "$last_state" == "$state_remove_line_failed" ]]; then
        echo "$state_finished"
    elif [[ "$last_state" == "$state_run_runner_failed" ]]; then
        echo "$state_revert_remove"
    elif [[ "$last_state" == "$state_run_runner_success" ]]; then
        echo "$state_remove_line"
    else
        echo "$state_unknown"
    fi
}

current_line_number=1
current_file=""
removed_line=""
project_files=()
current_file_index=0

get_next_file() {
    declare -a files=("${!1}")
    local next_index=$(( $2 + 1 ))

    local number_of_files=${#files[@]}
    if [[ "$next_index" -ge "$number_of_files" ]]; then
        return 1
    fi
    echo "${files[$next_index]}"
}

remove_line() {
    removed_line=$(remove_line.sh "$current_line_number" "$current_file" "$current_file")
    remove_status=$?

    if [[ "$remove_status" -eq 1 ]]; then
        echo $state_remove_line_failed
        return
    elif [[ "$remove_status" -eq 2 ]]; then
        current_file=$(get_next_file project_files[@] $current_file_index)
        get_next_file_status=$?
        if [[ "$get_next_file_status" -eq 1 ]]; then
            echo "$state_remove_line_failed"
            return 1
        fi
        current_line_number=1
        removed_line=$(remove_line.sh "$current_line_number" "$current_file" "$current_file")
        remove_status=$?
        if [[ "$remove_status" -eq 1 ]]; then
            echo $state_remove_line_failed
            return
        fi
    fi

    echo $state_remove_line_success
    return
}

run_runner() {
    eval "$framework_runner" > /dev/null 2>&1
    runner_state=$?
    if [[ "$runner_state" -ge 1 ]]; then
        echo $state_run_runner_failed
        return 1
    else
        echo $state_run_runner_success
        return 0
    fi
}

revert_remove() {
    a=$(insert_line.sh $current_line_number $removed_line $current_file $current_file > /dev/null 2>&1)
    local revert_state=$?
    echo $revert_state >&3
    if (( revert_state >= 1 )); then
        echo $state_finished
        return 1
    else
        echo $state_remove_line
        return 0
    fi
}

run_state() {
    local state="$1"
    if [[ "$state" == "$state_remove_line" ]]; then
        echo remove_line
    elif [[ "$state" == "$state_run_runner" ]]; then
        echo run_runner
    elif [[ "$state" == "$state_revert_remove" ]]; then
        echo revert_remove
    fi
}

run_main() {
    check_parameters

    local project_files_file="${output_folder}/project.files"
    local project_output_folder="${output_folder}/project"

    move_project_to_output_folder "$project_folder" "$project_output_folder"
    get_project_files.sh "$project_output_folder" "${project_files_file}"
    mapfile -t project_files < "${project_files_file}"

    local framework_runner
    framework_runner=$(get_test_framework_runner "$framework")
    echo "$project_output_folder" >&3

    local state="remove_line"
    while "$state" != "$state_finished" ; do
        state=$(run_state "$state")
        state=$(next_state "$state")
    done

    exit 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    run_main
fi
