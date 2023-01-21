#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/bats-support/load"
    load "test_helper/bats-assert/load"
    load "test_helper/bats-file/load"
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "Whatisleft with no project folder should fail" {
    run -1 whatisleft.sh
    assert_output "No project folder defined."
}

@test "Move test project to tmp folder" {
    source whatisleft.sh
    run move_project_to_tmp_folder test/pytest
    assert_dir_exists "$output"
    diff test/pytest "$output"
}

@test "Whatisleft with no specified test framework should fail" {
    run -1 whatisleft.sh
}

@test "validate_test_framework should fail if test framework not in list" {
    source whatisleft.sh
    run -1 validate_test_framework invalid_test_framework
    assert_output '"invalid_test_framework" is not a supported test framework.'
}

@test "validate_test_framework should not fail if test framework is in list" {
    source whatisleft.sh
    run validate_test_framework pytest
}

# pytest.sh

@test "Run pytest.sh" {
    pytest.sh test/pytest
}

@test "Pytest.sh with invalid test folder should fail" {
    run -1 pytest.sh invalid_folder
    assert_output "Test folder does not exist."
}

@test "Pytest.sh with no test folder should fail" {
    run -1 pytest.sh
    assert_output "No test folder defined."
}

@test "Pytest.sh should fail if pytest fails" {
    run -1 pytest.sh test/failing_pytest
}

# Test line removal

@test "Remove should return the removed line" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 test/assets/testfile.py "$tmp_file"
    assert_output "# python comment"
}

@test "Remove first line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 1 test/assets/testfile.py "$tmp_file"
    diff "$tmp_file" test/assets/remove_first_line_output.py
    assert_output "# python comment"
}

@test "Remove 3rd line of file" {
    tmp_file=$(mktemp)
    run remove_line.sh 3 test/assets/testfile.py "$tmp_file"
    diff "$tmp_file" test/assets/remove_third_line_output.py
    assert_output "import something"
}

@test "Fail when removing non existing line number < 0" {
    tmp_file=$(mktemp)
    run -1 remove_line.sh -1 test/assets/testfile.py "$tmp_file"
}

@test "Fail when removing non existing line number" {
    tmp_file=$(mktemp)
    run -1 remove_line.sh 20 test/assets/testfile.py "$tmp_file"
}

@test "Remove line and put it back" {
    tmp_file=$(mktemp)
}
