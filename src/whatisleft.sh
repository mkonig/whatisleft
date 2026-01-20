#!/usr/bin/env bash

root_dir="src"
# shellcheck source=src/utils.sh
source "src/utils.sh"

log_level=$log_level_info

test_framework=$1
project_folder=$2
output_folder=$3

# readonly E_SUCCESS=0
# readonly E_INVALID_ARGS=1
readonly E_MISSING_DIR=2
readonly E_MISSING_FRAMEWORK=3


# REFACTOR-4: Global Variables - These globals make testing difficult and create implicit dependencies
# Consider encapsulating in a context structure:
# declare -A ctx=(
#   [current_line]=1
#   [current_file]=""
#   [removed_line]=""
#   [file_index]=0
#   [changes]=0
#   [state]=""
# )
# Access as ${ctx[current_line]} throughout
current_line_number=1
current_file=""
current_jsonl_file=""
removed_line=""
project_files=()
project_output_folder=""
current_file_index=0
state=""
framework_runner=""
number_of_changes=0
first_run=true

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

# REFACTOR-10: Configuration - Hardcoded paths make adding new frameworks difficult
# Consider:
# readonly FRAMEWORK_DIR="${root_dir}/frameworks"
# declare -A FRAMEWORK_RUNNERS=(
#     [pytest]="${FRAMEWORK_DIR}/pytest.sh"
#     [jest]="${FRAMEWORK_DIR}/jest.sh"
# )
# get_test_framework_runner() {
#     echo "${FRAMEWORK_RUNNERS[$1]}"
# }
get_test_framework_runner() {
    framework=$1

    if [[ "$framework" == "pytest" ]]; then
        echo "${root_dir}/pytest.sh"
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
        exit $E_MISSING_DIR
    fi
    if [ -z "$test_framework" ]; then
        echo "No test framework defined"
        exit $E_MISSING_FRAMEWORK
    fi
    if ! [ -d "$output_folder" ]; then
        echo "No output folder defined."
        exit $E_MISSING_DIR
    fi
}

state_remove_line_failed="state_remove_line_failed"
state_remove_line_success="state_remove_line_success"
state_run_runner="state_run_runner"
state_run_runner_failed="state_run_runner_failed"
state_run_runner_success="state_run_runner_success"
state_revert_remove="state_revert_remove"
state_unknown="state_unknown"
state_finished="state_finished"
state_remove_line="state_remove_line"

declare -A STATE_TRANSITIONS=(
    [$state_remove_line_success]=$state_run_runner
    [$state_remove_line_failed]=$state_finished
    [$state_run_runner_failed]=$state_revert_remove
    [$state_run_runner_success]=$state_remove_line
    [$state_finished]=$state_finished
    [$state_remove_line]=$state_remove_line
)

next_state() {
    local prev_state="$1"
    if [[ -z "$prev_state" ]]; then
        state="$state_unknown"
    else
        state="${STATE_TRANSITIONS[$prev_state]:-$state_unknown}"
    fi
}

get_next_file() {
    declare -a files=("${!1}")
    local next_index=$(( $2 + 1 ))

    local number_of_files=${#files[@]}
    if [[ "$next_index" -ge "$number_of_files" ]]; then
        return 1
    fi
    echo "${files[$next_index]}"
}

function move_on_to_next_file() {
    if ! current_file=$(get_next_file project_files[@] $current_file_index); then
        state="$state_remove_line_failed"
        log_info "No next file available"
        return 1
    else
        log_info "Moved on to next file $current_file"
    fi
    current_file_index=$((current_file_index + 1))
    current_line_number=1
    current_jsonl_file="${current_file}.jsonl"

    removed_line=$(${root_dir}/remove_line.sh "$current_line_number" "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}")
    remove_status=$?

    if [[ "$remove_status" -eq "$error_line_nr_negative" ]]; then
        state="$state_remove_line_failed"
        log_info "Removing failed $current_file: $removed_line"
        return 1
    fi

    return 0
}

# REFACTOR-3: Function Responsibilities - This function does too much:
# - Removes line
# - Handles file switching logic
# - Updates state
# - Increments counter
# Consider extracting file switching:
# switch_to_next_file() {
#     current_file=$(get_next_file project_files[@] $current_file_index)
#     [[ $? -eq 1 ]] && return 1
#     current_file_index=$((current_file_index + 1))
#     current_line_number=1
#     return 0
# }
# Then use in remove_line() for clearer separation of concerns
#
# REFACTOR-5: Magic Numbers - Exit codes 1, 2, 3 from remove_line.sh are unclear
# Define constants:
# readonly REMOVE_LINE_INVALID=1
# readonly REMOVE_LINE_EOF=2
# readonly REMOVE_LINE_ERROR=3
# Then use: if [[ "$remove_status" -eq "$REMOVE_LINE_INVALID" || ... ]]
#
remove_line() {
    log_info "Removing line: $current_line_number, $current_file"
    log_debug "$(cat "${project_output_folder}/${current_file}")"

    local error_line_nr_negative=1
    local error_line_nr_gt_max=2
    local error_line_already_removed=4
    local error_wrong_parameters=3

    removed_line=$(${root_dir}/remove_line.sh "$current_line_number" "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}")
    remove_status=$?

    log_debug "$(cat "${project_output_folder}/${current_file}")"

    if [[ "$remove_status" -eq "$error_line_nr_negative" || "$remove_status" -eq "$error_wrong_parameters" ]]; then
        log_info "Removing failed $current_file: $removed_line"
        state="$state_remove_line_failed"
        return 1
    elif [[ "$remove_status" -eq "$error_line_nr_gt_max" ]]; then
        state="$state_remove_line_failed"
        return 1
    elif [[ "$remove_status" -eq "$error_line_already_removed" ]]; then
        log_info "Removing already removed lines. Skipping."
        state="$state_remove_line_success"
        return 0
    fi

    log_info "Removed line successfully: $removed_line"
    number_of_changes=$((number_of_changes+1))
    state="$state_remove_line_success"
    return 0
}

run_runner() {
    log_info "Running $framework_runner"
    eval "$framework_runner $project_output_folder" > /dev/null 2>&1
    runner_state=$?
    if [[ "$runner_state" -ge 1 ]]; then
        state="$state_run_runner_failed"
        log_info "$framework_runner failed"
        return 1
    else
        state="$state_run_runner_success"
        log_info "$framework_runner success"
        return 0
    fi
}

revert_remove() {
    log_info "revert: $current_line_number, removed line: $removed_line, current file: $current_file, $current_jsonl_file"

    ${root_dir}/insert_line.sh $current_line_number "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}" > /dev/null 2>&1
    local revert_state=$?
    log_debug "revert state: $revert_state"
    log_debug "$(cat "${project_output_folder}/${current_file}")"
    if (( revert_state >= 1 )); then
        state="$state_finished"
        return 1
    else
        number_of_changes=$((number_of_changes-1))
        state="$state_remove_line"
        return 0
    fi
}

run_state() {
    if [[ "$state" == "$state_remove_line" ]]; then
        remove_line
    elif [[ "$state" == "$state_run_runner" ]]; then
        run_runner
    elif [[ "$state" == "$state_revert_remove" ]]; then
        log_debug "Line to revert: $removed_line"
        revert_remove
    fi
}

reset() {
    first_run=false
    number_of_changes=0
    current_file_index=0
    current_file=${project_files[0]}
    current_jsonl_file="${current_file}.jsonl"
}

main() {
    log_debug "Starting"
    check_parameters
    framework_runner=$(get_test_framework_runner "$test_framework")

    project_output_folder="${output_folder}/project"
    local project_files_file="${project_output_folder}/project.files"

    move_project_to_output_folder "$project_folder" "$project_output_folder"

    "${root_dir}/get_project_files.sh" "$project_output_folder" "${project_output_folder}/project.conf" "${project_files_file}"

    mapfile -t project_files < "${project_files_file}"
    for file in "${project_files[@]}" ; do
        ${root_dir}/jsonl_conv.sh encode "${project_output_folder}/$file" "${project_output_folder}/${file}.jsonl"
    done

    current_file=${project_files[$current_file_index]}
    current_jsonl_file="${current_file}.jsonl"

    first_run=true

    while [ "$first_run" = true ] || [ "$number_of_changes" -gt 0 ] ; do
        reset
        log_debug "current_file: $current_file"

        for file in "${project_files[@]}" ; do
            current_file=${file}
            current_jsonl_file="${current_file}.jsonl"
            local number_of_lines
            number_of_lines=$(jq -n '[inputs.line_number] | max' "${project_output_folder}/$current_jsonl_file")
            local line_nr=1
            while [ "$line_nr" -le "$number_of_lines" ]; do
                current_line_number=$line_nr
                remove_line
                if ! run_runner ; then
                    log_debug "Line to revert: $removed_line"
                    revert_remove
                fi
                line_nr=$((line_nr + 1))
            done
        done

        log_debug "number_of_changes: $number_of_changes"
    done

    log_info "Creating coverage.xml"
    ${root_dir}/to_cobertura.sh "${project_files_file}" "${project_output_folder}/coverage.xml"
    echo "done"

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main
fi
