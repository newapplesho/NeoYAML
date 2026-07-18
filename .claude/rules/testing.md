---
paths:
  - "src/*-Tests/**/*.st"
---

# Testing Conventions

This file is **project-independent** — it can be copied as-is to any Pharo project.
Project-specific test fixtures are described in `project-conventions.md`.

## setUp / tearDown

Acquire shared fixtures in `setUp`; tests must be independent (no shared state
across test methods).

```smalltalk
NeoYAMLWriterTest >> setUp [
    super setUp.
    writer := NeoYAMLWriter new.
]
```

## No live network in unit tests

Unit tests must **never** make real HTTP calls or require credentials. The CI
runs offline. This project is a pure text-transformation library (NeoJSON
information → YAML text), so all tests are naturally offline: exercise the
writer/reader against literal Smalltalk objects and compare the resulting
YAML string.

## Test Method Naming

`test` + what is tested + expected outcome.

```
testWriteStringQuotesColon
testWriteDictionaryUsesBlockMapping
testWriteEmptyArrayUsesFlowStyle
```

## Assertions

```smalltalk
self assert: x equals: y.          "prefer over assert: (x = y)"
self assert: x.
self deny: x.
self assert: (yaml includesSubstring: 'key: value').
self should: [ writer write: aCyclicObject ] raise: Error.
```

Prefer `assert:equals:` over `assert: (x = y)` — gives better failure messages.

## Round-trip pattern

When testing serialization, prefer comparing structured results over raw
strings where possible (e.g. re-parsing YAML, or comparing against a NeoJSON
round-trip of the same input) since formatting details (line wrapping,
quoting choice) can be legitimate implementation freedom as long as the
semantic content is unchanged.
