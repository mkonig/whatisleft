#!/usr/bin/env bash

testfolder=$1
if [ -z "$testfolder" ]; then
    echo "No test folder defined."
    exit 2
elif ! [ -d "$testfolder" ]; then
    echo "Test folder does not exist."
    exit 2
fi

bats "$testfolder"/test/jsonl_conv.bats
