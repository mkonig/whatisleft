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

log_level_info=0
log_level_error=1
log_level_warning=2
log_level_debug=3

log_level=$log_level_debug

# shellcheck disable=SC2154
logging() {
    local level=$1
    local message=$2

    if (( level > log_level )) ; then
        return
    fi

    case $level in
        "$log_level_info")
            level_text="info" ;;
        "$log_level_debug")
            level_text="debug" ;;
        "$log_level_warning")
            level_text="warning";;
        "$log_level_error")
            level_text="error";;
    esac
    gum log -s -o whatisleft.log -t rfc822 -l "${level_text}" "${message}"
}

log_debug() {
    logging $log_level_debug "${1}"
}

log_error() {
    logging $log_level_error "${1}"
}

log_warning() {
    logging $log_level_warning "${1}"
}

log_info(){
    logging $log_level_info "${1}"
}
