# Usage

A practical guide to converting between NeoJSON's object shapes and YAML text
with `NeoYAMLWriter` (write direction) and `NeoYAMLReader` (read direction).
For the design behind these classes, see [architecture.md](architecture.md);
for exactly which YAML features are covered, see
[`ROADMAP.md`](../ROADMAP.md) and the classes' own comments.

## The object model

Both directions speak the same object shapes `NeoJSONWriter`/`NeoJSONReader`
use, so a YAML step can be swapped in wherever a JSON step was:

| YAML construct        | Pharo object                              |
|-----------------------|-------------------------------------------|
| mapping (`key: value`)| `Dictionary`                              |
| sequence (`- item`)   | `Array` / `OrderedCollection`             |
| key/value pair        | `Association`                             |
| string                | `String`                                  |
| number                | `Integer` / `Float`                       |
| boolean               | `true` / `false`                          |
| null                  | `nil`                                     |

## Writing YAML

### From a JSON string

`writeJSON:` parses JSON text with `NeoJSONReader` first, then emits YAML —
an end-to-end JSON-to-YAML conversion:

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

### From an already-built object

`write:` takes a NeoJSON-shaped object directly, without going through JSON
text:

```smalltalk
NeoYAMLWriter write: (Dictionary new
    at: 'name' put: 'Pharo';
    at: 'version' put: 13;
    at: 'stable' put: true;
    yourself).
```

produces:

```yaml
name: Pharo
version: 13
stable: true
```

Mapping keys are emitted in the source object's iteration order. Scalars are
quoted only when a plain form would be ambiguous — e.g. the string `'123'` is
written quoted so it does not read back as the number `123`.

### A multi-line string value

A string containing a newline, when nested inside a mapping or sequence, is
written as a literal block scalar (`|` / `|-`) rather than an escaped
double-quoted scalar:

```smalltalk
NeoYAMLWriter write: (Dictionary new
    at: 'note' put: 'line one', String lf, 'line two';
    yourself).
```

produces:

```yaml
note: |-
  line one
  line two
```

### Multiple documents

`writeAll:` writes each element of a collection as its own YAML document,
separated by `---`:

```smalltalk
NeoYAMLWriter writeAll: {
    (Dictionary new at: 'id' put: 1; yourself).
    (Dictionary new at: 'id' put: 2; yourself) }.
```

produces:

```yaml
id: 1
---
id: 2
```

## Reading YAML

### A single document

`fromString:` parses one YAML document into the equivalent object — the same
`Dictionary` that `NeoJSONReader` would build from the corresponding JSON:

```smalltalk
NeoYAMLReader fromString: 'name: Pharo', String lf, 'tags:', String lf, '  - smalltalk'.
```

returns a `Dictionary` equivalent to:

```smalltalk
Dictionary new
    at: 'name' put: 'Pharo';
    at: 'tags' put: #('smalltalk');
    yourself.
```

The reader covers block and flow styles, so the flow form parses the same way:

```smalltalk
NeoYAMLReader fromString: 'name: Pharo', String lf, 'tags: [smalltalk, yaml]'.
```

Plain scalars get core-schema coercion (`42` becomes an `Integer`, `true` a
`Boolean`, `null` becomes `nil`), while quoted scalars always stay strings.

### A multi-document stream

`allFromString:` splits a `---`/`...`-separated stream and returns an `Array`
of documents (mirrors `NeoJSONReader>>upToEnd` for JSON Lines):

```smalltalk
NeoYAMLReader allFromString: 'id: 1', String lf, '---', String lf, 'id: 2'.
```

returns an `Array` of two `Dictionary` objects.

## Round-tripping

Because both directions share the NeoJSON object model, writing then reading
returns an equal object for the block-style subset the writer emits:

```smalltalk
| original yaml restored |
original := Dictionary new
    at: 'name' put: 'Pharo';
    at: 'tags' put: #('smalltalk' 'yaml');
    yourself.
yaml := NeoYAMLWriter write: original.
restored := NeoYAMLReader fromString: yaml.
restored = original.   "=> true"
```

## Method summary

| Direction | Message | Input | Output |
|-----------|---------|-------|--------|
| write | `NeoYAMLWriter writeJSON:` | JSON `String` | YAML `String` |
| write | `NeoYAMLWriter write:` | NeoJSON-shaped object | YAML `String` |
| write | `NeoYAMLWriter writeAll:` | collection of objects | multi-document YAML `String` |
| read | `NeoYAMLReader fromString:` | YAML `String` (one document) | object |
| read | `NeoYAMLReader allFromString:` | YAML `String` (multi-document) | `Array` of objects |
