"
I am the ""scan"" stage of NeoYAMLReader's scan / parse / compose / construct
pipeline (see NeoYAMLReader's class comment; NeoYAMLParser in
NeoYAML-Core-Parse is the ""parse + compose"" stage that calls me). I turn
raw YAML source text
into an ordered list of physical line records — `indent -> content`
Associations, one per line, in original order — without interpreting their
meaning at all: no comment stripping, no blank-line dropping, no structural
nesting. A blank (empty or all-spaces) line is recorded as `-1 -> ''`
(indent `-1` is a sentinel meaning ""not applicable""), so later stages can
decide for themselves whether a blank line is insignificant (between two
ordinary constructs) or significant (inside a block scalar's body, where it
must be preserved). This split lets `NeoYAMLReader` fix a class of bugs a
""strip everything up front"" scanner cannot: content that looks like a
comment or a blank line, but only inside a block scalar, must survive.

I do not need any external library — this is plain character-by-character
scanning, mirroring what a real YAML scanner (e.g. libyaml's) does at the
lowest level, scoped to exactly the subset `NeoYAMLReader` supports.
"
Class {
	#name : 'NeoYAMLScanner',
	#superclass : 'Object',
	#instVars : [],
	#classVars : [],
	#package : 'NeoYAML-Core-Scan'
}

{ #category : 'scanning' }
NeoYAMLScanner class >> scan: aString [
	^ (self splitPreservingBlankLines: aString)
		collect: [ :line | self lineRecordFor: line ]
]

{ #category : 'private' }
NeoYAMLScanner class >> splitPreservingBlankLines: aString [
	| lines start i |
	lines := OrderedCollection new.
	start := 1.
	i := 1.
	[ i <= aString size ] whileTrue: [
		(aString at: i) = Character lf
			ifTrue: [
				lines add: (aString copyFrom: start to: i - 1).
				start := i + 1 ].
		i := i + 1 ].
	start <= aString size ifTrue: [ lines add: (aString copyFrom: start to: aString size) ].
	^ lines
]

{ #category : 'private' }
NeoYAMLScanner class >> lineRecordFor: aLine [
	| indent |
	(self isBlankLine: aLine) ifTrue: [ ^ -1 -> '' ].
	indent := 0.
	[ indent < aLine size and: [ (aLine at: indent + 1) = Character space ] ]
		whileTrue: [ indent := indent + 1 ].
	^ indent -> (aLine copyFrom: indent + 1 to: aLine size)
]

{ #category : 'private' }
NeoYAMLScanner class >> isBlankLine: aLine [
	^ aLine allSatisfy: [ :c | c = Character space ]
]
