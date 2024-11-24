#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    load "test_helper/common-setup"
    _common_setup
}

# bats file_tags=next_state

@test "next_state sets state to state_unknown when passed no state" {
    source whatisleft.sh
    next_state ""
    assert_equal "$state" "$state_unknown"
}

@test "next_state sets state to state_run_runner when passed state_remove_line_success" {
    source whatisleft.sh
    next_state $state_remove_line_success
    assert_equal "$state" "$state_run_runner"
}

@test "next_state sets state to state_remove_line when passed state_run_runner_success" {
    source whatisleft.sh
    next_state $state_run_runner_success
    assert_equal "$state" "$state_remove_line"
}

@test "next_state sets state to state_revert_remove when passed state_run_runner_failed" {
    source whatisleft.sh
    next_state $state_run_runner_failed
    assert_equal "$state" $state_revert_remove
}

@test "next_state sets state to state_unknown when passed an unknown state" {
    source whatisleft.sh
    next_state "unknown_gibberish"
    assert_equal "$state" $state_unknown
}

@test "next_state sets state to state_finished when passed state_remove_line_failed" {
    source whatisleft.sh
    next_state $state_remove_line_failed
    assert_equal "$state" $state_finished
}

@test "next_state sets state to state_finished when passed state_finished" {
    source whatisleft.sh
    next_state $state_finished
    assert_equal "$state" $state_finished
}

@test "next_state sets state to state_remove_line when passed state_remove_line" {
    source whatisleft.sh
    next_state $state_remove_line
    assert_equal "$state" $state_remove_line
}
