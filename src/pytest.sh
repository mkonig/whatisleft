#!/usr/bin/env bash

testfolder=$1
if [ -z "$testfolder" ]; then
    echo "No test folder defined."
    exit 1
elif ! [ -d "$testfolder" ]; then
    echo "Test folder does not exist."
    exit 1
fi

pytest $testfolder
