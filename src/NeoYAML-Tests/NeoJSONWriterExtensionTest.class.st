"
I test NeoJSONWriter class>>toYAML: (defined in NeoJSONWriter.extension.st,
part of NeoYAML-Core), verifying it behaves as a thin alias for
NeoYAMLWriter class>>write: rather than duplicating NeoYAMLWriterTest's
coverage of YAML formatting itself.
"
Class {
	#name : 'NeoJSONWriterExtensionTest',
	#superclass : 'TestCase',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'tests' }
NeoJSONWriterExtensionTest >> testToYAMLMatchesNeoYAMLWriterWrite [
	| dict |
	dict := Dictionary new.
	dict at: 'a' put: 1.
	self assert: (NeoJSONWriter toYAML: dict) equals: (NeoYAMLWriter write: dict)
]

{ #category : 'tests' }
NeoJSONWriterExtensionTest >> testToYAMLProducesTextNeoYAMLReaderCanReadBack [
	| dict yaml |
	dict := Dictionary new.
	dict at: 'name' put: 'Pharo'.
	yaml := NeoJSONWriter toYAML: dict.
	self assert: (NeoYAMLReader fromString: yaml) equals: dict
]

{ #category : 'tests' }
NeoJSONWriterExtensionTest >> testToYAMLRaisesErrorForUnsupportedType [
	self should: [ NeoJSONWriter toYAML: Object new ] raise: Error
]
