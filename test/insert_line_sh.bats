#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=insert_line

@test "insert_line.sh returns 1 if input file does not exists" {
    run -1 insert_line.sh 0 "non_existing_file" "test"
}

@test "insert_line.sh return 1 if not all parameters are given or some are invalid" {
    local input_file
    input_file=$(mktemp)
    run -1 insert_line.sh
    run -1 insert_line.sh 0 "test" "$input_file"
    run -1 insert_line.sh 0 "test" "$input_file" "input_file"
    run -1 insert_line.sh "a" "test" "$input_file" "$input_file"
}

@test "insert_line.sh return 0 when insert was successful" {
    jsonl_file=$(mktemp)
    output_file=$(mktemp)
    printf '%s
    ' \
      '{"line":"test1","line_number":1,"state":"removed"}' \
      '{"line":"test2","line_number":2,"state":"normal"}' \
      '{"line":"test3","line_number":3,"state":"normal"}' > "$jsonl_file"

    run -0 insert_line.sh 1 "$jsonl_file" "$output_file"

    delta --paging never -s <(echo -e "test1\ntest2\ntest3") "$output_file"
}

@test "insert_line.sh return 1 when insert failed" {
    jsonl_file=$(mktemp)
    output_file=$(mktemp)
    printf '%s
    ' \
      '{"line":"test1","line_number":1,"state":"removed"}' \
      '{"line":"test2","line_number":2,"state":"normal"}' \
      '{"line":"test3","line_number":3,"state":"normal"}' > "$jsonl_file"

    run -1 insert_line.sh 4 "$jsonl_file" "$output_file"
}
