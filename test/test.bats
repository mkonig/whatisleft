#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

@test "Whatisleft with no project folder fails" {
    run -2 whatisleft.sh
    assert_output "No project folder defined."
}

@test "Move test project to output folder" {
    source whatisleft.sh
    output_folder=$(mktemp -d)
    run move_project_to_output_folder test/assets/pytest "$output_folder"
    assert_dir_exists "$output_folder"
    diff test/assets/pytest "$output_folder"
}

@test "Whatisleft with no specified test framework fails" {
    run -2 whatisleft.sh
}

@test "Whatisleft with no specified output_folder fails" {
    run -2 whatisleft.sh pytest test/pytest
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
    pytest.sh test/assets/pytest
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
    run -1 pytest.sh test/assets/pytest_failing
}

# bats test_tags=remove_line,insert_line
@test "Remove line and put it back" {
    tmp_remove_output_file=$(mktemp)
    tmp_insert_output_file=$(mktemp)
    last_line_number=$(wc -l < "test/assets/testfile.py")

    for current_line_number in 1 3 5 6 ${last_line_number}; do
        removed_line=$(remove_line.sh "$current_line_number" test/assets/testfile.py "$tmp_remove_output_file")
        run insert_line.sh "$current_line_number" "${removed_line}" "$tmp_remove_output_file" "$tmp_insert_output_file"
        diff "$tmp_insert_output_file" test/assets/testfile.py
    done
}

# bats test_tags=whatisleft
@test "whatisleft copies folder, run pytest and exit 1" {
    skip
    output_folder=$(mktemp -d)
    echo "$output_folder"
    run -1 whatisleft.sh pytest test/assets/pytest "$output_folder"

    run diff --exclude=__pycache__ --exclude=.pytest_cache -ru test/assets/pytest_whatisleft_output "$output_folder/project/"

    if [ "$status" -eq "1" ]; then
        echo "$output" | delta --paging never -s
        fail "Output of whatisleft is wrong."
    fi
}

# get_project_files

@test "get_project_files should create file with all project files in it." {
    output_file=$(mktemp)
    run get_project_files.sh test/assets/pytest "$output_file"
    assert_equal "$(cat "${output_file}")" "module.py"
}

@test "get_project_files should fail on wrong parameters" {
    run -1 get_project_files.sh
    assert_output "No project folder defined. No output folder defined."
    run -1 get_project_files.sh test/saee
    assert_output "Project folder does not exist. No output folder defined."
    run -1 get_project_files.sh test/assets/pytest
    assert_output "No output folder defined."
    some_folder_name=$(mktemp -u)
    run -1 get_project_files.sh test/saee "$some_folder_name"
    assert_output "Project folder does not exist."
    run -1 get_project_files.sh test/assets/pytest /dev
    assert_output "Output folder can not be created."
    run -1 get_project_files.sh test/saa /dev
    assert_output "Project folder does not exist. Output folder can not be created."
}

# get_test_framework_runner
@test "get_test_framework_runner returns pytest.sh for pytest" {
    source whatisleft.sh
    run get_test_framework_runner pytest
    assert_output "pytest.sh"
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
    current_line_number=1
    current_file=$(mktemp)
    echo "test" > "$current_file"
    remove_line
    assert_equal "$state" "$state_remove_line_success"
}

# bats test_tags=remove_line_func
@test "remove_line() sets state to failure when no next line could be found" {
    source whatisleft.sh
    local current_line_number=2
    local current_file
    current_file=$(mktemp)
    echo "test" > "$current_file"
    if remove_line; then
        fail "remove_line should not be successful"
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
@test "revert_remove() returns 0 and 'remove_line' on success" {
    source whatisleft.sh

    local current_file
    local current_line_number=2
    local removed_line="test"
    current_file=$(mktemp)
    echo "test" > "$current_file"
    revert_remove
    assert_equal $state $state_remove_line
    delta --paging never -s <(echo -e "test\ntest") "$current_file"
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
