#!/usr/bin/env bash
# Utility functions

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
