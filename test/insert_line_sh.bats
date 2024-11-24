#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=insert_line

@test "insert_line.sh returns 1 if input file does not exists" {
    run -1 insert_line.sh 0 "test" "non_existing_file"
}

@test "insert_line.sh return 1 if not all parameters are given or some are invalid" {
    local input_file
    input_file=$(mktemp)
    run -1 insert_line.sh
    run -1 insert_line.sh 0 "test" "iaeie"
    run -1 insert_line.sh 0 "test" "$input_file"
    run -1 insert_line.sh 0 "test" "$input_file" "input_file"
    run -1 insert_line.sh "a" "test" "$input_file" "$input_file"
}

@test "insert_line.sh return 0 when insert was successful" {
    file=$(mktemp)
    echo -e "test1\ntest2\ntest3" > "$file"
    run -0 insert_line.sh 1 "test4" "$file" "$file"

    delta --paging never -s <(echo -e "test4\ntest1\ntest2\ntest3") "$file"
}

@test "insert_line.sh return 0 when inserting a line with leading spaces" {
    file=$(mktemp)
    echo -e "test1\ntest2\ntest3" > "$file"
    run -0 insert_line.sh 1 "   test" "$file" "$file"

    delta --paging never -s <(echo -e "   test\ntest1\ntest2\ntest3") "$file"
}

@test "insert_line.sh return 0 when inserting a empty line" {
    file=$(mktemp)
    echo -e "test1\ntest2\ntest3" > "$file"
    run -0 insert_line.sh 1 "" "$file" "$file"

    delta --paging never -s <(echo -e "\ntest1\ntest2\ntest3") "$file"
}
