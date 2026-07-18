"
I parse YAML text back into the same object shapes NeoJSON works with:
`Dictionary` for block/flow mappings, `Array` for block/flow sequences, and
scalars (`String`, `Integer`, `Float`, `Boolean`, `nil`).

I am implemented from scratch, without any external YAML library, as a thin
facade over the **scan / parse+compose / construct** pipeline real YAML
implementations use (see e.g. libyaml or PyYAML). Scan and parse+compose
each get their own sub-package, since a scanner and a node-tree builder are
reusable, self-contained units; construct is a small, non-reusable finishing
step over the exact `NeoYAMLNode` shape parse+compose produces, so its class
(`NeoYAMLConstructor`) lives alongside me, in `NeoYAML-Core`, rather than in
a fourth sub-package of its own:

1. **Scan** (`NeoYAMLScanner`, package `NeoYAML-Core-Scan`) turns source
   text into physical line records (`indent -> content`), preserving blank
   lines — it does not decide what anything *means*.
2. **Parse + compose** (`NeoYAMLParser`, package `NeoYAML-Core-Parse`) walks
   the line records, using indentation to recognize block mappings/
   sequences, a character-stream sub-parser for flow mappings/sequences,
   and builds a tree of `NeoYAMLNode`s (also in `NeoYAML-Core-Parse`) —
   capturing structure, scalar quoting style, and any explicit tag, but
   *not yet* deciding a scalar's final Smalltalk type. Comments are
   stripped here, lazily, per line — except inside a block scalar body,
   where a `#` is always literal content and a blank line is always
   significant.
3. **Construct** (`NeoYAMLConstructor`, package `NeoYAML-Core`) walks the
   `NeoYAMLNode` tree and produces the final native objects: a plain scalar
   gets the null/boolean/number core-schema coercion; a quoted scalar
   always stays a String; an explicit tag overrides both; a block scalar
   is folded (if `>`) and chomped here, correctly preserving interior
   blank lines as paragraph breaks.

I read: block and flow-style mappings/sequences (`key: value` /
`{a: 1, b: 2}`, `- item` / `[1, 2, 3]`, freely nested), plain/single/
double-quoted scalars, the null/boolean/number core schema (including
exponent-form floats like `1e10`), `#` comments, literal/folded block
scalars (`|`, `>`, with `-`/`+` chomping indicators, correctly preserving
blank lines as literal empty lines or folded paragraph breaks), and
explicit core schema tags (`!!str`, `!!int`, `!!float`, `!!bool`, `!!null`,
`!!map`, `!!seq`) that force a scalar's interpretation regardless of what
it would otherwise look like — e.g. `!!str 123` reads as the string
`'123'`, not the integer `123`.

`fromString:` reads a single document by handing source text to
`NeoYAMLParser` and the resulting node tree to `NeoYAMLConstructor`.
`allFromString:` reads a `---`/`...`-separated multi-document stream and
returns an Array of documents (mirrors `NeoJSONReader>>upToEnd` for JSON
Lines).

Example:
	NeoYAMLReader fromString: 'name: Pharo' , String lf , 'tags: [smalltalk, yaml]'.

Known limitations:
- An explicit block-scalar indentation indicator (e.g. `|2`) is not
  recognized; content indentation is always auto-detected from the first
  non-blank body line.
- Folded (`>`) style does not preserve *trailing* blank lines under `+`
  (keep) chomping — interior blank lines correctly become paragraph
  breaks, but trailing ones are not folded back in before chomping runs.
- A tag only applies to an inline value on the same line, or an
  empty/flow-style collection; `!!map`/`!!seq` followed by block-style
  content on subsequent lines is not recognized (the tag is treated as
  introducing an empty collection). Tags on mapping keys are not
  recognized either, only on values.
- A `---`/`...` document-separator line must be exactly that (no trailing
  whitespace, no compact `--- key: value` first-document-on-the-same-line
  form) — document splitting happens as raw-text preprocessing, before any
  per-document scan/parse/construct.
- Anchors/aliases and custom tags are not recognized — see
  `.claude/rules/yaml-spec.md` and `ROADMAP.md`.
"
Class {
	#name : 'NeoYAMLReader',
	#superclass : 'Object',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Core'
}

{ #category : 'convenience' }
NeoYAMLReader class >> fromString: aString [
	^ (NeoYAMLParser on: aString) parseNode
		ifNotNil: [ :node | NeoYAMLConstructor construct: node ]
]

{ #category : 'convenience' }
NeoYAMLReader class >> allFromString: aString [
	^ ((self splitDocuments: aString) collect: [ :doc | self fromString: doc ]) asArray
]

{ #category : 'private' }
NeoYAMLReader class >> splitDocuments: aString [
	| lines docs current |
	lines := (NeoYAMLScanner normalizeLineBreaks: aString) substrings: (String with: Character lf).
	docs := OrderedCollection new.
	current := OrderedCollection new.
	lines do: [ :line |
		(self isDocumentMarker: line)
			ifTrue: [
				current notEmpty ifTrue: [ docs add: (self joinLines: current) ].
				current := OrderedCollection new ]
			ifFalse: [ current add: line ] ].
	current notEmpty ifTrue: [ docs add: (self joinLines: current) ].
	^ docs
]

{ #category : 'private' }
NeoYAMLReader class >> isDocumentMarker: aLine [
	^ aLine = '---' or: [ aLine = '...' ]
]

{ #category : 'private' }
NeoYAMLReader class >> joinLines: aCollection [
	| stream |
	stream := WriteStream on: String new.
	aCollection doWithIndex: [ :line :idx |
		idx > 1 ifTrue: [ stream nextPut: Character lf ].
		stream nextPutAll: line ].
	^ stream contents
]
