"
I build YAML text from the same object shapes NeoJSON works with: `Dictionary`,
`Array`/`OrderedCollection`, `Association`, and scalars (`String`, `Integer`,
`Float`, `Boolean`, `nil`).

I am implemented from scratch, without any external YAML library, following
the block-style subset of YAML 1.2 documented in `.claude/rules/yaml-spec.md`.

Example:
	NeoYAMLWriter writeJSON: '{""name"":""Pharo"",""tags"":[""smalltalk"",""yaml""]}'.

String values containing a newline are written as a literal block scalar
(`|` or `|-`, chosen based on whether the string itself ends in a newline)
instead of a double-quoted/escaped scalar, when nested inside a mapping or
sequence. A bare top-level multi-line string passed directly to `write:`
still uses the double-quoted/escaped form.

`writeAll: aCollection` writes each element as its own YAML document,
separated by `---`, matching what `NeoYAMLReader class>>allFromString:`
expects.

`NeoJSONWriter class>>toYAML:` (defined in `NeoJSONWriter.extension.st`, in
this same package) is a thin alias for `write:`, so YAML output is
discoverable directly from `NeoJSONWriter` without needing to know
`NeoYAMLWriter` exists.

Known limitations: I do not emit anchors/aliases, tags, folded (`>`) block
scalars, or flow-style mappings/sequences (except for the empty collection,
which has no block form). A block scalar value containing a blank line is
written correctly but cannot be read back exactly by `NeoYAMLReader` (see
its class comment). Non-finite Float values (NaN/Infinity) are not given
special YAML tokens, since `NeoJSONReader` never produces them.
"
Class {
	#name : 'NeoYAMLWriter',
	#superclass : 'Object',
	#instVars : [
		'indentSize'
	],
	#classVars : [],
	#package : 'NeoYAML-Core'
}

{ #category : 'convenience' }
NeoYAMLWriter class >> write: anObject [
	^ self new write: anObject
]

{ #category : 'convenience' }
NeoYAMLWriter class >> writeJSON: aJSONString [
	"Read into NeoJSONObject/NeoJSONArray rather than a plain (hash-ordered)
	 Dictionary, so the object's field order — and therefore the YAML key
	 order — follows the JSON text instead of being non-deterministic."
	| reader |
	reader := NeoJSONReader new
		mapClass: NeoJSONObject;
		listClass: NeoJSONArray;
		yourself.
	^ self write: (reader on: aJSONString readStream; next)
]

{ #category : 'convenience' }
NeoYAMLWriter class >> writeAll: aCollection [
	| stream |
	stream := WriteStream on: String new.
	aCollection doWithIndex: [ :object :idx |
		idx > 1 ifTrue: [ stream nextPutAll: '---'; nextPut: Character lf ].
		stream nextPutAll: (self write: object) ].
	^ stream contents
]

{ #category : 'initialization' }
NeoYAMLWriter >> initialize [
	super initialize.
	indentSize := 2
]

{ #category : 'accessing' }
NeoYAMLWriter >> indentSize [
	^ indentSize
]

{ #category : 'accessing' }
NeoYAMLWriter >> indentSize: anInteger [
	"Number of spaces per nesting level. Must be at least 1: a non-positive
	 indent cannot represent block nesting and would produce unreadable (or
	 unparseable) YAML."
	anInteger < 1 ifTrue: [ ^ self error: 'indentSize must be a positive integer.' ].
	indentSize := anInteger
]

{ #category : 'converting' }
NeoYAMLWriter >> write: anObject [
	^ String streamContents: [ :stream | self write: anObject on: stream indent: 0 ]
]

{ #category : 'private' }
NeoYAMLWriter >> write: anObject on: aStream indent: level [
	anObject isString ifTrue: [ ^ aStream nextPutAll: (self scalarFor: anObject) ].
	(anObject isKindOf: Association)
		ifTrue: [ ^ self writeAssociation: anObject on: aStream indent: level ].
	anObject isDictionary
		ifTrue: [ ^ self writeMapping: anObject on: aStream indent: level ].
	(anObject isKindOf: SequenceableCollection)
		ifTrue: [ ^ self writeSequence: anObject on: aStream indent: level ].
	^ aStream nextPutAll: (self scalarFor: anObject)
]

{ #category : 'private' }
NeoYAMLWriter >> writeMapping: aDictionary on: aStream indent: level [
	aDictionary isEmpty ifTrue: [ ^ aStream nextPutAll: '{}' ].
	aDictionary keysAndValuesDo: [ :key :value |
		self writeMappingEntry: key value: value on: aStream indent: level ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeMappingEntry: key value: value on: aStream indent: level [
	aStream
		nextPutAll: (self indentStringFor: level);
		nextPutAll: (self scalarFor: key);
		nextPutAll: ':'.
	self writeValue: value on: aStream indent: level
]

{ #category : 'private' }
NeoYAMLWriter >> writeValue: value on: aStream indent: level [
	"Write a mapping-entry or sequence-item value, after the caller has already
	 written its `key:`/`-` prefix. Shared by writeMappingEntry:value:on:indent:
	 and writeSequenceItem:on:indent:."
	(value isString and: [ self needsBlockScalar: value ])
		ifTrue: [ ^ self writeBlockScalarValue: value on: aStream indent: level ].
	(self isBlockValue: value)
		ifTrue: [
			aStream nextPut: Character lf.
			self write: value on: aStream indent: level + 1 ]
		ifFalse: [
			aStream nextPutAll: ' '.
			self write: value on: aStream indent: level.
			aStream nextPut: Character lf ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeSequence: aCollection on: aStream indent: level [
	aCollection isEmpty ifTrue: [ ^ aStream nextPutAll: '[]' ].
	aCollection do: [ :item |
		self writeSequenceItem: item on: aStream indent: level ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeSequenceItem: item on: aStream indent: level [
	aStream
		nextPutAll: (self indentStringFor: level);
		nextPutAll: '-'.
	self writeValue: item on: aStream indent: level
]

{ #category : 'testing' }
NeoYAMLWriter >> needsBlockScalar: aString [
	"A carriage return cannot survive a literal block scalar: YAML normalizes
	 all line breaks to LF on read (spec 5.4), so a CR would be lost or turned
	 into an extra line. Such a string must go through the double-quoted form
	 (with a \r escape) instead."
	^ (aString includes: Character lf) and: [ (aString includes: Character cr) not ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeBlockScalarValue: aString on: aStream indent: level [
	aStream
		nextPutAll: ' ';
		nextPutAll: (self blockScalarHeaderFor: aString);
		nextPut: Character lf.
	self writeBlockScalarLines: aString on: aStream indent: level + 1
]

{ #category : 'private' }
NeoYAMLWriter >> blockScalarHeaderFor: aString [
	(aString notEmpty and: [ aString last = Character lf ]) ifTrue: [ ^ '|' ].
	^ '|-'
]

{ #category : 'private' }
NeoYAMLWriter >> writeBlockScalarLines: aString on: aStream indent: level [
	| lines indentStr |
	lines := NeoYAMLScanner splitPreservingBlankLines: aString.
	indentStr := self indentStringFor: level.
	lines do: [ :line | self writeBlockScalarLine: line on: aStream indent: indentStr ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeBlockScalarLine: line on: aStream indent: indentStr [
	line isEmpty
		ifTrue: [ aStream nextPut: Character lf ]
		ifFalse: [ aStream nextPutAll: indentStr; nextPutAll: line; nextPut: Character lf ]
]

{ #category : 'private' }
NeoYAMLWriter >> writeAssociation: anAssociation on: aStream indent: level [
	self
		writeMappingEntry: anAssociation key
		value: anAssociation value
		on: aStream
		indent: level
]

{ #category : 'testing' }
NeoYAMLWriter >> isBlockValue: anObject [
	anObject isString ifTrue: [ ^ false ].
	(anObject isKindOf: Association) ifTrue: [ ^ true ].
	anObject isDictionary ifTrue: [ ^ anObject notEmpty ].
	(anObject isKindOf: SequenceableCollection) ifTrue: [ ^ anObject notEmpty ].
	^ false
]

{ #category : 'private' }
NeoYAMLWriter >> scalarFor: anObject [
	anObject ifNil: [ ^ 'null' ].
	(anObject isKindOf: Boolean) ifTrue: [ ^ anObject printString ].
	(anObject isInteger or: [ anObject isFloat ]) ifTrue: [ ^ anObject printString ].
	anObject isString ifTrue: [ ^ self quotedIfNeeded: anObject ].
	^ self error: 'NeoYAMLWriter cannot write a ' , anObject class name , '.'
]

{ #category : 'private' }
NeoYAMLWriter >> quotedIfNeeded: aString [
	((aString includes: Character lf) or: [ aString includes: Character cr ])
		ifTrue: [ ^ self doubleQuoted: aString ].
	(self needsQuoting: aString) ifFalse: [ ^ aString ].
	^ self singleQuoted: aString
]

{ #category : 'testing' }
NeoYAMLWriter >> needsQuoting: aString [
	aString isEmpty ifTrue: [ ^ true ].
	(self startsWithIndicatorCharacter: aString) ifTrue: [ ^ true ].
	((aString includesSubstring: ': ') or: [ aString includesSubstring: ' #' ])
		ifTrue: [ ^ true ].
	(aString first isSeparator or: [ aString last isSeparator ]) ifTrue: [ ^ true ].
	(self isReservedWord: aString) ifTrue: [ ^ true ].
	^ self looksLikeNumber: aString
]

{ #category : 'testing' }
NeoYAMLWriter >> startsWithIndicatorCharacter: aString [
	| indicators |
	indicators := #($- $? $: $, $[ $] ${ $} $# $& $* $! $| $> $' $" $% $@ $`).
	^ indicators includes: aString first
]

{ #category : 'testing' }
NeoYAMLWriter >> isReservedWord: aString [
	| reserved |
	reserved := #('true' 'false' 'yes' 'no' 'on' 'off' 'y' 'n' 'null' '~').
	^ reserved includes: aString asLowercase
]

{ #category : 'testing' }
NeoYAMLWriter >> looksLikeNumber: aString [
	| body |
	body := (aString first = $- or: [ aString first = $+ ])
		ifTrue: [ aString allButFirst ]
		ifFalse: [ aString ].
	body isEmpty ifTrue: [ ^ false ].
	^ (body allSatisfy: [ :c | c isDigit or: [ '.eE+-' includes: c ] ])
		and: [ body anySatisfy: [ :c | c isDigit ] ]
]

{ #category : 'private' }
NeoYAMLWriter >> singleQuoted: aString [
	| escaped |
	escaped := aString copyReplaceAll: '''' with: ''''''.
	^ '''' , escaped , ''''
]

{ #category : 'private' }
NeoYAMLWriter >> doubleQuoted: aString [
	| stream |
	stream := WriteStream on: String new.
	stream nextPut: $".
	aString do: [ :char | self writeDoubleQuoteChar: char on: stream ].
	stream nextPut: $".
	^ stream contents
]

{ #category : 'private' }
NeoYAMLWriter >> writeDoubleQuoteChar: aCharacter on: aStream [
	aCharacter = Character lf ifTrue: [ ^ aStream nextPutAll: '\n' ].
	aCharacter = Character cr ifTrue: [ ^ aStream nextPutAll: '\r' ].
	aCharacter = Character tab ifTrue: [ ^ aStream nextPutAll: '\t' ].
	aCharacter = $" ifTrue: [ ^ aStream nextPutAll: '\"' ].
	aCharacter = $\ ifTrue: [ ^ aStream nextPutAll: '\\' ].
	aStream nextPut: aCharacter
]

{ #category : 'private' }
NeoYAMLWriter >> indentStringFor: level [
	^ String new: level * indentSize withAll: Character space
]
