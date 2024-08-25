#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=insert_line

@test "insert_line.sh should return 1 if input file does not exists" {
    run -1 insert_line.sh 0 "test" "non_existing_file"
}
