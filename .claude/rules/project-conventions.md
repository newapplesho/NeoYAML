---
paths:
  - "src/**/*.st"
---

# NeoYAML — Project Conventions

This file holds everything **specific to this project**. The other rules
files (`pharo-syntax.md`, `testing.md`, `yaml-spec.md`) are generic and
reusable; when starting a new Smalltalk library, copy those and rewrite only
this file.

## Class Prefix

| Prefix | Used by |
|--------|---------|
| `NeoYAML` | all classes in this library (`NeoYAMLWriter`, `NeoYAMLReader`, ...), mirroring the "Neo" family naming used by `NeoJSONWriter`/`NeoJSONReader` / `NeoCSVWriter` |

## Packages

| Package | Role |
|---------|------|
| `NeoYAML-Core` | `NeoYAMLWriter` (object → YAML text); `NeoYAMLReader`, a thin facade over the scan/parse packages below; `NeoYAMLConstructor`, the "construct" stage: node tree → final Dictionary/Array/scalar shapes |
| `NeoYAML-Core-Scan` | `NeoYAMLScanner` — the "scan" stage: source text → blank-line-preserving physical line records |
| `NeoYAML-Core-Parse` | `NeoYAMLParser`/`NeoYAMLNode` — the "parse" stage (syntactic analysis): line records → an untyped node tree |
| `BaselineOfNeoYAML` | Metacello baseline |
| `NeoYAML-Tests` | SUnit tests |

`NeoYAMLReader` is deliberately kept as a package-level facade over Scan and
Parse, whose one-way dependency (Scan → Parse) is visible in the project's
package/dependency graph, not just in a class comment. `NeoYAMLConstructor`
does not get its own package: it is a small finishing step over the exact
`NeoYAMLNode` shape Parse produces, with no reuse value of its own, so it
lives alongside `NeoYAMLReader`/`NeoYAMLWriter` in `NeoYAML-Core`.

## Dependencies

`BaselineOfNeoYAML` declares NeoJSON as an external Metacello dependency
(not assumed to be pre-loaded in the image), following the precedent in
`google-cloud-smalltalk`'s `BaselineOfGoogleCloud>>defineDependencies:`:

```smalltalk
spec
	baseline: 'NeoJSON'
	with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
```

## Implementation Policy: no external YAML library

Both `NeoYAMLWriter` and `NeoYAMLReader` are implemented **from scratch** —
this project does not depend on any third-party YAML library, keeping the
same minimal dependency footprint NeoJSON itself has.

- Study `NeoJSONWriter`'s dispatch over `Dictionary` / `Array` /
  `OrderedCollection` / `Association` / scalars as the reference for how
  `NeoYAMLWriter` should walk the same shapes; study `NeoJSONReader`'s
  `fromString:`/default `mapClass`/`listClass` behavior as the reference for
  `NeoYAMLReader`'s output shapes.
- For YAML syntax correctness (indentation, quoting, reserved words, block
  scalars), follow `.claude/rules/yaml-spec.md`.
- `NeoYAMLWriter` (in `NeoYAML-Core`) implements the write direction:
  `write:` converts an already-parsed NeoJSON-shaped object to a YAML
  `String`; `writeJSON:` is the end-to-end adapter that parses JSON text via
  `NeoJSONReader fromString:` first. Unsupported input types raise a plain
  `Error` (no custom exception hierarchy), per `.claude/rules/testing.md`'s
  `should: [...] raise: Error` pattern.
- `NeoYAMLReader` (in `NeoYAML-Core`) implements the read direction:
  `fromString:` mirrors `NeoJSONReader class>>fromString:` and parses
  exactly the block-style subset `NeoYAMLWriter` emits (line/indentation
  based, no general YAML grammar). See `ROADMAP.md` for what's covered vs.
  explicitly out of scope.

## Documentation Style

- In Japanese text, do not put a space between Japanese characters and Latin
  characters (English words, code, numbers) — e.g. `NeoJSONで`, `YAMLを`.
- Do not use `→`. Express references with `：` and connections with words
  like `と` / `して`.

## Reference Docs

- Architecture (layered structure, class relationships, read/write flows): `docs/architecture.md`
- Development workflow: `docs/development.md`
- Rules layout: `.claude/rules/README.md`
- Roadmap (done / planned / out of scope): `ROADMAP.md`
