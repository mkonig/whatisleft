#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup

    cp -r test/resources/pytest/project1_output "$BATS_TEST_TMPDIR/"
}

# bats file_tags=cobertura

@test "Convert jsonl to cobertura xml" {
    skip
    run to_cobertura.sh "${BATS_TEST_TMPDIR}/project.conf" "${BATS_TEST_TMPDIR}/coverage.xml"
    diff test/resources/pytest/project1_output/coverage.xml "${BATS_TEST_TMPDIR}/coverage.xml"
}
