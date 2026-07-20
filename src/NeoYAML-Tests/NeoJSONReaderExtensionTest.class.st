"
I test NeoJSONReader class>>fromYAML: (defined in NeoJSONReader.extension.st,
part of NeoYAML-Core), verifying it behaves as a thin alias for
NeoYAMLReader class>>fromString: rather than duplicating NeoYAMLReaderTest's
coverage of YAML parsing itself.
"
Class {
	#name : 'NeoJSONReaderExtensionTest',
	#superclass : 'TestCase',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'tests' }
NeoJSONReaderExtensionTest >> testFromYAMLMatchesNeoYAMLReaderFromString [
	| yaml |
	yaml := 'a: 1' , String lf , 'b: true'.
	self assert: (NeoJSONReader fromYAML: yaml) equals: (NeoYAMLReader fromString: yaml)
]

{ #category : 'tests' }
NeoJSONReaderExtensionTest >> testFromYAMLParsesBlockMapping [
	| expected |
	expected := Dictionary new.
	expected at: 'key' put: 'value'.
	self assert: (NeoJSONReader fromYAML: 'key: value') equals: expected
]

{ #category : 'tests' }
NeoJSONReaderExtensionTest >> testToYAMLThenFromYAMLRoundTripsUsingOnlyNeoJSONSideMethods [
	| original yaml resultBack |
	original := NeoJSONReader fromString: '{"a":1,"b":true,"c":[1,2]}'.
	yaml := NeoJSONWriter toYAML: original.
	resultBack := NeoJSONReader fromYAML: yaml.
	self assert: resultBack equals: original
]
