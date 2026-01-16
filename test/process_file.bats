#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup

    cp -r test/resources/* "$BATS_TEST_TMPDIR/"
}

# bats file_tags=process_file

# @test "Iterate line by line" {
# }
