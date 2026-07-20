# NeoYAML

[![ci](https://github.com/newapplesho/NeoYAML/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/newapplesho/NeoYAML/actions/workflows/ci.yml)

A Pharo Smalltalk adapter library that converts between YAML text and the
same object shapes (`Dictionary`, `Array`/`OrderedCollection`, `Association`,
scalars) that [NeoJSON](https://github.com/svenvc/NeoJSON)'s
`NeoJSONWriter`/`NeoJSONReader` use — in both directions, via `NeoYAMLWriter`
and `NeoYAMLReader`.

Both the YAML writer and reader are implemented from scratch, with no
external YAML library dependency — NeoYAML depends only on NeoJSON itself.

## Requirements

| Smalltalk | Version |
|-----------|---------|
| [Pharo](https://pharo.org/) | 12.0, 13.0 |

The only dependency is [NeoJSON](https://github.com/svenvc/NeoJSON), which the
baseline loads for you.

## Installation

```smalltalk
Metacello new
  baseline: 'NeoYAML';
  repository: 'github://newapplesho/NeoYAML:main/src';
  load.
```

To work from a local checkout instead, point the repository at it:
`'tonel://', '<repository root>/src'`.

## Usage

```smalltalk
NeoYAMLWriter writeJSON: '{"name":"Pharo","tags":["smalltalk","yaml"]}'.
```

produces:

```yaml
name: Pharo
tags:
  - smalltalk
  - yaml
```

`NeoYAMLWriter write: anObject` converts an already-parsed NeoJSON-shaped
object (`Dictionary`, `Array`/`OrderedCollection`, `Association`, or a
scalar) directly, without going through JSON text.

The other direction:

```smalltalk
NeoYAMLReader fromString: 'name: Pharo' , String lf , 'tags:' , String lf , '  - smalltalk'.
```

produces a `Dictionary` equivalent to what `NeoJSONReader` would build from
the corresponding JSON — `NeoYAMLReader` covers exactly the block-style
subset `NeoYAMLWriter` emits (see [ROADMAP.md](ROADMAP.md) for what's out
of scope).

The same conversions are reachable from NeoJSON's own classes, so you do not
have to name `NeoYAMLWriter`/`NeoYAMLReader`:

```smalltalk
NeoJSONWriter toYAML: aDictionary.
NeoJSONReader fromYAML: 'key: value'.
NeoJSONObject fromYAML: 'name: Pharo'.   "message-style access: obj name"
```

For more examples — multi-line strings, multi-document streams, round-tripping,
and a method summary — see [docs/usage.md](docs/usage.md).

## Documentation

- [Usage](docs/usage.md) — multi-line strings, multi-document streams,
  round-tripping, and a method summary
- [Architecture](docs/architecture.md) — the scan / parse / construct pipeline
  and the read/write flows ([日本語](docs/architecture.ja.md))
- [Parser](docs/parser.md) — how syntactic analysis is implemented
  ([日本語](docs/parser.ja.md))
- [Development](docs/development.md) — building and testing the library in Pharo
- [Roadmap](ROADMAP.md) — done, planned, and out of scope

## Packages

| Package | Role |
|---------|------|
| `NeoYAML-Core` | `NeoYAMLWriter` (object → YAML text); `NeoYAMLReader`, a thin facade over the two packages below; `NeoYAMLConstructor`, turning a node tree into the final Dictionary/Array/scalar shapes |
| `NeoYAML-Core-Scan` | `NeoYAMLScanner` — turns YAML source text into blank-line-preserving physical line records |
| `NeoYAML-Core-Parse` | `NeoYAMLParser`/`NeoYAMLNode` — the parse stage, building an untyped node tree |
| `BaselineOfNeoYAML` | Metacello baseline |
| `NeoYAML-Tests` | SUnit tests |

`fixtures/` holds standalone `.yaml` files read from disk by
`NeoYAMLFixtureTest`, covering the disk-read path alongside the inline
string literals `NeoYAMLReaderTest`/`NeoYAMLWriterTest` use. It lives
outside `src/` since Tonel does not define any handling for non-`.st` files
inside a package directory.

## Development

This is a Pharo / Tonel project. With a local Pharo image (`make setup`):

```bash
make load    # load/reload the project into the image
make test    # run the test suite (pattern NeoYAML.*)
make ui      # open the Pharo GUI
```

See [docs/development.md](docs/development.md) for the full workflow.
