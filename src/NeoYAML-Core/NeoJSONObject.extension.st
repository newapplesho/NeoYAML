Extension { #name : 'NeoJSONObject' }

{ #category : '*NeoYAML-Core' }
NeoJSONObject class >> fromYAML: aYAMLString [
	^ NeoYAMLReader fromString: aYAMLString mapClass: self listClass: NeoJSONArray
]
