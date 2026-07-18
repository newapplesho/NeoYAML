---
paths:
  - "src/NeoYAML-*/**/*.st"
---

# YAML 1.2 Knowledge (for implementing NeoYAMLWriter)

This file is **project-independent** — it can be copied as-is to any project
that emits YAML. It exists so that Claude Code does not guess at YAML syntax
when implementing the writer; when in doubt, defer to the primary source:
[YAML 1.2.2 Specification](https://yaml.org/spec/1.2.2/).

## Indentation

- Indentation is **significant** and must use **spaces only** — YAML forbids
  tabs for indentation (spec §6.1).
- Sibling nodes at the same nesting level must use the same indentation width.
- Block sequence entries (`- item`) may be indented at the same level as their
  parent mapping key, or indented further — pick one convention and apply it
  consistently across the writer.

## Block style vs. flow style

- **Block style** (the normal, human-readable form):
  ```yaml
  key: value
  list:
    - item1
    - item2
  ```
- **Flow style** (JSON-like, single line):
  ```yaml
  {a: 1, b: 2}
  [1, 2, 3]
  ```
- An empty mapping/sequence has no block form — it must be written in flow
  style: `{}` / `[]`.

## When a scalar must be quoted

A plain (unquoted) scalar is ambiguous or invalid when it:

- Starts with an indicator character: `- ? : , [ ] { } # & * ! | > ' " % @ ` `
- Contains `: ` (colon + space) or ` #` (space + hash) — these end a plain
  scalar mid-value.
- Has leading or trailing whitespace.
- Would otherwise be parsed as a **non-string type** by the schema in use —
  see "Reserved-looking scalars" below.
- Is the empty string (write `''` or `""`, not a bare nothing).

When unsure, prefer quoting (`'...'` for literal single-quoted, `"..."` for
double-quoted with escapes) over relying on plain-scalar rules.

## Reserved-looking scalars

YAML 1.1 and YAML 1.2 (Core Schema) disagree on which bare words parse as
booleans/null:

- YAML 1.2 Core Schema: only `true`/`false` (case-sensitive) are booleans,
  `null`/`~`/empty are null.
- YAML 1.1 (used by some parsers, e.g. PyYAML's default loader) additionally
  treats `yes`/`no`/`on`/`off`/`y`/`n`/`Y`/`N` (and case variants) as booleans.

Because the consuming parser is not guaranteed to be YAML-1.2-only, **quote
any string scalar whose bare form matches these reserved words**, plus
strings that look like numbers (e.g. `'123'`, `'1e10'`) when the source value
is actually a string, not a number.

## Null and boolean representation

- Write null as `null` (not `~`, for readability) unless a project decides
  otherwise.
- Write booleans as lowercase `true` / `false`.

## Multi-line string (block scalar) styles

- **Literal** (`|`): preserves newlines exactly as written.
  ```yaml
  key: |
    line one
    line two
  ```
- **Folded** (`>`): folds single newlines into spaces (blank lines become a
  newline).
  ```yaml
  key: >
    this becomes
    one line
  ```
- Chomping indicators change trailing-newline handling: `-` (strip, no final
  newline), `+` (keep all trailing newlines), default (keep exactly one).

## Document markers and comments

- `---` starts a new document; `...` ends one. Not required for a single
  top-level document, but useful when writing a stream of multiple documents.
- `#` starts a comment (to end of line). Comments are not part of the data
  model — a writer never needs to emit them for correctness.

## Key ordering

The YAML data model (a mapping) does **not** guarantee key order is
meaningful to a reader. `NeoYAMLWriter` should nonetheless emit keys in the
same order as the source structure (e.g. `Dictionary` iteration order, or an
explicit ordered structure), since stable, readable output is a usability
goal even though the spec does not require it.

## Out of scope (for now)

- Anchors (`&`) and aliases (`*`) for shared/cyclic structure — NeoJSON's own
  object model does not represent cycles, so the initial NeoYAMLWriter does
  not need to support them.
- Tags (`!!type`) beyond the implicit core schema types (string, number,
  boolean, null, mapping, sequence).
