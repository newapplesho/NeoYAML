Class {
	#name : 'BaselineOfNeoYAML',
	#superclass : 'BaselineOf',
	#instVars : [],
	#classVars : [],
	#package : 'BaselineOfNeoYAML'
}

{ #category : 'baselines' }
BaselineOfNeoYAML >> baseline: spec [
	<baseline>
	spec for: #common do: [
		self defineDependencies: spec.
		self definePackages: spec.
		self defineGroups: spec ]
]

{ #category : 'baselines' }
BaselineOfNeoYAML >> defineDependencies: spec [
	spec
		baseline: 'NeoJSON'
		with: [
			spec repository: 'github://svenvc/NeoJSON/repository'.
			spec loads: #('core') ]
]

{ #category : 'baselines' }
BaselineOfNeoYAML >> definePackages: spec [
	spec
		package: 'NeoYAML-Core-Scan';
		package: 'NeoYAML-Core-Parse' with: [ spec requires: #('NeoYAML-Core-Scan') ];
		package: 'NeoYAML-Core'
			with: [
				spec requires: #('NeoJSON' 'NeoYAML-Core-Scan' 'NeoYAML-Core-Parse') ];
		package: 'NeoYAML-Tests' with: [ spec requires: #('NeoYAML-Core') ]
]

{ #category : 'baselines' }
BaselineOfNeoYAML >> defineGroups: spec [
	spec
		group: 'default'
		with: #(
			'NeoYAML-Core-Scan'
			'NeoYAML-Core-Parse'
			'NeoYAML-Core'
			'NeoYAML-Tests')
]
