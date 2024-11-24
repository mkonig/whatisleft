#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=next_state

@test "next_state returns state_unknown when passed no state" {
    source whatisleft.sh
    run next_state ""
    assert_output $state_unknown
}

@test "next_state returns state_run_runner when passed state_remove_line_success" {
    source whatisleft.sh
    run next_state $state_remove_line_success
    assert_output $state_run_runner
}

@test "next_state returns state_remove_line when passed state_run_runner_success" {
    source whatisleft.sh
    run next_state $state_run_runner_success
    assert_output $state_remove_line
}

@test "next_state returns state_revert_remove when passed state_run_runner_failed" {
    source whatisleft.sh
    run next_state $state_run_runner_failed
    assert_output $state_revert_remove
}

@test "next_state returns state_unknown when passed an unknown state" {
    source whatisleft.sh
    run next_state "unknown_gibberish"
    assert_output $state_unknown
}

@test "next_state returns state_finished when passed state_remove_line_failed" {
    source whatisleft.sh
    run next_state $state_remove_line_failed
    assert_output $state_finished
}

@test "next_state returns state_finished when passed state_finished" {
    source whatisleft.sh
    run next_state $state_finished
    assert_output $state_finished
}
