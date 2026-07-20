Extension { #name : 'NeoJSONReader' }

{ #category : '*NeoYAML-Core' }
NeoJSONReader class >> fromYAML: aYAMLString [
	^ NeoYAMLReader fromString: aYAMLString
]
