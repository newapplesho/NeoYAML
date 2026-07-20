# NeoYAML

A Pharo Smalltalk adapter library that converts between YAML text and the
same object shapes (`Dictionary`, `Array`/`OrderedCollection`, `Association`,
scalars) that [NeoJSON](https://github.com/svenvc/NeoJSON)'s
`NeoJSONWriter`/`NeoJSONReader` use — in both directions, via `NeoYAMLWriter`
and `NeoYAMLReader`.

Both the YAML writer and reader are implemented from scratch, with no
external YAML library dependency — NeoYAML depends only on NeoJSON itself.

## Commands

A `Makefile` wraps a local Pharo image in `pharo-local/` (see
[docs/development.md](docs/development.md)):

```bash
make setup   # one-time: download Pharo image + VM into pharo-local/
make load    # load/reload the project into the image
make test    # run the test suite (pattern NeoYAML.*)
make ui      # open the Pharo GUI
```

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

For more examples — multi-line strings, multi-document streams, round-tripping,
and a method summary — see [docs/usage.md](docs/usage.md).

## Architecture

See [docs/architecture.md](docs/architecture.md) for the layered structure
(scan / parse / construct), the read/write flows, and a reading
guide to the classes.

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

## Roadmap

See [ROADMAP.md](ROADMAP.md) for what's done, planned, and explicitly out
of scope.
