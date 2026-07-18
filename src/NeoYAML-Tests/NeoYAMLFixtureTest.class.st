"
I test NeoYAMLReader and NeoYAMLWriter against real .yaml fixture files on
disk (see the top-level fixtures/ directory), complementing the inline
string-literal tests in NeoYAMLReaderTest and NeoYAMLWriterTest with cases
that exercise an actual file-read path. sample-document.yaml and
multi-document-stream.yaml stay flat; nested-config.yaml covers multiple
levels of indentation together with block/flow mixing, block scalars, and
explicit tags in one document.
"
Class {
	#name : 'NeoYAMLFixtureTest',
	#superclass : 'TestCase',
	#instVars : [
		'writer'
	],
	#classVars : [],
	#package : 'NeoYAML-Tests'
}

{ #category : 'running' }
NeoYAMLFixtureTest >> setUp [
	super setUp.
	writer := NeoYAMLWriter new
]

{ #category : 'private' }
NeoYAMLFixtureTest >> repositoryRoot [
	| workspace |
	workspace := OSEnvironment current
		at: 'GITHUB_WORKSPACE'
		ifAbsent: [ nil ].
	workspace ifNotNil: [ ^ workspace asFileReference ].
	^ (FileLocator imageDirectory / '..') resolve
]

{ #category : 'private' }
NeoYAMLFixtureTest >> fixture: aFileName [
	^ (self repositoryRoot / 'fixtures' / aFileName) contents
]

{ #category : 'tests - fixtures' }
NeoYAMLFixtureTest >> testReadSampleDocumentFixtureBuildsExpectedShape [
	| yaml expected metadata |
	yaml := self fixture: 'sample-document.yaml'.
	metadata := Dictionary new.
	metadata at: 'owner' put: 'alice'.
	metadata at: 'version' put: 1.
	expected := Dictionary new.
	expected at: 'name' put: 'example'.
	expected at: 'count' put: 3.
	expected at: 'enabled' put: true.
	expected at: 'description' put: nil.
	expected at: 'tags' put: #('a' 'b').
	expected at: 'metadata' put: metadata.
	self assert: (NeoYAMLReader fromString: yaml) equals: expected
]

{ #category : 'tests - fixtures' }
NeoYAMLFixtureTest >> testSampleDocumentFixtureRoundTrips [
	| yaml parsed reparsed |
	yaml := self fixture: 'sample-document.yaml'.
	parsed := NeoYAMLReader fromString: yaml.
	reparsed := NeoYAMLReader fromString: (writer write: parsed).
	self assert: reparsed equals: parsed
]

{ #category : 'tests - fixtures' }
NeoYAMLFixtureTest >> testReadMultiDocumentStreamFixtureSplitsIntoTwoDocuments [
	| yaml documents |
	yaml := self fixture: 'multi-document-stream.yaml'.
	documents := NeoYAMLReader allFromString: yaml.
	self assert: documents size equals: 2.
	self assert: (documents first at: 'service') equals: 'a'.
	self assert: (documents second at: 'service') equals: 'b'
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfig [
	| expected |
	expected := Dictionary new.
	expected at: 'name' put: 'web-api'.
	expected at: 'version' put: 2.
	expected at: 'enabled' put: true.
	expected at: 'weight' put: -1.5.
	expected at: 'scale' put: 1.5e2.
	expected at: 'buildId' put: '100'.
	expected at: 'retries' put: 3.
	expected at: 'description' put: self expectedNestedConfigDescription.
	expected at: 'metadata' put: self expectedNestedConfigMetadata.
	expected at: 'tags' put: #('production' 'east-1' 'blue-green').
	expected at: 'endpoints' put: self expectedNestedConfigEndpoints.
	^ expected
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigDescription [
	^ 'Handles inbound requests' , String lf , 'and routes them to background workers.'
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigMetadata [
	| metadata |
	metadata := Dictionary new.
	metadata at: 'owner' put: 'platform-team'.
	metadata at: 'priority' put: 1.
	^ metadata
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigEndpoints [
	^ Array
		with: self expectedNestedConfigFirstEndpoint
		with: self expectedNestedConfigSecondEndpoint
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigFirstEndpoint [
	| endpoint |
	endpoint := Dictionary new.
	endpoint at: 'path' put: '/health'.
	endpoint at: 'methods' put: #('GET').
	endpoint at: 'auth' put: nil.
	^ endpoint
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigSecondEndpoint [
	| endpoint |
	endpoint := Dictionary new.
	endpoint at: 'path' put: '/users'.
	endpoint at: 'methods' put: #('GET' 'POST').
	endpoint at: 'auth' put: self expectedNestedConfigSecondEndpointAuth.
	^ endpoint
]

{ #category : 'private' }
NeoYAMLFixtureTest >> expectedNestedConfigSecondEndpointAuth [
	| auth |
	auth := Dictionary new.
	auth at: 'type' put: 'bearer'.
	auth at: 'scopes' put: #('read' 'write').
	^ auth
]

{ #category : 'tests - fixtures' }
NeoYAMLFixtureTest >> testReadNestedConfigFixtureBuildsExpectedShape [
	| yaml expected result |
	yaml := self fixture: 'nested-config.yaml'.
	expected := Dictionary new.
	expected at: 'service' put: self expectedNestedConfig.
	result := NeoYAMLReader fromString: yaml.
	self assert: result equals: expected
]

{ #category : 'tests - fixtures' }
NeoYAMLFixtureTest >> testNestedConfigFixtureRoundTrips [
	| yaml parsed reparsed |
	yaml := self fixture: 'nested-config.yaml'.
	parsed := NeoYAMLReader fromString: yaml.
	reparsed := NeoYAMLReader fromString: (writer write: parsed).
	self assert: reparsed equals: parsed
]
