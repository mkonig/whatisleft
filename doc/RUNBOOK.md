# whatisleft Runbook

Development runbook for the whatisleft project.

Use `nix-shell` to enter the development environment with all dependencies.

## Table of Contents

- [Running whatisleft](#running-whatisleft)
- [Running Tests](#running-tests)
- [How to use this Runbook](#how-to-use-this-runbook)

## Running whatisleft

### Run on example project

```bash {"interpreter":"/usr/bin/env bash","name":"run-example","cwd":".."}
mkdir -p /tmp/whatisleft-output
src/whatisleft.sh pytest test/resources/pytest/project1 /tmp/whatisleft-output
```

## Running Tests

### Run all tests

```bash {"interpreter":"/usr/bin/env bash","name":"test-all","cwd":".."}
bats --pretty test/*.bats
```

## How to use this Runbook

This runbook is designed to be used with [Runme](https://runme.dev).

**VS Code:** Install the Runme extension, open this file, and click the play button next to any code block.

**Browser:** Run `code serve-web`, `code-server`, or `openvscode-server` and open the URL in your browser. Install the Runme extension to run commands.

**TUI:** Run `runme tui` for an interactive terminal interface.

**CLI:**

Run `runme` in the project root to get an interactive list of commands, or specify a command directly:

```bash {"interpreter":"/usr/bin/env bash","name":"runme-run"}
runme run --filename doc/RUNBOOK.md
```

Run a specific command by name:

```bash {"interpreter":"/usr/bin/env bash","name":"runme-run-named"}
runme run --filename doc/RUNBOOK.md "Run all tests"
```

List all available commands:

```bash {"interpreter":"/usr/bin/env bash","name":"runme-list"}
runme list --filename doc/RUNBOOK.md
```
