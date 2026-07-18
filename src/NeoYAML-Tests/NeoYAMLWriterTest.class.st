"
I test NeoYAMLWriter: scalar formatting, quoting rules, block-style mapping
and sequence output, and the NeoJSON→YAML round trip via #writeJSON:.
"
Class {
	#name : 'NeoYAMLWriterTest',
	#superclass : 'TestCase',
	#instVars : [
		'writer'
	],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'running' }
NeoYAMLWriterTest >> setUp [
	super setUp.
	writer := NeoYAMLWriter new
]

{ #category : 'tests - scalars' }
NeoYAMLWriterTest >> testWriteNilWritesNull [
	self assert: (writer write: nil) equals: 'null'
]

{ #category : 'tests - scalars' }
NeoYAMLWriterTest >> testWriteTrueWritesLowercaseTrue [
	self assert: (writer write: true) equals: 'true'
]

{ #category : 'tests - scalars' }
NeoYAMLWriterTest >> testWriteFalseWritesLowercaseFalse [
	self assert: (writer write: false) equals: 'false'
]

{ #category : 'tests - scalars' }
NeoYAMLWriterTest >> testWriteIntegerWritesPlainNumber [
	self assert: (writer write: 42) equals: '42'
]

{ #category : 'tests - scalars' }
NeoYAMLWriterTest >> testWriteFloatWritesPlainNumber [
	self assert: (writer write: 3.14) equals: '3.14'
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWritePlainStringIsUnquoted [
	self assert: (writer write: 'hello') equals: 'hello'
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWriteStringQuotesColon [
	self assert: (writer write: 'a: b') equals: '''a: b'''
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWriteEmptyStringUsesQuotes [
	self assert: (writer write: '') equals: ''''''
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWriteReservedWordStringIsQuoted [
	self assert: (writer write: 'true') equals: '''true'''
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWriteNumberLookingStringIsQuoted [
	self assert: (writer write: '123') equals: '''123'''
]

{ #category : 'tests - strings' }
NeoYAMLWriterTest >> testWriteStringWithNewlineUsesDoubleQuotes [
	| input |
	input := 'a' , String lf , 'b'.
	self assert: (writer write: input) equals: '"a\nb"'
]

{ #category : 'tests - block scalars' }
NeoYAMLWriterTest >> testWriteMappingValueWithNewlineUsesLiteralBlockScalar [
	| dict input expected |
	input := 'a' , String lf , 'b'.
	dict := Dictionary new.
	dict at: 'text' put: input.
	expected := 'text: |-' , String lf , '  a' , String lf , '  b' , String lf.
	self assert: (writer write: dict) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLWriterTest >> testWriteMappingValueWithTrailingNewlineUsesClipChomping [
	| dict input expected |
	input := 'a' , String lf , 'b' , String lf.
	dict := Dictionary new.
	dict at: 'text' put: input.
	expected := 'text: |' , String lf , '  a' , String lf , '  b' , String lf.
	self assert: (writer write: dict) equals: expected
]

{ #category : 'tests - block scalars' }
NeoYAMLWriterTest >> testWriteSequenceItemWithNewlineUsesLiteralBlockScalar [
	| array input expected |
	input := 'a' , String lf , 'b'.
	array := Array with: input.
	expected := '- |-' , String lf , '  a' , String lf , '  b' , String lf.
	self assert: (writer write: array) equals: expected
]

{ #category : 'tests - collections' }
NeoYAMLWriterTest >> testWriteEmptyArrayUsesFlowStyle [
	self assert: (writer write: #()) equals: '[]'
]

{ #category : 'tests - collections' }
NeoYAMLWriterTest >> testWriteEmptyDictionaryUsesFlowStyle [
	self assert: (writer write: Dictionary new) equals: '{}'
]

{ #category : 'tests - collections' }
NeoYAMLWriterTest >> testWriteFlatArrayUsesBlockSequence [
	| expected |
	expected := '- 1' , String lf , '- 2' , String lf , '- 3' , String lf.
	self assert: (writer write: #(1 2 3)) equals: expected
]

{ #category : 'tests - collections' }
NeoYAMLWriterTest >> testWriteDictionaryUsesBlockMapping [
	| dict |
	dict := Dictionary new.
	dict at: 'key' put: 'value'.
	self assert: ((writer write: dict) includesSubstring: 'key: value')
]

{ #category : 'tests - collections' }
NeoYAMLWriterTest >> testWriteMultiKeyDictionaryIncludesAllEntries [
	| dict yaml |
	dict := Dictionary new.
	dict at: 'a' put: 1.
	dict at: 'b' put: 2.
	yaml := writer write: dict.
	self assert: (yaml includesSubstring: 'a: 1').
	self assert: (yaml includesSubstring: 'b: 2')
]

{ #category : 'tests - nesting' }
NeoYAMLWriterTest >> testWriteNestedMappingIndentsDeeper [
	| inner outer expected |
	inner := Dictionary new.
	inner at: 'inner' put: 1.
	outer := Dictionary new.
	outer at: 'outer' put: inner.
	expected := 'outer:' , String lf , '  inner: 1' , String lf.
	self assert: (writer write: outer) equals: expected
]

{ #category : 'tests - nesting' }
NeoYAMLWriterTest >> testWriteNestedSequenceIndentsDeeper [
	| array expected |
	array := Array with: (Array with: 1).
	expected := '-' , String lf , '  - 1' , String lf.
	self assert: (writer write: array) equals: expected
]

{ #category : 'tests - nesting' }
NeoYAMLWriterTest >> testWriteMappingValueThatIsSequenceUsesBlockStyle [
	| dict expected |
	dict := Dictionary new.
	dict at: 'items' put: #(1 2).
	expected := 'items:' , String lf , '  - 1' , String lf , '  - 2' , String lf.
	self assert: (writer write: dict) equals: expected
]

{ #category : 'tests - nesting' }
NeoYAMLWriterTest >> testWriteSequenceItemThatIsMappingUsesBlockStyle [
	| dict array expected |
	dict := Dictionary new.
	dict at: 'k' put: 'v'.
	array := Array with: dict.
	expected := '-' , String lf , '  k: v' , String lf.
	self assert: (writer write: array) equals: expected
]

{ #category : 'tests - association' }
NeoYAMLWriterTest >> testWriteAssociationAsSingleEntryMapping [
	| expected |
	expected := 'key: value' , String lf.
	self assert: (writer write: ('key' -> 'value')) equals: expected
]

{ #category : 'tests - json adapting' }
NeoYAMLWriterTest >> testWriteJSONRoundTripsObjectToYAMLMapping [
	| yaml |
	yaml := NeoYAMLWriter writeJSON: '{"a":1,"b":true}'.
	self assert: (yaml includesSubstring: 'a: 1').
	self assert: (yaml includesSubstring: 'b: true')
]

{ #category : 'tests - errors' }
NeoYAMLWriterTest >> testWriteUnsupportedTypeRaisesError [
	self should: [ writer write: Object new ] raise: Error
]

{ #category : 'tests - multi-document' }
NeoYAMLWriterTest >> testWriteAllSeparatesDocumentsWithMarker [
	| first second expected |
	first := Dictionary new.
	first at: 'a' put: 1.
	second := Dictionary new.
	second at: 'b' put: 2.
	expected := 'a: 1' , String lf , '---' , String lf , 'b: 2' , String lf.
	self assert: (NeoYAMLWriter writeAll: (Array with: first with: second)) equals: expected
]
