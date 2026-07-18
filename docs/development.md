# Development

How to work on NeoYAML itself (a Pharo / Tonel project).

## Prerequisites

- macOS or Linux (Windows: load manually in the Pharo UI — see below)
- `make`, `curl`, `bash`

## One-time setup

Download a local Pharo image + VM into `pharo-local/` (git-ignored):

```bash
make setup
```

This fetches Pharo 13 via `get.pharo.org`. To use a different version, override
`PHARO_VERSION` (e.g. `make setup PHARO_VERSION=120`).

## Daily cycle

```bash
make load    # load (or reload) the project into pharo-local/Pharo.image
make test    # run all tests headless (JUnit XML), pattern NeoYAML.*
make ui      # open the Pharo GUI on the loaded image
make help    # list targets
```

Tonel `.class.st` files are **not live** until re-imported. After editing
source, run `make load` again (or reload via Iceberg in the UI) before
`make test`.

- `scripts/load-project.st` is the **single source of truth** for the
  Metacello load expression. Paste it into a Playground and press Ctrl+D to
  load manually (this is also the Windows path).
- `scripts/run-tests.st` runs the suite and prints a summary to the
  Transcript (handy inside the UI).

## Loading without the Makefile

In a Playground (any platform):

```smalltalk
Metacello new
    baseline: 'NeoYAML';
    repository: 'github://newapplesho/NeoYAML:main/src';
    load.
```

For a working copy, replace the repository with your local checkout:
`'tonel://', '<repository root>/src'`.

## CI

`.github/workflows/ci.yml` runs smalltalkCI on Pharo 12 and 13:

```bash
smalltalkci -s Pharo64-13 .smalltalk.ston
```

## Coding conventions

See [`.claude/rules/`](../.claude/rules/) — `pharo-syntax.md` (generic Pharo /
Tonel style), `yaml-spec.md` (YAML syntax knowledge), `testing.md`, and
`project-conventions.md` (this project's prefix, packages, dependencies, and
implementation policy). These are auto-loaded by Claude Code when editing.
