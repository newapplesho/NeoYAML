"
I test NeoYAMLParser directly: source text in, a NeoYAMLNode tree out, with no
NeoYAMLConstructor step. I exist to pin down the parser's distinctive job as
documented in docs/parser.md (## Syntactic analysis): I build the tree
structure and record each scalar's quoting style and any explicit tag, but I do
*not* decide a scalar's final type — that is NeoYAMLConstructor's job. Each test
mirrors a specific claim in the parser documentation, so the two can be read
side by side. Broader end-to-end behavior (final types, folding/chomping) is
covered by NeoYAMLReaderTest.
"
Class {
	#name : 'NeoYAMLParserTest',
	#superclass : 'TestCase',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'private' }
NeoYAMLParserTest >> parse: aString [
	^ (NeoYAMLParser on: aString) parseNode
]

{ #category : 'private' }
NeoYAMLParserTest >> scalarTextsOf: aSequenceNode [
	^ (aSequenceNode value collect: [ :each | each value ]) asArray
]

{ #category : 'tests - scalar style' }
NeoYAMLParserTest >> testParsePlainScalarRecordsPlainStyle [
	"docs/parser.md ## Syntactic analysis: a plain scalar is recorded as #plain."
	| node |
	node := self parse: 'hello'.
	self assert: node isScalar.
	self assert: node style equals: #plain.
	self assert: node value equals: 'hello'
]

{ #category : 'tests - scalar style' }
NeoYAMLParserTest >> testParseSingleQuotedScalarKeepsTextNotType [
	"docs/parser.md: the parser records quoting (style) and does NOT decide the
	 type. '123' stays the text '123' with style #single, not the Integer 123."
	| node |
	node := self parse: '''123'''.
	self assert: node isScalar.
	self assert: node style equals: #single.
	self assert: node value equals: '123'
]

{ #category : 'tests - scalar style' }
NeoYAMLParserTest >> testParseDoubleQuotedScalarRecordsDoubleStyle [
	"docs/parser.md: a double-quoted scalar is recorded as #double."
	| node |
	node := self parse: '"hi"'.
	self assert: node style equals: #double.
	self assert: node value equals: 'hi'
]

{ #category : 'tests - mapping' }
NeoYAMLParserTest >> testParseBlockMappingBuildsMappingNode [
	"docs/parser.md: a block mapping becomes a #mapping node of key/value pairs."
	| node entry |
	node := self parse: 'k: v'.
	self assert: node isMapping.
	self assert: node value size equals: 1.
	entry := node value first.
	self assert: entry key value equals: 'k'.
	self assert: entry value value equals: 'v'
]

{ #category : 'tests - sequence' }
NeoYAMLParserTest >> testParseBlockSequenceBuildsSequenceNode [
	"docs/parser.md: a block sequence becomes a #sequence node of item nodes."
	| node |
	node := self parse: '- a' , String lf , '- b'.
	self assert: node isSequence.
	self assert: (self scalarTextsOf: node) equals: #( 'a' 'b' )
]

{ #category : 'tests - block vs flow' }
NeoYAMLParserTest >> testParseBlockAndFlowSequenceBuildSameShape [
	"docs/parser.md ## Parsing block style and flow style: the two surface forms
	 build the same tree."
	| block flow |
	block := self parse: 'k:' , String lf , '  - a' , String lf , '  - b'.
	flow := self parse: 'k: [a, b]'.
	self assert: (self scalarTextsOf: block value first value) equals: #( 'a' 'b' ).
	self assert: (self scalarTextsOf: flow value first value) equals: #( 'a' 'b' )
]

{ #category : 'tests - nesting' }
NeoYAMLParserTest >> testParseNestedMappingRecursesDeeper [
	"docs/parser.md ### Block style: an empty inline value recurses into the
	 deeper-indented child block."
	| node tagsValue |
	node := self parse: 'tags:' , String lf , '  - a'.
	tagsValue := node value first value.
	self assert: tagsValue isSequence.
	self assert: tagsValue value first value equals: 'a'
]

{ #category : 'tests - tags' }
NeoYAMLParserTest >> testParseExplicitTagRecordsTagName [
	"docs/parser.md: an explicit tag is recorded on the node; the type is still
	 not decided here (!!str 123 keeps the text '123')."
	| node |
	node := self parse: '!!str 123'.
	self assert: node tag equals: 'str'.
	self assert: node value equals: '123'
]

{ #category : 'tests - block scalars' }
NeoYAMLParserTest >> testParseLiteralBlockScalarRecordsLiteralStyle [
	"docs/parser.md ## Block scalars: | is recorded as style #literal."
	| node |
	node := self parse: '|' , String lf , '  line1' , String lf , '  line2'.
	self assert: node style equals: #literal.
	self assert: (node value includesSubstring: 'line1')
]

{ #category : 'tests - block scalars' }
NeoYAMLParserTest >> testParseFoldedBlockScalarRecordsFoldedStyle [
	"docs/parser.md ## Block scalars: > is recorded as style #folded."
	| node |
	node := self parse: '>' , String lf , '  a' , String lf , '  b'.
	self assert: node style equals: #folded
]

{ #category : 'tests - block scalars' }
NeoYAMLParserTest >> testParseBlockScalarRecordsChompingIndicator [
	"docs/parser.md ## Block scalars: the raw chomping character is recorded and
	 left for the constructor to apply."
	| node |
	node := self parse: '|-' , String lf , '  x'.
	self assert: node style equals: #literal.
	self assert: node chomping equals: $-
]

{ #category : 'tests - comments' }
NeoYAMLParserTest >> testParseStripsTrailingComment [
	"docs/parser.md ## Quote-aware comment stripping: a trailing comment is
	 removed before the value is built."
	| node |
	node := self parse: 'k: v # note'.
	self assert: node value first value value equals: 'v'
]

{ #category : 'tests - comments' }
NeoYAMLParserTest >> testParseCommentOnlyDocumentReturnsNil [
	"docs/parser.md: a comment-only document parses to nil."
	self assert: (self parse: '# just a comment') isNil
]

{ #category : 'tests - comments' }
NeoYAMLParserTest >> testParseEmptyDocumentReturnsNil [
	"docs/parser.md ## What the parser does not do: an empty document is nil."
	self assert: (self parse: '') isNil
]