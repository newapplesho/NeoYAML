"
I am the ""compose"" stage's output in NeoYAMLReader's scan / parse /
compose / construct pipeline (see NeoYAMLReader's class comment): an
untyped tree node capturing everything the parser learned about one piece
of YAML *before* deciding what final Smalltalk object it becomes.

I carry:
- `kind`: `#mapping`, `#sequence`, or `#scalar`.
- `value`: for `#mapping`, an `OrderedCollection` of `keyNode -> valueNode`
  Associations; for `#sequence`, an `OrderedCollection` of item nodes; for
  `#scalar`, the scalar's text content (already quote-unescaped if it was
  quoted, but *not yet* coerced to Integer/Float/Boolean/nil — that
  decision belongs to `NeoYAMLConstructor` (in `NeoYAML-Core`), the next
  stage).
- `style`: only meaningful for `#scalar` — `#plain`, `#single`, or
  `#double` — since a plain scalar is eligible for null/boolean/number
  coercion at construct time, but a quoted scalar always stays a String
  regardless of what its text looks like.
- `chomping`: only set for a block scalar (`|`/`>`) — the header's
  chomping character (`$-`, `$+`, or the style character itself when no
  explicit indicator was given), used by `NeoYAMLConstructor` to trim/keep
  trailing newlines at construct time.
- `tag`: nil, or an explicit core schema tag name (e.g. `'str'`) that
  overrides the default construction rule regardless of style.

Deliberately one class with a `kind` tag rather than a `#scalar`/
`#mapping`/`#sequence` subclass hierarchy — for this small parser,
three near-empty subclasses would add more ceremony than clarity.
"
Class {
	#name : 'NeoYAMLNode',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'style',
		'tag',
		'chomping',
		'value'
	],
	#classVars : [],
	#package : 'NeoYAML-Core-Parse'
}

{ #category : 'instance creation' }
NeoYAMLNode class >> scalar: text style: aStyle tag: aTag [
	^ self new
		setKind: #scalar style: aStyle tag: aTag chomping: nil value: text
]

{ #category : 'instance creation' }
NeoYAMLNode class >> blockScalar: text style: aStyle chomping: aCharacter [
	^ self new
		setKind: #scalar style: aStyle tag: nil chomping: aCharacter value: text
]

{ #category : 'instance creation' }
NeoYAMLNode class >> mapping: entries tag: aTag [
	^ self new setKind: #mapping style: nil tag: aTag chomping: nil value: entries
]

{ #category : 'instance creation' }
NeoYAMLNode class >> sequence: items tag: aTag [
	^ self new setKind: #sequence style: nil tag: aTag chomping: nil value: items
]

{ #category : 'private' }
NeoYAMLNode >> setKind: aKind style: aStyle tag: aTag chomping: aChomping value: aValue [
	kind := aKind.
	style := aStyle.
	tag := aTag.
	chomping := aChomping.
	value := aValue
]

{ #category : 'accessing' }
NeoYAMLNode >> kind [
	^ kind
]

{ #category : 'accessing' }
NeoYAMLNode >> style [
	^ style
]

{ #category : 'accessing' }
NeoYAMLNode >> tag [
	^ tag
]

{ #category : 'accessing' }
NeoYAMLNode >> tag: aTag [
	tag := aTag
]

{ #category : 'accessing' }
NeoYAMLNode >> chomping [
	^ chomping
]

{ #category : 'accessing' }
NeoYAMLNode >> value [
	^ value
]

{ #category : 'testing' }
NeoYAMLNode >> isScalar [
	^ kind = #scalar
]

{ #category : 'testing' }
NeoYAMLNode >> isMapping [
	^ kind = #mapping
]

{ #category : 'testing' }
NeoYAMLNode >> isSequence [
	^ kind = #sequence
]
