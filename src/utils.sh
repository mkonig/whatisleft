#!/usr/bin/env bash

# REFACTOR-9: Logging Calls - Consider lazy evaluation to avoid executing commands
# when debug level is not enabled. The logging function could check log level
# before evaluating the message parameter:
# log_debug() {
#     if [[ "${DEBUG_ENABLED:-0}" == "1" ]]; then
#         logging "debug" "${1}"
#     fi
# }
# Or move the check to the logging function itself to avoid evaluating
# expensive command substitutions in the caller

# shellcheck disable=SC2154
logging() {
    local level=$1
    local message=$2
    gum log -o whatisleft.log -t rfc822 -l "${level}" "${message}"
}

log_debug() {
    logging "debug" "${1}"
}

log_error() {
    logging "error" "${1}"
}

log_warning() {
    logging "warn" "${1}"
}

log_info(){
    logging "info" "${1}"
}
