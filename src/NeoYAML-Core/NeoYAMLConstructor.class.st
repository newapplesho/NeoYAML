"
I am the ""construct"" stage of NeoYAMLReader's scan / parse / construct
pipeline (see NeoYAMLReader's class comment). Given the
`NeoYAMLNode` tree `NeoYAMLParser` (in `NeoYAML-Core-Parse`) built, I decide
each scalar's final Smalltalk type: a plain scalar gets the null/boolean/
number core-schema coercion, a quoted scalar always stays a String, an
explicit tag overrides both, and a block scalar is folded (if `>`) and
chomped here — correctly turning an interior blank line into a paragraph
break for folded style, rather than losing it.

I hold no state of my own — `construct:` is a pure function from a
`NeoYAMLNode` tree to the final Dictionary/Array/scalar shape NeoJSON works
with, so all my methods are class-side.
"
Class {
	#name : 'NeoYAMLConstructor',
	#superclass : 'Object',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Core'
}

{ #category : 'construct' }
NeoYAMLConstructor class >> construct: node [
	^ self construct: node mapClass: Dictionary listClass: Array
]

{ #category : 'construct' }
NeoYAMLConstructor class >> construct: node mapClass: mapClass listClass: listClass [
	node isMapping
		ifTrue: [ ^ self constructMapping: node mapClass: mapClass listClass: listClass ].
	node isSequence
		ifTrue: [ ^ self constructSequence: node mapClass: mapClass listClass: listClass ].
	^ self constructScalar: node
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructMapping: node mapClass: mapClass listClass: listClass [
	| dict |
	dict := mapClass new.
	node value do: [ :assoc |
		dict
			at: (self construct: assoc key mapClass: mapClass listClass: listClass)
			put: (self construct: assoc value mapClass: mapClass listClass: listClass) ].
	^ dict
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructSequence: node mapClass: mapClass listClass: listClass [
	^ listClass withAll: (node value collect: [ :item |
		self construct: item mapClass: mapClass listClass: listClass ])
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructScalar: node [
	node chomping ifNotNil: [ ^ self constructBlockScalar: node ].
	node tag ifNotNil: [ ^ self constructTagged: node ].
	^ self constructByStyle: node
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructByStyle: node [
	node style = #plain ifTrue: [ ^ self parsePlainScalar: node value ].
	^ node value
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructTagged: node [
	| content |
	content := node value.
	node tag = 'str' ifTrue: [ ^ content ].
	node tag = 'int' ifTrue: [ ^ Integer readFrom: (self stripLeadingPlus: content) readStream ].
	node tag = 'float'
		ifTrue: [ ^ Float readFrom: (self normalizeFloatText: content) readStream ].
	node tag = 'bool' ifTrue: [ ^ content = 'true' ].
	node tag = 'null' ifTrue: [ ^ nil ].
	^ self constructByStyle: node
]

{ #category : 'construct' }
NeoYAMLConstructor class >> constructBlockScalar: node [
	| text |
	text := node style = #folded
		ifTrue: [ self foldedTextFrom: node value ]
		ifFalse: [ node value ].
	^ self chomp: text indicator: node chomping
]

{ #category : 'construct' }
NeoYAMLConstructor class >> foldedTextFrom: rawText [
	| lines stream blankRun isFirst |
	lines := NeoYAMLScanner splitPreservingBlankLines: rawText.
	stream := WriteStream on: String new.
	blankRun := 0.
	isFirst := true.
	lines do: [ :line |
		line isEmpty
			ifTrue: [ blankRun := blankRun + 1 ]
			ifFalse: [
				isFirst
					ifTrue: [ isFirst := false ]
					ifFalse: [ self writeFoldSeparator: blankRun on: stream ].
				stream nextPutAll: line.
				blankRun := 0 ] ].
	^ stream contents
]

{ #category : 'construct' }
NeoYAMLConstructor class >> writeFoldSeparator: blankRun on: stream [
	blankRun = 0
		ifTrue: [ stream nextPutAll: ' ' ]
		ifFalse: [ blankRun timesRepeat: [ stream nextPut: Character lf ] ]
]

{ #category : 'construct' }
NeoYAMLConstructor class >> chomp: aString indicator: indicatorChar [
	indicatorChar = $- ifTrue: [ ^ self stripTrailingNewlines: aString ].
	indicatorChar = $+ ifTrue: [ ^ aString ].
	^ (self stripTrailingNewlines: aString) , (String with: Character lf)
]

{ #category : 'private' }
NeoYAMLConstructor class >> stripTrailingNewlines: aString [
	| stop |
	stop := aString size.
	[ stop >= 1 and: [ (aString at: stop) = Character lf ] ]
		whileTrue: [ stop := stop - 1 ].
	^ aString copyFrom: 1 to: stop
]

{ #category : 'construct' }
NeoYAMLConstructor class >> parsePlainScalar: aText [
	aText isEmpty ifTrue: [ ^ nil ].
	(self isNullLiteral: aText) ifTrue: [ ^ nil ].
	(self isTrueLiteral: aText) ifTrue: [ ^ true ].
	(self isFalseLiteral: aText) ifTrue: [ ^ false ].
	(self isIntegerLiteral: aText)
		ifTrue: [ ^ Integer readFrom: (self stripLeadingPlus: aText) readStream ].
	(self isFloatLiteral: aText)
		ifTrue: [ ^ Float readFrom: (self normalizeFloatText: aText) readStream ].
	^ aText
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isNullLiteral: aText [
	"YAML 1.2 core schema: null | Null | NULL | ~ (empty is handled earlier)."
	^ #('null' 'Null' 'NULL' '~') includes: aText
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isTrueLiteral: aText [
	^ #('true' 'True' 'TRUE') includes: aText
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isFalseLiteral: aText [
	^ #('false' 'False' 'FALSE') includes: aText
]

{ #category : 'private' }
NeoYAMLConstructor class >> normalizeExponentCase: aText [
	^ aText copyReplaceAll: 'E' with: 'e'
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isIntegerLiteral: aText [
	^ self isDigitsOnly: (self stripSign: aText)
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isFloatLiteral: aText [
	| body eIndex mantissa exponent |
	body := self stripSign: aText.
	eIndex := self exponentIndexIn: body.
	eIndex = 0 ifTrue: [ ^ self isDecimalMantissa: body ].
	mantissa := body copyFrom: 1 to: eIndex - 1.
	exponent := body copyFrom: eIndex + 1 to: body size.
	^ (self isValidMantissa: mantissa) and: [ self isSignedDigits: exponent ]
]

{ #category : 'private' }
NeoYAMLConstructor class >> exponentIndexIn: aString [
	| eIndex bigEIndex |
	eIndex := aString indexOf: $e.
	bigEIndex := aString indexOf: $E.
	eIndex = 0 ifTrue: [ ^ bigEIndex ].
	bigEIndex = 0 ifTrue: [ ^ eIndex ].
	^ eIndex min: bigEIndex
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isDecimalMantissa: aString [
	"YAML 1.2 core schema float mantissa: one side of the dot may be empty
	 (`.5`, `5.`), but not both, and each present side must be digits."
	| dotIndex intPart fracPart |
	dotIndex := aString indexOf: $. .
	dotIndex = 0 ifTrue: [ ^ false ].
	intPart := aString copyFrom: 1 to: dotIndex - 1.
	fracPart := aString copyFrom: dotIndex + 1 to: aString size.
	(intPart isEmpty and: [ fracPart isEmpty ]) ifTrue: [ ^ false ].
	^ (intPart isEmpty or: [ self isDigitsOnly: intPart ])
		and: [ fracPart isEmpty or: [ self isDigitsOnly: fracPart ] ]
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isValidMantissa: aString [
	^ (self isDigitsOnly: aString) or: [ self isDecimalMantissa: aString ]
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isSignedDigits: aString [
	^ self isDigitsOnly: (self stripSign: aString)
]

{ #category : 'testing' }
NeoYAMLConstructor class >> isDigitsOnly: aString [
	^ aString notEmpty and: [ aString allSatisfy: [ :c | c isDigit ] ]
]

{ #category : 'private' }
NeoYAMLConstructor class >> stripSign: aText [
	"Drop a leading sign for the digit-shape predicates. The core schema allows
	 both `-` and `+` (e.g. `+5`, `1e+3`)."
	(aText notEmpty and: [ aText first = $- or: [ aText first = $+ ] ])
		ifTrue: [ ^ aText allButFirst ].
	^ aText
]

{ #category : 'private' }
NeoYAMLConstructor class >> stripLeadingPlus: aText [
	"Integer readFrom: rejects a leading `+`, so remove it before parsing.
	 A leading `-` is kept, since readFrom: handles it."
	(aText notEmpty and: [ aText first = $+ ]) ifTrue: [ ^ aText allButFirst ].
	^ aText
]

{ #category : 'private' }
NeoYAMLConstructor class >> normalizeFloatText: aText [
	"Rewrite a core-schema float into the exact form Float readFrom: accepts:
	 lowercase exponent, no leading `+`, and a `0` before a bare leading dot
	 (`.5` -> `0.5`), preserving a leading `-`."
	| text sign |
	text := self normalizeExponentCase: aText.
	"Float readFrom: rejects an explicit `+` in the exponent (e.g. `1e+3`)."
	text := text copyReplaceAll: 'e+' with: 'e'.
	"...and stops at a bare dot before the exponent (`5.e3`), losing the
	 exponent, so give it an explicit fractional digit."
	text := text copyReplaceAll: '.e' with: '.0e'.
	sign := ''.
	(text notEmpty and: [ text first = $+ or: [ text first = $- ] ])
		ifTrue: [
			text first = $- ifTrue: [ sign := '-' ].
			text := text allButFirst ].
	(text notEmpty and: [ text first = $. ]) ifTrue: [ text := '0' , text ].
	^ sign , text
]
