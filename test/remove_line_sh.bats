#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup

    cp -r test/resources/* "$BATS_TEST_TMPDIR/"
}

# bats file_tags=remove_line

@test "Remove returns the removed line" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
    assert_output "import something"
}

@test "Remove returns the removed line with leading spaces" {
    tmp_file=$(mktemp)
    run remove_line.sh 4 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
    assert_output "    print(\"hi\")"
}

@test "Remove first line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
    diff "$tmp_file" test/resources/remove_first_line_output.py
    diff "${BATS_TEST_TMPDIR}/testfile.jsonl" test/resources/testfile_first_line_removed.jsonl
    assert_output "import something"
}

@test "Remove 3rd line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 3 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
    diff "$tmp_file" test/resources/remove_third_line_output.py
    diff "${BATS_TEST_TMPDIR}/testfile.jsonl" test/resources/testfile_third_line_removed.jsonl
    assert_output "def a_func():"
}

@test "Fail with 1 when removing non existing line number < 0" {
    tmp_file=$(mktemp)
    run -1 remove_line.sh -1 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
}

@test "Fail with 2 when removing non existing line number > line numbers of the file" {
    tmp_file=$(mktemp)
    run -2 remove_line.sh 20 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
}

@test "Fail with 4 when removing an already removed line" {
    tmp_file=$(mktemp)
    run -4 remove_line.sh 3 "${BATS_TEST_TMPDIR}/testfile_third_line_removed.jsonl" "$tmp_file"
}

@test "Fail with 5 when line is empty" {
    tmp_file=$(mktemp)
    run -5 remove_line.sh 5 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
}

@test "Fail with 6 when line is a comment" {
    tmp_file=$(mktemp)
    run -6 remove_line.sh 6 "${BATS_TEST_TMPDIR}/testfile.jsonl" "$tmp_file"
}

@test "Fail with 3 when not all parameters are given" {
    run -3 remove_line.sh 20 "test" ""
    run -3 remove_line.sh 20
    run -3 remove_line.sh 20 "test"
    run -3 remove_line.sh 20 ""
    run -3 remove_line.sh
}
