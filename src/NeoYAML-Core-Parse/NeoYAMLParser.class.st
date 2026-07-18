"
I am the ""parse"" stage of NeoYAMLReader's scan / parse / construct
pipeline (see NeoYAMLReader's class comment): I perform the syntactic
analysis, turning the flat line records into a tree. I walk the physical
line records `NeoYAMLScanner` (in `NeoYAML-Core-Scan`) produced and turn them
into a tree of `NeoYAMLNode`s: using indentation to recognize block
mappings/sequences, a character-stream sub-parser for flow mappings/
sequences, and explicit-tag syntax, I decide structure, scalar quoting
style, and any explicit tag — but I deliberately do not decide a scalar's
final Smalltalk type (Integer vs. String vs. Boolean, etc.); that decision
belongs to `NeoYAMLConstructor` (in `NeoYAML-Core`), the next stage.

I strip comments lazily, per line, as I read past them — except inside a
block scalar body, where a `#` is always literal content and a blank line
is always significant, which is the reason I go through `NeoYAMLScanner`'s
blank-line-preserving line records rather than stripping blank/comment
lines globally up front.

`parseNode` reads one document's worth of nodes (or answers nil for an
empty/comment-only document); `on: aString` creates a parser positioned at
the start of aString.
"
Class {
	#name : 'NeoYAMLParser',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'position'
	],
	#classVars : [],
	#package : 'NeoYAML-Core-Parse'
}

{ #category : 'instance creation' }
NeoYAMLParser class >> on: aString [
	^ self new
		setSource: aString;
		yourself
]

{ #category : 'initialization' }
NeoYAMLParser >> initialize [
	super initialize.
	position := 1
]

{ #category : 'private' }
NeoYAMLParser >> setSource: aString [
	entries := NeoYAMLScanner scan: aString
]

{ #category : 'parsing' }
NeoYAMLParser >> parseNode [
	self atEnd ifTrue: [ ^ nil ].
	^ self parseNodeAtIndent: self currentIndent
]

{ #category : 'testing' }
NeoYAMLParser >> atEnd [
	self skipBlankEntries.
	^ position > entries size
]

{ #category : 'private' }
NeoYAMLParser >> skipBlankEntries [
	[ self shouldSkipCurrentEntry ] whileTrue: [ position := position + 1 ]
]

{ #category : 'private' }
NeoYAMLParser >> shouldSkipCurrentEntry [
	position > entries size ifTrue: [ ^ false ].
	(entries at: position) key = -1 ifTrue: [ ^ true ].
	^ (self stripCommentFrom: (entries at: position) value) isEmpty
]

{ #category : 'private' }
NeoYAMLParser >> currentIndent [
	self skipBlankEntries.
	^ (entries at: position) key
]

{ #category : 'private' }
NeoYAMLParser >> currentText [
	self skipBlankEntries.
	^ self stripCommentFrom: (entries at: position) value
]

{ #category : 'private' }
NeoYAMLParser >> advance [
	position := position + 1
]

{ #category : 'private' }
NeoYAMLParser >> stripCommentFrom: aLine [
	| idx |
	idx := self commentStartIndexIn: aLine.
	idx = 0 ifTrue: [ ^ aLine ].
	^ aLine copyFrom: 1 to: idx - 1
]

{ #category : 'private' }
NeoYAMLParser >> commentStartIndexIn: aLine [
	| inSingle inDouble i char |
	inSingle := false.
	inDouble := false.
	i := 1.
	[ i <= aLine size ] whileTrue: [
		char := aLine at: i.
		(self isCommentHashAt: i in: aLine char: char single: inSingle double: inDouble)
			ifTrue: [ ^ i ].
		(char = $' and: [ inDouble not ]) ifTrue: [ inSingle := inSingle not ].
		(char = $" and: [ inSingle not ]) ifTrue: [ inDouble := inDouble not ].
		i := i + 1 ].
	^ 0
]

{ #category : 'private' }
NeoYAMLParser >> isCommentHashAt: i in: aLine char: char single: inSingle double: inDouble [
	char = $# ifFalse: [ ^ false ].
	(inSingle or: [ inDouble ]) ifTrue: [ ^ false ].
	^ i = 1 or: [ (aLine at: i - 1) isSeparator ]
]

{ #category : 'private' }
NeoYAMLParser >> trimmed: aString [
	| start stop |
	start := 1.
	[ start <= aString size and: [ (aString at: start) isSeparator ] ]
		whileTrue: [ start := start + 1 ].
	stop := aString size.
	[ stop >= start and: [ (aString at: stop) isSeparator ] ]
		whileTrue: [ stop := stop - 1 ].
	^ aString copyFrom: start to: stop
]

{ #category : 'parsing' }
NeoYAMLParser >> parseNodeAtIndent: indent [
	self currentTextStartsFlowCollection ifTrue: [ ^ self parseScalarLineNode ].
	(self hasExplicitTag: self currentText) ifTrue: [ ^ self parseTopLevelTaggedNode ].
	(self isBlockScalarHeader: self currentText)
		ifTrue: [ ^ self parseTopLevelBlockScalarNodeAtIndent: indent ].
	(self looksLikeSequenceItem: self currentText)
		ifTrue: [ ^ self parseSequenceNodeAtIndent: indent ].
	(self looksLikeMappingEntry: self currentText)
		ifTrue: [ ^ self parseMappingNodeAtIndent: indent ].
	^ self parseScalarLineNode
]

{ #category : 'testing' }
NeoYAMLParser >> currentTextStartsFlowCollection [
	^ self startsFlowCollection: self currentText
]

{ #category : 'testing' }
NeoYAMLParser >> startsFlowCollection: aText [
	^ aText notEmpty and: [ (aText first = ${) or: [ aText first = $[ ] ]
]

{ #category : 'parsing' }
NeoYAMLParser >> parseScalarLineNode [
	| text |
	text := self currentText.
	self advance.
	^ self valueNodeFor: text
]

{ #category : 'parsing' }
NeoYAMLParser >> parseTopLevelTaggedNode [
	| text |
	text := self currentText.
	self advance.
	^ self resolveTaggedValueNodeText: text
]

{ #category : 'parsing' }
NeoYAMLParser >> parseTopLevelBlockScalarNodeAtIndent: indent [
	| header |
	header := self currentText.
	self advance.
	^ self parseBlockScalarNodeWithHeader: header atParentIndent: indent
]

{ #category : 'testing' }
NeoYAMLParser >> looksLikeSequenceItem: aText [
	^ aText = '-' or: [ aText size >= 2 and: [ (aText copyFrom: 1 to: 2) = '- ' ] ]
]

{ #category : 'testing' }
NeoYAMLParser >> looksLikeMappingEntry: aText [
	^ (self topLevelColonIndexIn: aText) > 0
]

{ #category : 'private' }
NeoYAMLParser >> topLevelColonIndexIn: aText [
	| inSingle inDouble i char wasSingle wasDouble |
	inSingle := false.
	inDouble := false.
	i := 1.
	[ i <= aText size ] whileTrue: [
		char := aText at: i.
		wasSingle := inSingle.
		wasDouble := inDouble.
		(self isDelimiterColon: char at: i in: aText single: wasSingle double: wasDouble)
			ifTrue: [ ^ i ].
		(char = $' and: [ wasDouble not ]) ifTrue: [ inSingle := wasSingle not ].
		(char = $" and: [ wasSingle not ]) ifTrue: [ inDouble := wasDouble not ].
		i := i + 1 ].
	^ 0
]

{ #category : 'private' }
NeoYAMLParser >> isDelimiterColon: char at: i in: aText single: wasSingle double: wasDouble [
	char = $: ifFalse: [ ^ false ].
	(wasSingle or: [ wasDouble ]) ifTrue: [ ^ false ].
	^ self colonEndsKeyAt: i in: aText
]

{ #category : 'private' }
NeoYAMLParser >> colonEndsKeyAt: i in: aText [
	^ i = aText size or: [ (aText at: i + 1) = Character space ]
]

{ #category : 'parsing' }
NeoYAMLParser >> parseSequenceNodeAtIndent: indent [
	| items |
	items := OrderedCollection new.
	[ self atEnd not
		and: [ self currentIndent = indent and: [ self looksLikeSequenceItem: self currentText ] ] ]
		whileTrue: [ items add: (self parseSequenceItemNodeAt: indent) ].
	^ NeoYAMLNode sequence: items tag: nil
]

{ #category : 'parsing' }
NeoYAMLParser >> parseSequenceItemNodeAt: indent [
	| text offset remainder |
	text := self currentText.
	offset := self sequenceItemContentOffset: text.
	remainder := text copyFrom: offset + 1 to: text size.
	self advance.
	(self remainderStartsCompactMapping: remainder)
		ifTrue: [ ^ self parseCompactMappingFromInline: remainder atKeyIndent: indent + offset ].
	^ self resolveValueNodeText: remainder atParentIndent: indent
]

{ #category : 'testing' }
NeoYAMLParser >> remainderStartsCompactMapping: remainder [
	(self startsFlowCollection: remainder) ifTrue: [ ^ false ].
	(self hasExplicitTag: remainder) ifTrue: [ ^ false ].
	(self isBlockScalarHeader: remainder) ifTrue: [ ^ false ].
	^ self looksLikeMappingEntry: remainder
]

{ #category : 'parsing' }
NeoYAMLParser >> parseCompactMappingFromInline: remainderText atKeyIndent: keyIndent [
	| entries |
	entries := OrderedCollection new.
	entries add: (self mappingEntryFromText: remainderText atIndent: keyIndent).
	[ self atEnd not
		and: [ self currentIndent = keyIndent
			and: [ self looksLikeMappingEntry: self currentText ] ] ]
		whileTrue: [ entries add: (self parseMappingEntryNodeAt: keyIndent) ].
	^ NeoYAMLNode mapping: entries tag: nil
]

{ #category : 'private' }
NeoYAMLParser >> sequenceItemContentOffset: aText [
	| i |
	i := 2.
	[ i <= aText size and: [ (aText at: i) = Character space ] ]
		whileTrue: [ i := i + 1 ].
	^ i - 1
]

{ #category : 'parsing' }
NeoYAMLParser >> parseMappingNodeAtIndent: indent [
	| entries |
	entries := OrderedCollection new.
	[ self atEnd not
		and: [ self currentIndent = indent and: [ self looksLikeMappingEntry: self currentText ] ] ]
		whileTrue: [ entries add: (self parseMappingEntryNodeAt: indent) ].
	^ NeoYAMLNode mapping: entries tag: nil
]

{ #category : 'parsing' }
NeoYAMLParser >> parseMappingEntryNodeAt: indent [
	| text |
	text := self currentText.
	self advance.
	^ self mappingEntryFromText: text atIndent: indent
]

{ #category : 'parsing' }
NeoYAMLParser >> mappingEntryFromText: text atIndent: indent [
	| colonIndex keyText valueText |
	colonIndex := self topLevelColonIndexIn: text.
	keyText := text copyFrom: 1 to: colonIndex - 1.
	valueText := self trimmed: (text copyFrom: colonIndex + 1 to: text size).
	^ (self valueNodeFor: keyText) -> (self resolveValueNodeText: valueText atParentIndent: indent)
]

{ #category : 'parsing' }
NeoYAMLParser >> resolveValueNodeText: valueText atParentIndent: indent [
	(self hasExplicitTag: valueText)
		ifTrue: [ ^ self resolveTaggedValueNodeText: valueText ].
	(self isBlockScalarHeader: valueText)
		ifTrue: [ ^ self parseBlockScalarNodeWithHeader: valueText atParentIndent: indent ].
	valueText isEmpty ifTrue: [ ^ self resolveEmptyValueNodeAtParentIndent: indent ].
	^ self valueNodeFor: valueText
]

{ #category : 'parsing' }
NeoYAMLParser >> resolveEmptyValueNodeAtParentIndent: indent [
	(self emptyValueHasBlockChildAtParentIndent: indent)
		ifTrue: [ ^ self parseNodeAtIndent: self currentIndent ].
	^ self valueNodeFor: ''
]

{ #category : 'testing' }
NeoYAMLParser >> emptyValueHasBlockChildAtParentIndent: indent [
	self atEnd ifTrue: [ ^ false ].
	self currentIndent > indent ifTrue: [ ^ true ].
	^ self currentIndent = indent and: [ self looksLikeSequenceItem: self currentText ]
]

{ #category : 'testing' }
NeoYAMLParser >> hasExplicitTag: aText [
	^ aText size >= 2 and: [ aText first = $! and: [ (aText at: 2) = $! ] ]
]

{ #category : 'parsing' }
NeoYAMLParser >> resolveTaggedValueNodeText: valueText [
	| tagName rest node |
	tagName := self tagNameIn: valueText.
	rest := self trimmed: (self afterTagIn: valueText).
	rest isEmpty ifTrue: [ ^ self emptyNodeForTag: tagName ].
	node := self valueNodeFor: rest.
	node tag: tagName.
	^ node
]

{ #category : 'private' }
NeoYAMLParser >> tagNameIn: aText [
	| stop |
	stop := 3.
	[ stop <= aText size and: [ (aText at: stop) isSeparator not ] ]
		whileTrue: [ stop := stop + 1 ].
	^ aText copyFrom: 3 to: stop - 1
]

{ #category : 'private' }
NeoYAMLParser >> afterTagIn: aText [
	| start |
	start := (self tagNameIn: aText) size + 3.
	start > aText size ifTrue: [ ^ '' ].
	^ aText copyFrom: start to: aText size
]

{ #category : 'private' }
NeoYAMLParser >> emptyNodeForTag: tagName [
	tagName = 'map' ifTrue: [ ^ NeoYAMLNode mapping: OrderedCollection new tag: tagName ].
	tagName = 'seq' ifTrue: [ ^ NeoYAMLNode sequence: OrderedCollection new tag: tagName ].
	^ NeoYAMLNode scalar: '' style: #plain tag: tagName
]

{ #category : 'testing' }
NeoYAMLParser >> isBlockScalarHeader: aText [
	(aText isEmpty or: [ aText size > 2 ]) ifTrue: [ ^ false ].
	(aText first = $| or: [ aText first = $> ]) ifFalse: [ ^ false ].
	aText size = 1 ifTrue: [ ^ true ].
	^ aText last = $- or: [ aText last = $+ ]
]

{ #category : 'parsing' }
NeoYAMLParser >> parseBlockScalarNodeWithHeader: header atParentIndent: parentIndent [
	| lines style chomping contentIndent joined |
	lines := self collectBlockScalarLinesDeeperThan: parentIndent.
	style := header first = $> ifTrue: [ #folded ] ifFalse: [ #literal ].
	chomping := header last.
	lines isEmpty ifTrue: [ ^ NeoYAMLNode blockScalar: '' style: style chomping: chomping ].
	contentIndent := (lines detect: [ :assoc | assoc key ~= -1 ] ifNone: [ 0 -> '' ]) key.
	joined := self joinBlockScalarLines: lines contentIndent: contentIndent.
	^ NeoYAMLNode blockScalar: joined style: style chomping: chomping
]

{ #category : 'private' }
NeoYAMLParser >> collectBlockScalarLinesDeeperThan: parentIndent [
	| lines |
	lines := OrderedCollection new.
	[ position <= entries size and: [ self blockScalarShouldContinueAt: parentIndent ] ]
		whileTrue: [
			lines add: (entries at: position).
			position := position + 1 ].
	^ lines
]

{ #category : 'private' }
NeoYAMLParser >> blockScalarShouldContinueAt: parentIndent [
	| entry |
	entry := entries at: position.
	entry key = -1 ifTrue: [ ^ true ].
	^ entry key > parentIndent
]

{ #category : 'private' }
NeoYAMLParser >> joinBlockScalarLines: lines contentIndent: contentIndent [
	| stream |
	stream := WriteStream on: String new.
	lines doWithIndex: [ :assoc :idx |
		idx > 1 ifTrue: [ stream nextPut: Character lf ].
		stream nextPutAll: (self reconstructBlockLine: assoc contentIndent: contentIndent) ].
	stream nextPut: Character lf.
	^ stream contents
]

{ #category : 'private' }
NeoYAMLParser >> reconstructBlockLine: assoc contentIndent: contentIndent [
	| extra |
	assoc key = -1 ifTrue: [ ^ '' ].
	extra := assoc key - contentIndent.
	extra <= 0 ifTrue: [ ^ assoc value ].
	^ (String new: extra withAll: Character space) , assoc value
]

{ #category : 'parsing' }
NeoYAMLParser >> valueNodeFor: aText [
	aText isEmpty ifTrue: [ ^ NeoYAMLNode scalar: '' style: #plain tag: nil ].
	aText first = ${ ifTrue: [ ^ self parseFlowMappingNode: aText readStream ].
	aText first = $[ ifTrue: [ ^ self parseFlowSequenceNode: aText readStream ].
	^ self scalarNodeFor: aText
]

{ #category : 'parsing' }
NeoYAMLParser >> scalarNodeFor: aText [
	(aText size >= 2 and: [ aText first = $' and: [ aText last = $' ] ])
		ifTrue: [ ^ NeoYAMLNode scalar: (self unquoteSingle: aText) style: #single tag: nil ].
	(aText size >= 2 and: [ aText first = $" and: [ aText last = $" ] ])
		ifTrue: [ ^ NeoYAMLNode scalar: (self unquoteDouble: aText) style: #double tag: nil ].
	^ NeoYAMLNode scalar: aText style: #plain tag: nil
]

{ #category : 'parsing' }
NeoYAMLParser >> parseFlowValueNode: aStream [
	self skipFlowWhitespace: aStream.
	aStream peek = ${ ifTrue: [ ^ self parseFlowMappingNode: aStream ].
	aStream peek = $[ ifTrue: [ ^ self parseFlowSequenceNode: aStream ].
	^ self scalarNodeFor: (self extractFlowScalarText: aStream)
]

{ #category : 'private' }
NeoYAMLParser >> skipFlowWhitespace: aStream [
	[ aStream atEnd not and: [ aStream peek = Character space ] ]
		whileTrue: [ aStream next ]
]

{ #category : 'parsing' }
NeoYAMLParser >> parseFlowSequenceNode: aStream [
	| items |
	items := OrderedCollection new.
	aStream next.
	self skipFlowWhitespace: aStream.
	aStream peek = $] ifTrue: [ aStream next. ^ NeoYAMLNode sequence: items tag: nil ].
	[ items add: (self parseFlowValueNode: aStream).
	  self skipFlowWhitespace: aStream.
	  aStream peek = $, ]
		whileTrue: [ aStream next. self skipFlowWhitespace: aStream ].
	aStream next.
	^ NeoYAMLNode sequence: items tag: nil
]

{ #category : 'parsing' }
NeoYAMLParser >> parseFlowMappingNode: aStream [
	| entries |
	entries := OrderedCollection new.
	aStream next.
	self skipFlowWhitespace: aStream.
	aStream peek = $} ifTrue: [ aStream next. ^ NeoYAMLNode mapping: entries tag: nil ].
	[ entries add: (self parseFlowEntryNodeFrom: aStream).
	  self skipFlowWhitespace: aStream.
	  aStream peek = $, ]
		whileTrue: [ aStream next. self skipFlowWhitespace: aStream ].
	aStream next.
	^ NeoYAMLNode mapping: entries tag: nil
]

{ #category : 'parsing' }
NeoYAMLParser >> parseFlowEntryNodeFrom: aStream [
	| keyNode |
	keyNode := self parseFlowValueNode: aStream.
	self skipFlowWhitespace: aStream.
	aStream next.
	self skipFlowWhitespace: aStream.
	^ keyNode -> (self parseFlowValueNode: aStream)
]

{ #category : 'private' }
NeoYAMLParser >> extractFlowScalarText: aStream [
	(aStream peek = $' or: [ aStream peek = $" ])
		ifTrue: [ ^ self extractFlowQuotedText: aStream ].
	^ self trimmed: (self readFlowPlainText: aStream)
]

{ #category : 'private' }
NeoYAMLParser >> readFlowPlainText: aStream [
	| stream |
	stream := WriteStream on: String new.
	[ aStream atEnd not and: [ (',}]:{[' includes: aStream peek) not ] ]
		whileTrue: [ stream nextPut: aStream next ].
	^ stream contents
]

{ #category : 'private' }
NeoYAMLParser >> extractFlowQuotedText: aStream [
	| quote stream |
	quote := aStream next.
	stream := WriteStream on: String new.
	stream nextPut: quote.
	quote = $'
		ifTrue: [ self copySingleQuotedBodyFrom: aStream to: stream quote: quote ]
		ifFalse: [ self copyDoubleQuotedBodyFrom: aStream to: stream ].
	^ stream contents
]

{ #category : 'private' }
NeoYAMLParser >> copySingleQuotedBodyFrom: aStream to: stream quote: quote [
	| char |
	[ aStream atEnd ] whileFalse: [
		char := aStream next.
		stream nextPut: char.
		char = quote
			ifTrue: [
				aStream peek = quote
					ifTrue: [ stream nextPut: aStream next ]
					ifFalse: [ ^ self ] ] ]
]

{ #category : 'private' }
NeoYAMLParser >> copyDoubleQuotedBodyFrom: aStream to: stream [
	| char |
	[ aStream atEnd ] whileFalse: [
		char := aStream next.
		stream nextPut: char.
		char = $\
			ifTrue: [ aStream atEnd ifFalse: [ stream nextPut: aStream next ] ]
			ifFalse: [ char = $" ifTrue: [ ^ self ] ] ]
]

{ #category : 'private' }
NeoYAMLParser >> unquoteSingle: aText [
	| inner |
	inner := aText copyFrom: 2 to: aText size - 1.
	^ inner copyReplaceAll: '''''' with: ''''
]

{ #category : 'private' }
NeoYAMLParser >> unquoteDouble: aText [
	| inner stream i |
	inner := aText copyFrom: 2 to: aText size - 1.
	stream := WriteStream on: String new.
	i := 1.
	[ i <= inner size ] whileTrue: [
		i := self appendDoubleQuoteCharAt: i in: inner to: stream ].
	^ stream contents
]

{ #category : 'private' }
NeoYAMLParser >> appendDoubleQuoteCharAt: i in: inner to: stream [
	| char |
	char := inner at: i.
	(char = $\ and: [ i < inner size ])
		ifTrue: [ ^ self appendEscapeAfterBackslashAt: i in: inner to: stream ].
	stream nextPut: char.
	^ i + 1
]

{ #category : 'private' }
NeoYAMLParser >> appendEscapeAfterBackslashAt: i in: inner to: stream [
	| next |
	next := inner at: i + 1.
	next = $n ifTrue: [ stream nextPut: Character lf. ^ i + 2 ].
	next = $" ifTrue: [ stream nextPut: $". ^ i + 2 ].
	next = $\ ifTrue: [ stream nextPut: $\. ^ i + 2 ].
	stream nextPut: next.
	^ i + 2
]
