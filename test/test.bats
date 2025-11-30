#!/usr/bin/env bats

# REFACTOR-7: Testing Isolation - Tests source entire whatisleft.sh making them fragile
# and creating implicit dependencies on global state. Consider:
# 1. Extract testable functions to separate library files:
#    src/lib/state_machine.sh
#    src/lib/file_operations.sh
#    src/lib/test_runner.sh
# 2. Keep only orchestration logic in whatisleft.sh
# 3. Source specific lib files in tests instead of the entire main script
# 4. Use dependency injection for external dependencies (filesystem, test runner)
# This would enable:
#    - Unit testing individual functions in isolation
#    - Mocking dependencies
#    - Faster test execution
#    - More maintainable tests

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
    cp -r test/resources/* "$BATS_TEST_TMPDIR/"
}

@test "Whatisleft with no project folder fails" {
    run -2 whatisleft.sh
    assert_output "No project folder defined."
}

@test "Move test project to output folder" {
    source whatisleft.sh
    output_folder=$(mktemp -d)
    run move_project_to_output_folder test/resources/pytest/project1 "$output_folder"
    assert_dir_exists "$output_folder"
    diff test/resources/pytest/project1 "$output_folder"
}

@test "Whatisleft with no specified test framework fails" {
    run -2 whatisleft.sh
}

@test "Whatisleft with no specified output_folder fails" {
    run -2 whatisleft.sh pytest test/pytest/project1
}

@test "validate_test_framework fails if test framework not in list" {
    source whatisleft.sh
    run -1 validate_test_framework invalid_test_framework
    assert_output '"invalid_test_framework" is not a supported test framework.'
}

@test "validate_test_framework does not fail if test framework is in list" {
    source whatisleft.sh
    run -0 validate_test_framework pytest
}

# pytest.sh

# bats test_tags=pytest_runner
@test "Run pytest.sh" {
    pytest.sh test/resources/pytest/project1
}

# bats test_tags=pytest_runner
@test "Pytest.sh with invalid test folder fails" {
    run -2 pytest.sh invalid_folder
    assert_output "Test folder does not exist."
}

# bats test_tags=pytest_runner
@test "Pytest.sh with no test folder fails" {
    run -2 pytest.sh
    assert_output "No test folder defined."
}

# bats test_tags=pytest_runner
@test "Pytest.sh should fail if pytest fails" {
    run -1 pytest.sh test/resources/pytest/failing_project1
}

# bats test_tags=remove_line,insert_line
@test "Remove line and put it back" {
    T=$BATS_TEST_TMPDIR
    tmp_decoded_file=$(mktemp)
    last_line_number=$(jq -n '[inputs.line_number] | max' "${T}/testfile.jsonl")
    cp "${T}/testfile.jsonl" "${T}/testfile.jsonl.orig"

    for line_number in 1 3 5 6 ${last_line_number}; do
        cp "${T}/testfile.jsonl.orig" "${T}/testfile.jsonl"
        remove_line.sh "$line_number" "${T}/testfile.jsonl" "$tmp_decoded_file"
        run -1 diff "$tmp_decoded_file" "${T}/testfile.py"

        run -0 insert_line.sh "$line_number" "${T}/testfile.jsonl" "$tmp_decoded_file"
        run -0 diff "$tmp_decoded_file" "${T}/testfile.py"
    done
}

# bats test_tags=whatisleft
@test "whatisleft runs until it does not do any more changes to the code" {
    skip
    output_folder=$(mktemp -d)
    echo "$output_folder"
    if whatisleft.sh pytest test/resources/pytest/project2 "$output_folder" ; then
        assert_equal $? 0
    else
        fail "whatisleft should return 0. It returned $?"
    fi

    run diff --exclude=__pycache__ --exclude=.pytest_cache -ru test/resources/pytest/project2_output "$output_folder/project/"

    if [ "$status" -eq "1" ]; then
        echo "$output" | delta --paging never -s
        fail "Output of whatisleft is wrong."
    fi
}
# bats test_tags=whatisleft
@test "whatisleft copies folder, run pytest and exit 0" {
    skip
    output_folder=$(mktemp -d)
    echo "$output_folder"
    if whatisleft.sh pytest test/resources/pytest/project1 "$output_folder" ; then
        assert_equal $? 0
    else
        fail "whatisleft should return 0. It returned $?"
    fi

    run diff --exclude=__pycache__ --exclude=.pytest_cache -ru test/resources/pytest/project1_output "$output_folder/project/"

    if [ "$status" -eq "1" ]; then
        echo "$output" | delta --paging never -s
        fail "Output of whatisleft is wrong."
    fi
}

# get_test_framework_runner
# bats test_tags=get_next_file
@test "get_test_framework_runner returns pytest.sh for pytest" {
    source whatisleft.sh
    run get_test_framework_runner pytest
    assert_output "src/pytest.sh"
}

@test "get_test_framework_runner should fail if framework not found" {
    source whatisleft.sh
    run -1 get_test_framework_runner missing_runner
}

# bats test_tags=get_next_file
@test "get_next_file returns 1 if no next file exists" {
    source whatisleft.sh
    local file_array=("file1" "file2" "file3")
    local current_file_index=2
    run -1 get_next_file file_array[@] $current_file_index
    assert_output ""

}

# bats test_tags=get_next_file
@test "get_next_file returns next file in list if exists" {
    source whatisleft.sh
    local file_array=("file1" "file2" "file3")
    local current_file_index=0
    run -0 get_next_file file_array[@] $current_file_index
    assert_output "file2"
}

# bats test_tags=remove_line_func
@test "remove_line() sets state to success when a next line could be found" {
    source whatisleft.sh
    line_number=1
    current_file=$(mktemp)
    echo "test" > "$current_file"
    current_jsonl_file="${current_file}.jsonl"
    run -0 jsonl_conv.sh encode "${current_file}" "${current_jsonl_file}"

    remove_line
    assert_equal "$state" "$state_remove_line_success"
}

# bats test_tags=remove_line_func
@test "remove_line() sets state to failure when no next line could be found" {
    source whatisleft.sh
    local current_line_number=2
    local current_file
    local current_jsonl_file
    current_file=$(mktemp)
    echo "test" > "$current_file"
    current_jsonl_file="${current_file}.jsonl"
    run -0 jsonl_conv.sh encode "${current_file}" "${current_jsonl_file}"

    if remove_line; then
        fail "remove_line() should not be successful"
    else
        assert_equal $? 1
    fi
    assert_equal $state $state_remove_line_failed
}

# bats test_tags=run_runner_func
@test "run_runner() returns 0 und 'run_runner_success' if runner passed" {
    source whatisleft.sh
    framework_runner="ls"
    run_runner
    assert_equal $state $state_run_runner_success
}

# bats test_tags=run_runner_func
@test "run_runner() returns 1 and 'run_runner_failed' if runner fails" {
    source whatisleft.sh
    framework_runner="lls"
    if run_runner ; then
        fail "run_runner should not be successful"
    else
        assert_equal $? 1
    fi
    assert_equal $state $state_run_runner_failed
}

# bats test_tags=revert_remove_func
@test "revert_remove() returns 0 and state_remove_line and increments current_line_number on success" {
    source whatisleft.sh

    local current_file
    local current_jsonl_file
    local current_line_number=2
    local removed_line="test"
    current_file=$(mktemp)
    current_jsonl_file="${current_file}.jsonl"
    printf '%s
    ' \
      '{"line":"test1","line_number":1,"state":"normal"}' \
      '{"line":"test2","line_number":2,"state":"removed"}' > "$current_jsonl_file"

    revert_remove
    assert_equal $state $state_remove_line
    assert_equal 3 $current_line_number
    delta --paging never -s <(echo -e "test1\ntest2") "$current_file"
}

# bats test_tags=revert_remove_func
@test "revert_remove() returns 1 and 'finished' on failure" {
    source whatisleft.sh

    local current_line_number=2
    local removed_line="test"
    local current_file="gibberish"

    if revert_remove ; then
        fail "revert_remove should not succeed"
    else
        assert_equal $? 1
    fi
    assert_equal $state $state_finished
}
