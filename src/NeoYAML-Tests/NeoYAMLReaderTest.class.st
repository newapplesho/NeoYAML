"
I test NeoYAMLReader: literal YAML parsing (independent of NeoYAMLWriter,
to avoid tautological coverage) plus round-trip tests (write then read back)
covering scalars, quoting, nesting, and the NeoJSON→YAML→object chain.
"
Class {
	#name : 'NeoYAMLReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'writer'
	],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'running' }
NeoYAMLReaderTest >> setUp [
	super setUp.
	writer := NeoYAMLWriter new
]

{ #category : 'private' }
NeoYAMLReaderTest >> roundTrip: anObject [
	^ NeoYAMLReader fromString: (writer write: anObject)
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadPlainTrueLiteral [
	self assert: (NeoYAMLReader fromString: 'true') equals: true
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadPlainNullLiteral [
	self assert: (NeoYAMLReader fromString: 'null') equals: nil
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadTildeNullLiteral [
	self assert: (NeoYAMLReader fromString: '~') equals: nil
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadNegativeIntegerLiteral [
	self assert: (NeoYAMLReader fromString: '-7') equals: -7
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadFloatLiteral [
	self assert: (NeoYAMLReader fromString: '3.14') equals: 3.14
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadEmptyMappingFlowLiteral [
	self assert: (NeoYAMLReader fromString: '{}') equals: Dictionary new
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadEmptySequenceFlowLiteral [
	self assert: (NeoYAMLReader fromString: '[]') equals: Array new
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadBlockMappingLiteral [
	| expected |
	expected := Dictionary new.
	expected at: 'key' put: 'value'.
	self assert: (NeoYAMLReader fromString: 'key: value') equals: expected
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadBlockSequenceLiteral [
	| yaml |
	yaml := '- 1' , String lf , '- 2'.
	self assert: (NeoYAMLReader fromString: yaml) equals: #(1 2)
]

{ #category : 'tests - literals' }
NeoYAMLReaderTest >> testReadNestedMappingLiteral [
	| yaml inner expected |
	yaml := 'outer:' , String lf , '  inner: 1'.
	inner := Dictionary new.
	inner at: 'inner' put: 1.
	expected := Dictionary new.
	expected at: 'outer' put: inner.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - comments' }
NeoYAMLReaderTest >> testReadStripsFullLineComment [
	| yaml expected |
	yaml := '# a comment' , String lf , 'key: value'.
	expected := Dictionary new.
	expected at: 'key' put: 'value'.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - comments' }
NeoYAMLReaderTest >> testReadStripsTrailingComment [
	| expected |
	expected := Dictionary new.
	expected at: 'key' put: 'value'.
	self assert: (NeoYAMLReader fromString: 'key: value # trailing') equals: expected
]

{ #category : 'tests - comments' }
NeoYAMLReaderTest >> testReadIgnoresHashInsideQuotedString [
	| expected |
	expected := Dictionary new.
	expected at: 'key' put: 'a # b'.
	self assert: (NeoYAMLReader fromString: 'key: ''a # b''') equals: expected
]

{ #category : 'tests - comments' }
NeoYAMLReaderTest >> testReadIgnoresHashWithoutPrecedingSpace [
	| expected |
	expected := Dictionary new.
	expected at: 'key' put: 'foo#bar'.
	self assert: (NeoYAMLReader fromString: 'key: foo#bar') equals: expected
]

{ #category : 'tests - comments' }
NeoYAMLReaderTest >> testReadCommentOnlyDocumentReturnsNil [
	self assert: (NeoYAMLReader fromString: '# just a comment') equals: nil
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowSequenceOfScalars [
	self assert: (NeoYAMLReader fromString: '[1, 2, 3]') equals: #(1 2 3)
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowMappingOfScalars [
	| expected |
	expected := Dictionary new.
	expected at: 'a' put: 1.
	expected at: 'b' put: 2.
	self assert: (NeoYAMLReader fromString: '{a: 1, b: 2}') equals: expected
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadNestedFlowSequence [
	self assert: (NeoYAMLReader fromString: '[1, [2, 3]]') equals: (Array with: 1 with: #(2 3))
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowSequenceWithQuotedCommaString [
	| expected |
	expected := Array with: 'a, b' with: 2.
	self assert: (NeoYAMLReader fromString: '[''a, b'', 2]') equals: expected
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowMappingAsBlockMappingValue [
	| inner expected |
	inner := Dictionary new.
	inner at: 'a' put: 1.
	expected := Dictionary new.
	expected at: 'items' put: inner.
	self assert: (NeoYAMLReader fromString: 'items: {a: 1}') equals: expected
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowMappingAsBlockSequenceItem [
	| inner |
	inner := Dictionary new.
	inner at: 'a' put: 1.
	self assert: (NeoYAMLReader fromString: '- {a: 1}') equals: (Array with: inner)
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadBlockSequenceOfBlockMappings [
	| yaml item expected |
	yaml := String lf join: {
		'sub_agents:'.
		'  - name: research'.
		'    output_key: research_result' }.
	item := Dictionary new.
	item at: 'name' put: 'research'.
	item at: 'output_key' put: 'research_result'.
	expected := Dictionary new.
	expected at: 'sub_agents' put: (Array with: item).
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadBlockSequenceItemSingleMappingEntry [
	| item |
	item := Dictionary new.
	item at: 'a' put: 1.
	self assert: (NeoYAMLReader fromString: '- a: 1') equals: (Array with: item)
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadBlockSequenceItemMappingWithEmptyValue [
	| yaml item |
	yaml := String lf join: { '- name:'. '  output_key: x' }.
	item := Dictionary new.
	item at: 'name' put: nil.
	item at: 'output_key' put: 'x'.
	self assert: (NeoYAMLReader fromString: yaml) equals: (Array with: item)
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadBlockSequenceItemExtraSpacesAfterDash [
	| item |
	item := Dictionary new.
	item at: 'a' put: 1.
	self assert: (NeoYAMLReader fromString: '-  a: 1') equals: (Array with: item)
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadBlockSequenceOfBlockMappingsExtraSpaces [
	| yaml item expected |
	yaml := String lf join: {
		'sub_agents:'.
		'  -  name: research'.
		'     output_key: research_result' }.
	item := Dictionary new.
	item at: 'name' put: 'research'.
	item at: 'output_key' put: 'research_result'.
	expected := Dictionary new.
	expected at: 'sub_agents' put: (Array with: item).
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadMappingEmptyValueThenSiblingKey [
	| yaml expected |
	yaml := String lf join: { 'a:'. 'b: 2' }.
	expected := Dictionary new.
	expected at: 'a' put: nil.
	expected at: 'b' put: 2.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block style' }
NeoYAMLReaderTest >> testReadMappingValueBlockSequenceAtSameIndent [
	| yaml expected |
	yaml := String lf join: { 'items:'. '- 1'. '- 2' }.
	expected := Dictionary new.
	expected at: 'items' put: #(1 2).
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - flow style' }
NeoYAMLReaderTest >> testReadFlowMappingWithNestedFlowSequenceValue [
	| expected |
	expected := Dictionary new.
	expected at: 'tags' put: #('x' 'y').
	self assert: (NeoYAMLReader fromString: '{tags: [x, y]}') equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadLiteralBlockScalarStripChomping [
	| yaml expected |
	yaml := 'text: |-' , String lf , '  a' , String lf , '  b'.
	expected := Dictionary new.
	expected at: 'text' put: 'a' , String lf , 'b'.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadLiteralBlockScalarClipChomping [
	| yaml expected |
	yaml := 'text: |' , String lf , '  a' , String lf , '  b'.
	expected := Dictionary new.
	expected at: 'text' put: 'a' , String lf , 'b' , String lf.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadFoldedBlockScalarJoinsWithSpaces [
	| yaml expected |
	yaml := 'text: >-' , String lf , '  a' , String lf , '  b'.
	expected := Dictionary new.
	expected at: 'text' put: 'a b'.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadBlockScalarAsSequenceItem [
	| yaml expected |
	yaml := '- |-' , String lf , '  a' , String lf , '  b'.
	expected := Array with: ('a' , String lf , 'b').
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadTopLevelBlockScalar [
	| yaml expected |
	yaml := '|-' , String lf , '  a' , String lf , '  b'.
	expected := 'a' , String lf , 'b'.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadLiteralBlockScalarPreservesInteriorBlankLine [
	| yaml expected |
	yaml := 'text: |' , String lf , '  line1' , String lf , '' , String lf , '  line2'.
	expected := Dictionary new.
	expected at: 'text' put: 'line1' , String lf , String lf , 'line2' , String lf.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLReaderTest >> testReadFoldedBlockScalarTurnsBlankLineIntoParagraphBreak [
	| yaml expected |
	yaml := 'text: >-' , String lf , '  line1' , String lf , '' , String lf , '  line2'.
	expected := Dictionary new.
	expected at: 'text' put: 'line1' , String lf , 'line2'.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadStrTagForcesStringOverNumberLookingValue [
	| expected |
	expected := Dictionary new.
	expected at: 'code' put: '123'.
	self assert: (NeoYAMLReader fromString: 'code: !!str 123') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadIntTagForcesIntegerFromQuotedValue [
	| expected |
	expected := Dictionary new.
	expected at: 'n' put: 42.
	self assert: (NeoYAMLReader fromString: 'n: !!int ''42''') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadFloatTagForcesFloat [
	| expected |
	expected := Dictionary new.
	expected at: 'n' put: 3.0.
	self assert: (NeoYAMLReader fromString: 'n: !!float 3.0') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadBoolTagForcesBoolean [
	| expected |
	expected := Dictionary new.
	expected at: 'flag' put: true.
	self assert: (NeoYAMLReader fromString: 'flag: !!bool true') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadNullTagForcesNil [
	| expected |
	expected := Dictionary new.
	expected at: 'v' put: nil.
	self assert: (NeoYAMLReader fromString: 'v: !!null anything') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadBareNullTagWithoutValue [
	| expected |
	expected := Dictionary new.
	expected at: 'v' put: nil.
	self assert: (NeoYAMLReader fromString: 'v: !!null') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadSeqTagWithFlowSequence [
	| expected |
	expected := Dictionary new.
	expected at: 'items' put: #(1 2).
	self assert: (NeoYAMLReader fromString: 'items: !!seq [1, 2]') equals: expected
]

{ #category : 'tests - tags' }
NeoYAMLReaderTest >> testReadTopLevelStrTag [
	self assert: (NeoYAMLReader fromString: '!!str 42') equals: '42'
]

{ #category : 'tests - numbers' }
NeoYAMLReaderTest >> testReadExponentFloatLowercaseE [
	self assert: (NeoYAMLReader fromString: '1e10') equals: 1e10
]

{ #category : 'tests - numbers' }
NeoYAMLReaderTest >> testReadExponentFloatUppercaseE [
	self assert: (NeoYAMLReader fromString: '1E3') equals: 1e3
]

{ #category : 'tests - numbers' }
NeoYAMLReaderTest >> testReadExponentFloatWithDecimalMantissa [
	self assert: (NeoYAMLReader fromString: '1.5e2') equals: 1.5e2
]

{ #category : 'tests - numbers' }
NeoYAMLReaderTest >> testReadExponentFloatWithNegativeExponent [
	self assert: (NeoYAMLReader fromString: '1e-3') equals: 1e-3
]

{ #category : 'tests - multi-document' }
NeoYAMLReaderTest >> testReadAllFromStringSplitsMultipleDocuments [
	| yaml first second expected |
	yaml := 'a: 1' , String lf , '---' , String lf , 'b: 2'.
	first := Dictionary new.
	first at: 'a' put: 1.
	second := Dictionary new.
	second at: 'b' put: 2.
	expected := Array with: first with: second.
	self assert: (NeoYAMLReader allFromString: yaml) equals: expected
]

{ #category : 'tests - multi-document' }
NeoYAMLReaderTest >> testReadAllFromStringIgnoresDocumentEndTerminator [
	| yaml first second expected |
	yaml := 'a: 1' , String lf , '...' , String lf , '---' , String lf , 'b: 2'.
	first := Dictionary new.
	first at: 'a' put: 1.
	second := Dictionary new.
	second at: 'b' put: 2.
	expected := Array with: first with: second.
	self assert: (NeoYAMLReader allFromString: yaml) equals: expected
]

{ #category : 'tests - multi-document' }
NeoYAMLReaderTest >> testWriteAllThenReadAllRoundTrips [
	| first second yaml |
	first := Dictionary new.
	first at: 'a' put: 1.
	second := Dictionary new.
	second at: 'b' put: 2.
	yaml := NeoYAMLWriter writeAll: (Array with: first with: second).
	self assert: (NeoYAMLReader allFromString: yaml)
		equals: (Array with: first with: second)
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsMappingValueWithNewlineViaBlockScalar [
	| dict |
	dict := Dictionary new.
	dict at: 'text' put: ('a' , String lf , 'b').
	self assert: (self roundTrip: dict) equals: dict
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsNil [
	self assert: (self roundTrip: nil) equals: nil
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsTrue [
	self assert: (self roundTrip: true) equals: true
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsFalse [
	self assert: (self roundTrip: false) equals: false
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsInteger [
	self assert: (self roundTrip: 42) equals: 42
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsFloat [
	self assert: (self roundTrip: 3.14) equals: 3.14
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsPlainString [
	self assert: (self roundTrip: 'hello') equals: 'hello'
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsStringNeedingSingleQuote [
	self assert: (self roundTrip: 'a: b') equals: 'a: b'
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsStringWithEmbeddedSingleQuote [
	self assert: (self roundTrip: 'a: it''s') equals: 'a: it''s'
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsStringWithNewline [
	| input |
	input := 'a' , String lf , 'b'.
	self assert: (self roundTrip: input) equals: input
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsEmptyString [
	self assert: (self roundTrip: '') equals: ''
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsEmptyArray [
	self assert: (self roundTrip: #()) equals: #()
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsEmptyDictionary [
	self assert: (self roundTrip: Dictionary new) equals: Dictionary new
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsFlatArray [
	self assert: (self roundTrip: #(1 2 3)) equals: #(1 2 3)
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsMultiKeyDictionary [
	| dict |
	dict := Dictionary new.
	dict at: 'a' put: 1.
	dict at: 'b' put: 2.
	self assert: (self roundTrip: dict) equals: dict
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsNestedMapping [
	| inner outer |
	inner := Dictionary new.
	inner at: 'inner' put: 1.
	outer := Dictionary new.
	outer at: 'outer' put: inner.
	self assert: (self roundTrip: outer) equals: outer
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsNestedSequence [
	| array |
	array := Array with: (Array with: 1).
	self assert: (self roundTrip: array) equals: array
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsMappingValueThatIsSequence [
	| dict |
	dict := Dictionary new.
	dict at: 'items' put: #(1 2).
	self assert: (self roundTrip: dict) equals: dict
]

{ #category : 'tests - round trip' }
NeoYAMLReaderTest >> testRoundTripsSequenceItemThatIsMapping [
	| dict array |
	dict := Dictionary new.
	dict at: 'k' put: 'v'.
	array := Array with: dict.
	self assert: (self roundTrip: array) equals: array
]

{ #category : 'tests - json adapting' }
NeoYAMLReaderTest >> testReadJSONWrittenAsYAMLRoundTrips [
	| original yaml resultBack |
	original := NeoJSONReader fromString: '{"a":1,"b":true,"c":[1,2],"d":{"x":"y"}}'.
	yaml := NeoYAMLWriter write: original.
	resultBack := NeoYAMLReader fromString: yaml.
	self assert: resultBack equals: original
]
