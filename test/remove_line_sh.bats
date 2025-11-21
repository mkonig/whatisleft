#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=remove_line

@test "Remove returns the removed line" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 test/resources/testfile.py "$tmp_file"
    assert_output "# python comment"
}

@test "Remove returns the removed line with leading spaces" {
    tmp_file=$(mktemp)
    run remove_line.sh 6 test/resources/testfile.py "$tmp_file"
    assert_output "    print(\"hi\")"
}

@test "Output file same as input file" {
    tmp_file=$(mktemp)
    cp test/resources/testfile.py "$tmp_file"
    run remove_line.sh 1 "$tmp_file" "$tmp_file"
    delta --paging never -s "$tmp_file" test/resources/remove_first_line_output.py
    assert_output "# python comment"
}

@test "Remove first line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 test/resources/testfile.py "$tmp_file"
    diff "$tmp_file" test/resources/remove_first_line_output.py
    assert_output "# python comment"
}

@test "Remove 3rd line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 3 test/resources/testfile.py "$tmp_file"
    diff "$tmp_file" test/resources/remove_third_line_output.py
    assert_output "import something"
}

@test "Fail with 1 when removing non existing line number < 0" {
    tmp_file=$(mktemp)
    run -1 remove_line.sh -1 test/resources/testfile.py "$tmp_file"
}

@test "Fail with 2 when removing non existing line number > line numbers of the file" {
    tmp_file=$(mktemp)
    run -2 remove_line.sh 20 test/resources/testfile.py "$tmp_file"
}

@test "Fail with 3 when not all parameters are given" {
    run -3 remove_line.sh 20
    run -3 remove_line.sh 20 "test"
    run -3 remove_line.sh 20 ""
    run -3 remove_line.sh 20 "test" ""
    run -3 remove_line.sh
}
