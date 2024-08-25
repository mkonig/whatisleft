#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=next_state

@test "next_state should return 'unknown' when passed no state" {
    source whatisleft.sh
    run next_state ""
    assert_output "unknown"
}

@test "next_state should return 'run_runner' when passed 'remove_line_success'" {
    source whatisleft.sh
    run next_state "remove_line_success"
    assert_output "run_runner"
}

@test "next_state should return 'remove_line' when passed 'run_runner_success'" {
    source whatisleft.sh
    run next_state "run_runner_success"
    assert_output "remove_line"
}

@test "next_state should return 'revert_remove' when passed 'run_runner_failed'" {
    source whatisleft.sh
    run next_state "run_runner_failed"
    assert_output "revert_remove"
}

@test "next_state should return 'unknown' when passed an unknown state" {
    source whatisleft.sh
    run next_state "unknown_gibberish"
    assert_output "unknown"
}

@test "next_state should return 'finished' when passed 'remove_line_failed'" {
    source whatisleft.sh
    run next_state "remove_line_failed"
    assert_output "finished"
}
