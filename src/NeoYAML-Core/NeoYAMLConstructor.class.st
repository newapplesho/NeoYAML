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
	node tag = 'int' ifTrue: [ ^ Integer readFrom: content readStream ].
	node tag = 'float'
		ifTrue: [ ^ Float readFrom: (self normalizeExponentCase: content) readStream ].
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
	(aText = 'null' or: [ aText = '~' ]) ifTrue: [ ^ nil ].
	aText = 'true' ifTrue: [ ^ true ].
	aText = 'false' ifTrue: [ ^ false ].
	(self isIntegerLiteral: aText) ifTrue: [ ^ Integer readFrom: aText readStream ].
	(self isFloatLiteral: aText)
		ifTrue: [ ^ Float readFrom: (self normalizeExponentCase: aText) readStream ].
	^ aText
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
	| dotIndex |
	dotIndex := aString indexOf: $. .
	dotIndex = 0 ifTrue: [ ^ false ].
	^ (self isDigitsOnly: (aString copyFrom: 1 to: dotIndex - 1))
		and: [ self isDigitsOnly: (aString copyFrom: dotIndex + 1 to: aString size) ]
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
	^ (aText first = $-) ifTrue: [ aText allButFirst ] ifFalse: [ aText ]
]
