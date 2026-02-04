#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
    T=$BATS_TEST_TMPDIR
}

assert_json_equal() {
    local actual="$1"
    local expected="$2"
    local actual_sorted expected_sorted
    actual_sorted=$(echo "$actual" | jq -Sc '.')
    expected_sorted=$(echo "$expected" | jq -Sc '.')
    assert_equal "$actual_sorted" "$expected_sorted"
}

assert_jsonl_line() {
    local file="$1"
    local line_num="$2"
    local expected="$3"
    local actual
    actual=$(sed -n "${line_num}p" "$file")
    assert_json_equal "$actual" "$expected"
}

assert_jsonl_file_equal() {
    local actual_file="$1"
    local expected_file="$2"
    local actual_sorted expected_sorted
    actual_sorted=$(jq -Sc '.' "$actual_file" | sort)
    expected_sorted=$(jq -Sc '.' "$expected_file" | sort)
    assert_equal "$actual_sorted" "$expected_sorted"
}

@test "Fails with exit code 1 when command missing" {
    run -1 jsonl_conv.sh
}

@test "Fails with exit code 4 when command is invalid" {
    echo "test" > "$T/input.txt"
    run -4 jsonl_conv.sh invalid "$T/input.txt" "$T/output.txt"
}

# bats file_tags=encode

@test "Converts single line file to jsonl" {
    echo "hello world" > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_json_equal "$(cat "$T/output.jsonl")" '{"line":"hello world","line_number":1,"state":"normal"}'
}

@test "Converts multi-line file to jsonl with correct line numbers" {
    printf "first\nsecond\nthird\n" > "$T/input.txt"
    cat > "$T/expected.jsonl" << 'EOF'
{"line":"first","line_number":1,"state":"normal"}
{"line":"second","line_number":2,"state":"normal"}
{"line":"third","line_number":3,"state":"normal"}
EOF
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_jsonl_file_equal "$T/output.jsonl" "$T/expected.jsonl"
}

@test "Preserves leading whitespace in line content" {
    printf "    indented line\n" > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_json_equal "$(cat "$T/output.jsonl")" '{"line":"    indented line","line_number":1,"state":"normal"}'
}

@test "Handles empty lines" {
    printf "line1\n\nline3\n" > "$T/input.txt"
    cat > "$T/expected.jsonl" << 'EOF'
{"line":"line1","line_number":1,"state":"normal"}
{"line":"","line_number":2,"state":"ignore"}
{"line":"line3","line_number":3,"state":"normal"}
EOF
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_jsonl_file_equal "$T/output.jsonl" "$T/expected.jsonl"
}

@test "Escapes double quotes in line content" {
    echo 'say "hello"' > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_json_equal "$(cat "$T/output.jsonl")" '{"line":"say \"hello\"","line_number":1,"state":"normal"}'
}

@test "Escapes backslashes in line content" {
    echo 'path\to\file' > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_json_equal "$(cat "$T/output.jsonl")" '{"line":"path\\to\\file","line_number":1,"state":"normal"}'
}

@test "Defaults to normal state when no state parameter given" {
    echo "a line" > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_json_equal "$(cat "$T/output.jsonl")" '{"line":"a line","line_number":1,"state":"normal"}'
}

# bats test_tags=encode,error
@test "encode: Fails with exit code 1 when input file missing" {
    run -1 jsonl_conv.sh encode
}

# bats test_tags=encode,error
@test "encode: Fails with exit code 1 when output file missing" {
    run -1 jsonl_conv.sh encode "$T/input.txt"
}

# bats test_tags=encode,error
@test "encode: Fails with exit code 2 when input file does not exist" {
    run -2 jsonl_conv.sh encode "$T/nonexistent.txt" "$T/output.jsonl"
}

@test "Handles empty input file" {
    touch "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    assert_equal "$(cat "$T/output.jsonl")" ""
}

@test "Output file has same number of lines as input file" {
    printf "one\ntwo\nthree\nfour\nfive\n" > "$T/input.txt"
    run -0 jsonl_conv.sh encode "$T/input.txt" "$T/output.jsonl"
    input_lines=$(wc -l < "$T/input.txt")
    output_lines=$(wc -l < "$T/output.jsonl")
    assert_equal "$output_lines" "$input_lines"
}

@test "Converts python file correctly" {
    printf '# python comment\n\nimport something\n\ndef a_func():\n    print("hi")\n' > "$T/testfile.py"
    cat > "$T/expected.jsonl" << 'EOF'
{"line":"# python comment","line_number":1,"state":"ignore"}
{"line":"","line_number":2,"state":"ignore"}
{"line":"import something","line_number":3,"state":"normal"}
{"line":"","line_number":4,"state":"ignore"}
{"line":"def a_func():","line_number":5,"state":"normal"}
{"line":"    print(\"hi\")","line_number":6,"state":"normal"}
EOF
    run -0 jsonl_conv.sh encode "$T/testfile.py" "$T/output.jsonl"
    assert_jsonl_file_equal "$T/output.jsonl" "$T/expected.jsonl"
}

# bats file_tags=decode

@test "Converts single line jsonl to text" {
    echo '{"line":"hello world","line_number":1,"state":"normal"}' > "$T/input.jsonl"
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" "hello world"
}

@test "Converts multi-line jsonl to text" {
    cat > "$T/input.jsonl" << 'EOF'
{"line":"first","line_number":1,"state":"normal"}
{"line":"second","line_number":2,"state":"normal"}
{"line":"third","line_number":3,"state":"normal"}
EOF
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    printf "first\nsecond\nthird\n" > "$T/expected.txt"
    diff "$T/output.txt" "$T/expected.txt"
}

@test "Excludes lines with deleted state" {
    cat > "$T/input.jsonl" << 'EOF'
{"line":"keep1","line_number":1,"state":"normal"}
{"line":"remove","line_number":2,"state":"deleted"}
{"line":"keep2","line_number":3,"state":"normal"}
EOF
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    printf "keep1\nkeep2\n" > "$T/expected.txt"
    diff "$T/output.txt" "$T/expected.txt"
}

@test "Preserves leading whitespace" {
    echo '{"line":"    indented","line_number":1,"state":"normal"}' > "$T/input.jsonl"
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" "    indented"
}

@test "decode: Handles empty lines" {
    cat > "$T/input.jsonl" << 'EOF'
{"line":"line1","line_number":1,"state":"normal"}
{"line":"","line_number":2,"state":"ignore"}
{"line":"line3","line_number":3,"state":"normal"}
EOF
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    printf "line1\n\nline3\n" > "$T/expected.txt"
    diff "$T/output.txt" "$T/expected.txt"
}

@test "Unescapes double quotes" {
    echo '{"line":"say \"hello\"","line_number":1,"state":"normal"}' > "$T/input.jsonl"
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" 'say "hello"'
}

@test "Unescapes backslashes" {
    echo '{"line":"path\\to\\file","line_number":1,"state":"normal"}' > "$T/input.jsonl"
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" 'path\to\file'
}

@test "Excludes all removed lines" {
    cat > "$T/input.jsonl" << 'EOF'
{"line":"del1","line_number":1,"state":"removed"}
{"line":"del2","line_number":2,"state":"removed"}
EOF
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" ""
}

@test "decode: Handles empty input file" {
    touch "$T/input.jsonl"
    run -0 jsonl_conv.sh decode "$T/input.jsonl" "$T/output.txt"
    assert_equal "$(cat "$T/output.txt")" ""
}

# bats test_tags=decode,error
@test "decode: Fails with exit code 1 when input file missing" {
    run -1 jsonl_conv.sh decode
}

# bats test_tags=decode,error
@test "decode: Fails with exit code 1 when output file missing" {
    run -1 jsonl_conv.sh decode "$T/input.jsonl"
}

# bats test_tags=decode,error
@test "decode: Fails with exit code 2 when input file does not exist" {
    run -2 jsonl_conv.sh decode "$T/nonexistent.jsonl" "$T/output.txt"
}
