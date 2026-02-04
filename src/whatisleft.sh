#!/usr/bin/env bash

root_dir="src"
# shellcheck source=src/utils.sh
source "src/utils.sh"

log_level=$log_level_info

test_framework=$1
project_folder=$2
output_folder=$3

readonly E_MISSING_DIR=2
readonly E_MISSING_PARAMETER=2
readonly E_MISSING_FRAMEWORK=3

current_line_number=1
current_file=""
current_jsonl_file=""
removed_line=""
project_files=()
project_output_folder=""
framework_runner=""
number_of_changes=0
first_run=true

error_line_nr_negative=1
error_line_nr_gt_max=2
error_line_already_removed=4
error_wrong_parameters=3
error_line_is_empty=5
error_line_is_comment=6

validate_test_framework() {
    local framework=$1
    local valid_frameworks=("pytest")

    for valid_framework in "${valid_frameworks[@]}"; do
        if [[ "$framework" = "$valid_framework" ]]; then
            exit 0
        fi
    done
    echo "\"${framework}\" is not a supported test framework."
    exit 1
}

get_test_framework_runner() {
    framework=$1

    case $framework in
    "pytest")
        echo "${root_dir}/pytest.sh"
        ;;
    "bats")
        echo "${root_dir}/bats_framework.sh"
        ;;
    *)
        return 1
        ;;
    esac
}

move_project_to_output_folder() {
    project_folder=$1
    output_folder=$2
    rsync -av --exclude='.git' "$project_folder"/ "$output_folder"/
}

check_parameters() {
    if [ -z "$project_folder" ]; then
        log_info "Project folder not defined"
        exit $E_MISSING_PARAMETER
    elif ! [ -d "$project_folder" ]; then
        log_error "Project folder does not exist"
        exit $E_MISSING_DIR
    fi

    if [ -z "$test_framework" ]; then
        log_error "No test framework defined"
        exit $E_MISSING_FRAMEWORK
    fi

    if [ -z "$output_folder" ]; then
        log_error "Output folder not defined"
        exit $E_MISSING_PARAMETER
    elif ! [ -d "$output_folder" ]; then
        log_error "Output folder does not exist"
        exit $E_MISSING_DIR
    fi
}

get_next_file() {
    declare -a files=("${!1}")
    local next_index=$(($2 + 1))

    local number_of_files=${#files[@]}
    if [[ "$next_index" -ge "$number_of_files" ]]; then
        return 1
    fi
    echo "${files[$next_index]}"
}

log_remove_line_error() {
    local remove_status="$1"
    declare -A errors
    errors[$error_line_nr_negative]="Removing failed. Line number negative."
    errors[$error_line_nr_gt_max]="Removing failed. Line number to big."
    errors[$error_wrong_parameters]="Removing failed. Wrong parameters."
    errors[$error_line_already_removed]="Removing already removed lines. Skipping."
    errors[$error_line_is_empty]="Not removing because line is empty."
    errors[$error_line_is_comment]="Not removing because line is comment."
    log_info "${errors[$remove_status]}"
}

remove_line() {
    log_info "Removing line: $current_line_number, $current_file, $current_jsonl_file"

    removed_line_number=$(${root_dir}/remove_line.sh "$current_line_number" "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}")
    remove_status=$?

    log_remove_line_error $remove_status
    case "$remove_status" in
    "$error_line_nr_negative" | "$error_wrong_parameters" | "$error_line_nr_gt_max")
        return 1
        ;;
    esac

    log_info "Removed line successfully: $removed_line"
    current_line_number=$removed_line_number
    number_of_changes=$((number_of_changes + 1))
    return 0
}

run_runner() {
    log_info "Running $framework_runner"
    eval "$framework_runner $project_output_folder" >/dev/null 2>&1
    runner_state=$?
    if [[ "$runner_state" -ge 1 ]]; then
        log_info "$framework_runner failed"
        return 1
    else
        log_info "$framework_runner success"
        return 0
    fi
}

revert_remove() {
    log_info "revert: $current_line_number, removed line: $removed_line, current file: $current_file, $current_jsonl_file"

    ${root_dir}/insert_line.sh $current_line_number "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}" >/dev/null 2>&1
    local revert_state=$?
    log_debug "revert state: $revert_state"
    if ((revert_state >= 1)); then
        exit 1
    else
        number_of_changes=$((number_of_changes - 1))
        return 0
    fi
}

reset() {
    first_run=false
    number_of_changes=0
    current_file=${project_files[0]}
    current_jsonl_file="${current_file}.jsonl"
}

process_single_file() {
    local number_of_lines
    number_of_lines=$(jq -n '[inputs.line_number] | max' "${project_output_folder}/$current_jsonl_file")
    local line_nr=1
    while [ "$line_nr" -le "$number_of_lines" ]; do
        current_line_number=$line_nr
        remove_line
        remove_line_return_value=$?
        case $remove_line_return_value in
        0)
            if ! run_runner; then
                log_debug "Line to revert: $removed_line"
                revert_remove
            fi
            ;;
        1)
            exit 1
            ;;
        esac
        line_nr=$((line_nr + 1))
    done
}

process_files() {
    for file in "${project_files[@]}"; do
        current_file=${file}
        current_jsonl_file="${current_file}.jsonl"
        log_debug "Current file: $current_file"
        process_single_file
    done
}

create_jsonl_files() {
    for file in "${project_files[@]}"; do
        log_debug "Creating jsonl for: $file"
        ${root_dir}/jsonl_conv.sh encode "${project_output_folder}/$file" "${project_output_folder}/${file}.jsonl"
    done
}

main() {
    log_debug "Starting"
    check_parameters
    framework_runner=$(get_test_framework_runner "$test_framework")
    project_output_folder="${output_folder}/project"

    move_project_to_output_folder "$project_folder" "$project_output_folder"

    local project_files_file="${project_output_folder}/project.files"
    "${root_dir}/get_project_files.sh" "$project_output_folder" "${project_output_folder}/project.conf" "${project_files_file}"

    mapfile -t project_files <"${project_files_file}"
    create_jsonl_files

    first_run=true
    number_of_runs=0

    while [ "$first_run" = true ] || [ "$number_of_changes" -gt 0 ]; do
        number_of_runs=$((number_of_runs + 1))
        log_debug "Run #${number_of_runs}"
        reset
        process_files
        log_debug "Number of changes: $number_of_changes"
    done

    log_info "Creating coverage.xml"
    ${root_dir}/to_cobertura.sh "${project_files_file}" "${project_output_folder}/coverage.xml"
    echo "done"

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
