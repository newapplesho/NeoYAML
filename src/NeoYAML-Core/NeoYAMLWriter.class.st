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
	^ self write: (NeoJSONReader fromString: aJSONString)
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
	(item isString and: [ self needsBlockScalar: item ])
		ifTrue: [ ^ self writeBlockScalarValue: item on: aStream indent: level ].
	(self isBlockValue: item)
		ifTrue: [
			aStream nextPut: Character lf.
			self write: item on: aStream indent: level + 1 ]
		ifFalse: [
			aStream nextPutAll: ' '.
			self write: item on: aStream indent: level.
			aStream nextPut: Character lf ]
]

{ #category : 'testing' }
NeoYAMLWriter >> needsBlockScalar: aString [
	^ aString includes: Character lf
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
	lines := self linesOf: aString.
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
NeoYAMLWriter >> linesOf: aString [
	| lines start i |
	lines := OrderedCollection new.
	start := 1.
	i := 1.
	[ i <= aString size ] whileTrue: [
		(aString at: i) = Character lf
			ifTrue: [
				lines add: (aString copyFrom: start to: i - 1).
				start := i + 1 ].
		i := i + 1 ].
	start <= aString size ifTrue: [ lines add: (aString copyFrom: start to: aString size) ].
	^ lines
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
	(anObject isKindOf: Dictionary) ifTrue: [ ^ anObject notEmpty ].
	(anObject isKindOf: SequenceableCollection) ifTrue: [ ^ anObject notEmpty ].
	^ false
]

{ #category : 'private' }
NeoYAMLWriter >> scalarFor: anObject [
	anObject ifNil: [ ^ 'null' ].
	(anObject isKindOf: Boolean) ifTrue: [ ^ anObject printString ].
	((anObject isKindOf: Integer) or: [ anObject isKindOf: Float ])
		ifTrue: [ ^ anObject printString ].
	anObject isString ifTrue: [ ^ self quotedIfNeeded: anObject ].
	^ Error signal: 'NeoYAMLWriter cannot write a ' , anObject class name , '.'
]

{ #category : 'private' }
NeoYAMLWriter >> quotedIfNeeded: aString [
	(aString includes: Character lf) ifTrue: [ ^ self doubleQuoted: aString ].
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
	aCharacter = $" ifTrue: [ ^ aStream nextPutAll: '\"' ].
	aCharacter = $\ ifTrue: [ ^ aStream nextPutAll: '\\' ].
	aStream nextPut: aCharacter
]

{ #category : 'private' }
NeoYAMLWriter >> indentStringFor: level [
	^ String new: level * indentSize withAll: Character space
]
