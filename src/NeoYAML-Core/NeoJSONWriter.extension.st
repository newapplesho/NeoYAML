Extension { #name : 'NeoJSONWriter' }

{ #category : '*NeoYAML-Core' }
NeoJSONWriter class >> toYAML: anObject [
	^ NeoYAMLWriter write: anObject
]
