# Roadmap

## Done

- `NeoYAMLWriter` — converts NeoJSON-shaped objects (`Dictionary`,
  `Array`/`OrderedCollection`, `Association`, scalars) to YAML text.
  `write:` converts an already-parsed object; `writeJSON:` parses JSON text
  via `NeoJSONReader fromString:` first, so it works end-to-end from raw
  JSON. `writeAll:` writes a collection as a `---`-separated multi-document
  stream.
- `NeoYAMLReader` — parses YAML text back into the same object shapes
  (`Dictionary` for block/flow mappings, `Array` for block/flow sequences,
  scalars). `fromString:` mirrors `NeoJSONReader class>>fromString:`;
  `allFromString:` reads a `---`/`...`-separated multi-document stream and
  returns an Array of documents (mirrors `NeoJSONReader>>upToEnd`).

### Full YAML 1.2 coverage, implemented in stages (each shipped and
CI-verified before the next started)

1. **Comments** (`# ...`) — stripped so hand-written YAML (not just
   `NeoYAMLWriter`'s own output) can be read.
2. **Flow-style collections** (`{a: 1, b: 2}`, `[1, 2, 3]`) — read-only in
   `NeoYAMLReader`; `NeoYAMLWriter` still only emits block style, since
   block style is always valid and more readable and the two writer/reader
   directions don't need to be symmetric here.
3. **Block scalars** (`|` literal, `>` folded, with `-`/`+` chomping
   indicators) — `NeoYAMLReader` reads both styles; `NeoYAMLWriter` emits
   literal style (`|`/`|-`) for any nested String value containing a
   newline, replacing the double-quote/`\n`-escape it still uses for a
   bare top-level multi-line string.
4. **Tags** (`!!str`, `!!int`, `!!float`, `!!bool`, `!!null`, `!!map`,
   `!!seq`) — read-only in `NeoYAMLReader`, forcing a value's
   interpretation regardless of what it would otherwise parse as (e.g.
   `!!str 123` reads as the string `'123'`). `NeoYAMLWriter` doesn't need
   to emit tags: its existing quoting rules already make every core-schema
   type unambiguous without them.
5. **Multi-document streams** (`---` / `...`) and **exponent-form floats**
   (`1e10`, `1.5e-3`) — both directions.

6. **Scan / parse / construct pipeline** — `NeoYAMLReader` was
   rebuilt from a single-pass, string-based reader into the staged
   architecture real YAML implementations use (see e.g. libyaml, PyYAML):
   `NeoYAMLScanner` turns source text into blank-line-preserving physical
   line records; `NeoYAMLParser`'s parse stage builds a
   `NeoYAMLNode` tree capturing structure/style/tag without yet deciding a
   scalar's final type; `NeoYAMLConstructor` performs that final
   null/boolean/number/tag coercion. This fixed two real gaps the old
   single-pass design could not represent (see below).
7. **A package per reusable pipeline stage** — `NeoYAMLScanner` and
   `NeoYAMLParser`/`NeoYAMLNode` were split into their own packages
   (`NeoYAML-Core-Scan`, `NeoYAML-Core-Parse`), with `NeoYAMLReader`
   reduced to a thin facade in `NeoYAML-Core` that calls `NeoYAMLParser`
   then `NeoYAMLConstructor`. `NeoYAMLConstructor` stays in `NeoYAML-Core`
   rather than getting a fourth package of its own: it is a small
   finishing step over the exact `NeoYAMLNode` shape parse
   produces, with no reuse value on its own. This makes Scan → Parse's
   one-way dependency visible in the Metacello baseline's package graph,
   not just in prose, without introducing a package for a class that
   wouldn't benefit from one.

See `NeoYAMLReader`'s class comment for the exact, current scope and the
following known gaps (kept intentionally, as documented simplifications
rather than oversights):

- Folded (`>`) style does not preserve *trailing* blank lines under `+`
  (keep) chomping — interior blank lines correctly become paragraph breaks,
  but trailing ones are not folded back in before chomping runs.
- An explicit block-scalar indentation indicator (e.g. `|2`) is not
  recognized; content indentation is always auto-detected.
- A tag only applies to an inline value on the same line, or an
  empty/flow-style collection; `!!map`/`!!seq` followed by block-style
  content on subsequent lines, and tags on mapping keys, are not
  recognized.
- A `---`/`...` document-separator line must be exactly that (no compact
  `--- key: value` first-document-on-the-same-line form). `fromString:`
  tolerates such marker lines wrapping a single document (a leading `---`
  and/or a trailing `.../---`), but a second document after a `---` is
  rejected — use `allFromString:` for multi-document streams.
- Text following a closed flow collection on the same line (e.g.
  `[1, 2] extra`) is silently ignored rather than rejected. Fail-loud
  covers leftover content on *subsequent* lines and unterminated flow
  collections, but not trailing junk on the flow line itself.
- A plain scalar used as a mapping key gets the same core-schema coercion
  as a value, so `true:`, `123:`, and `1.5:` become boolean/integer/float
  keys rather than strings. This is correct per YAML, but differs from
  JSON/NeoJSON, where keys are always strings; it only surfaces for
  hand-written YAML, since `NeoYAMLWriter` quotes any key that would
  otherwise read back as a non-string.

## Explicitly out of scope

- **Anchors and aliases** (`&anchor`, `*alias`) — deliberately not
  supported, even for non-cyclic shared structure. `NeoJSONReader`/
  `NeoJSONWriter` never track object identity across a structure either
  (a JSON object referenced twice gets serialized twice, independently),
  so skipping this keeps `NeoYAMLReader`/`NeoYAMLWriter` consistent with
  the NeoJSON behavior this project re-targets. Supporting real cycles
  would additionally require constructing objects incrementally and
  patching back-references after the fact — a much larger undertaking
  than this project's scope justifies.
- **Custom (non-core-schema) tags** — only the implicit/explicit core
  schema types are recognized; user-defined tag semantics are not.
