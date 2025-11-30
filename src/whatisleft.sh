#!/usr/bin/env bash

root_dir="src"
# shellcheck source=src/utils.sh
source "src/utils.sh"

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

# REFACTOR-8: Validation Logic - BUG: This function always exits on first iteration
# The else clause fires immediately on first comparison, even if there are more items to check
# Fix:
# validate_test_framework() {
#     local framework=$1
#     local valid_frameworks=("pytest")
#     for valid in "${valid_frameworks[@]}"; do
#         [[ "$framework" == "$valid" ]] && return 0
#     done
#     echo "\"${framework}\" is not a supported test framework."
#     return 1
# }
validate_test_framework() {
    local framework=$1
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
# REFACTOR-9: Logging Calls - Command substitution in log_debug executes even when not needed
# Wrap expensive debug calls:
# if [[ "${DEBUG:-0}" == "1" ]]; then
#     log_debug "$(cat "${project_output_folder}/${current_file}")"
# fi
remove_line() {
    log_debug "Removing line: $current_line_number, $current_file"
    log_debug "$(cat "${project_output_folder}/${current_file}")"

    removed_line=$(${root_dir}/remove_line.sh "$current_line_number" "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}")
    remove_status=$?
    log_info "Removed from $current_file: $removed_line"

    if [[ "$remove_status" -eq 1 || "$remove_status" -eq 3 ]]; then
        state="$state_remove_line_failed"
        return 1
    elif [[ "$remove_status" -eq 2 ]]; then
        current_file=$(get_next_file project_files[@] $current_file_index)
        get_next_file_status=$?
        if [[ "$get_next_file_status" -eq 1 ]]; then
            state="$state_remove_line_failed"
            return 1
        fi
        current_line_number=1
        removed_line=$(${root_dir}/remove_line.sh "$current_line_number" "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}")
        remove_status=$?
        if [[ "$remove_status" -eq 1 ]]; then
            state="$state_remove_line_failed"
            return 1
        fi
    fi

    log_debug "Removed line successfully: $removed_line"
    number_of_changes=$((number_of_changes+1))
    state="$state_remove_line_success"
    return 0
}

run_runner() {
    log_debug "Framework: $framework_runner"
    eval "$framework_runner $project_output_folder" > /dev/null 2>&1
    runner_state=$?
    if [[ "$runner_state" -ge 1 ]]; then
        state="$state_run_runner_failed"
        return 1
    else
        state="$state_run_runner_success"
        return 0
    fi
}

revert_remove() {
    log_debug "revert: $current_line_number ,removed line: $removed_line ,current file: $current_file"

    ${root_dir}/insert_line.sh $current_line_number "${project_output_folder}/${current_jsonl_file}" "${project_output_folder}/${current_file}" > /dev/null 2>&1
    local revert_state=$?
    log_debug "revert state: $revert_state"
    log_debug "$(cat "${project_output_folder}/${current_file}")"
    if (( revert_state >= 1 )); then
        state="$state_finished"
        return 1
    else
        number_of_changes=$((number_of_changes-1))
        current_line_number=$((current_line_number+1))
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
    current_line_number=1
    current_file=${project_files[0]}
}

main() {
    log_debug "Starting"
    check_parameters
    framework_runner=$(get_test_framework_runner "$test_framework")

    local project_files_file="${output_folder}/project.files"
    project_output_folder="${output_folder}/project"

    move_project_to_output_folder "$project_folder" "$project_output_folder"

    "${root_dir}/get_project_files.sh" "$project_output_folder" "${project_output_folder}/project.conf" "${project_files_file}"

    mapfile -t project_files < "${project_files_file}"
    current_file=${project_files[$current_file_index]}
    current_jsonl_file="${current_file}.jsonl"
    "${root_dir}/jsonl_conv.sh" encode "$current_file" "$current_jsonl_file"

    local first_run=true

    while [ "$first_run" = true ] || [ "$number_of_changes" -gt 0 ] ; do
        reset
        log_debug "current_file: $current_file"

        state="$state_remove_line"
        log_debug "start state: $state"
        while [ "$state" != "$state_finished" ] ; do
            log_debug "state: $state"
            run_state "$state"
            log_debug "state after run: $state"
            next_state "$state"
            log_debug "next state: $state"
        done

        log_debug "number_of_changes: $number_of_changes"
    done
    echo "done"

    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main
fi
