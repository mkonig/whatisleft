#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$DIR/../src:$PATH"
}

@test "Remove first line of file" {
    tmp_file=$(mktemp)
    ./src/remove_line.sh 1 test/assets/testfile.py $tmp_file
    diff $tmp_file test/assets/remove_first_line_output.py
}

@test "Run pytest" {
    run pytest.sh test/python
    echo $output
    [ $status -eq 0 ]
}

@test "Pytest.sh with no testfolder should fail" {
    run pytest.sh
    assert_output "No testfolder given."
    # [ $status -ne 0 ]
}
