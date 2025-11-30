#!/usr/bin/env bash

# REFACTOR-2: Error Handling Consistency - Use standardized error codes
# readonly E_SUCCESS=0
# readonly E_INVALID_ARGS=1
# readonly E_DIR_NOT_FOUND=2

testfolder=$1
if [ -z "$testfolder" ]; then
    echo "No test folder defined."
    exit 2
elif ! [ -d "$testfolder" ]; then
    echo "Test folder does not exist."
    exit 2
fi

pytest "$testfolder"
