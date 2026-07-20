"
I test NeoJSONObject class>>fromYAML: (defined in NeoJSONObject.extension.st,
part of NeoYAML-Core), which reads YAML into NeoJSONObject/NeoJSONArray so the
result supports NeoJSON's message-style field access (obj name), and round-trips
with NeoJSONWriter class>>toYAML:.
"
Class {
	#name : 'NeoJSONObjectExtensionTest',
	#superclass : 'TestCase',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'tests' }
NeoJSONObjectExtensionTest >> testFromYAMLReturnsNeoJSONObjectWithMessageAccess [
	| obj |
	obj := NeoJSONObject fromYAML: 'name: Pharo'.
	self assert: obj class equals: NeoJSONObject.
	self assert: obj name equals: 'Pharo'
]

{ #category : 'tests' }
NeoJSONObjectExtensionTest >> testFromYAMLNestedMappingIsAlsoNeoJSONObject [
	| obj |
	obj := NeoJSONObject fromYAML: 'outer:' , String lf , '  inner: 1'.
	self assert: obj outer class equals: NeoJSONObject.
	self assert: obj outer inner equals: 1
]

{ #category : 'tests' }
NeoJSONObjectExtensionTest >> testFromYAMLSequenceIsNeoJSONArray [
	| obj |
	obj := NeoJSONObject fromYAML: 'items: [1, 2, 3]'.
	self assert: obj items class equals: NeoJSONArray.
	self assert: obj items asArray equals: #( 1 2 3 )
]

{ #category : 'tests' }
NeoJSONObjectExtensionTest >> testNeoJSONObjectRoundTripsThroughYAML [
	| original yaml back |
	original := NeoJSONObject fromString: '{"name":"Pharo","tags":["a","b"]}'.
	yaml := NeoJSONWriter toYAML: original.
	back := NeoJSONObject fromYAML: yaml.
	self assert: back equals: original
]
