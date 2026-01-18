#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

@test "get_project_files handles directly named files." {
    output_file=$(mktemp)
    project_folder=$(mktemp -d)
    touch "${project_folder}/file1.py"
    touch "${project_folder}/file2.py"

cat > "${project_folder}/project.conf" << EOF
file1.py
file2.py
EOF

    run get_project_files.sh "$project_folder" "$project_folder/project.conf" "$output_file"
    refute_output

expected_output=$(cat << EOF
file1.py
file2.py
EOF
)
    assert_files_equal "$output_file" <(echo "$expected_output")
}

@test "get_project_files uses gitignore like config file 2." {
    output_file=$(mktemp)
    project_folder=$(mktemp -d)
    mkdir "${project_folder}/subfolder"
    touch "${project_folder}/file1.py"
    touch "${project_folder}/file2.py"
    touch "${project_folder}/subfolder/file2.py"
    touch "${project_folder}/file2.txt"

cat > "${project_folder}/project.conf" << EOF
file*.py
**/file*.py
EOF

    run get_project_files.sh "$project_folder" "$project_folder/project.conf" "$output_file"
    refute_output

expected_output=$(cat << EOF
file1.py
file2.py
subfolder/file2.py
EOF
)
    assert_files_equal "$output_file" <(echo "$expected_output")
}

@test "get_project_files should fail on wrong parameters" {
    folder_not_existent_msg="Project folder does not exist."
    config_not_existent_msg="Project config does not exist."
    usage_msg="Usage: get_project_files.sh <project folder> <config> <output file>"

    run -1 get_project_files.sh
    assert_output "$usage_msg"

    run -1 get_project_files.sh "$non_existent_folder"
    assert_output "$usage_msg"

    run -1 get_project_files.sh "$non_existent_folder" "something"
    assert_output "$usage_msg"

    non_existent_config=$(mktemp -u)
    non_existent_folder=$(mktemp -ud)
    output_file=$(mktemp -u)

    run -1 get_project_files.sh "$non_existent_folder" "$non_existent_config" "$output_file"
    assert_output "$folder_not_existent_msg $config_not_existent_msg"
}
