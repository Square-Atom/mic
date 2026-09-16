class_name Ostinato
extends RefCounted

## The rhythmic figures a looped chord can be broken into.
##
## A pattern is a list of steps that divide one bar evenly, and each step names
## the chord tones struck at that moment. Positions are chord-tone numbers
## rather than intervals - 1 is the root, 3 the third, 5 the fifth - so a single
## pattern fits every chord in every key with no transposition step of its own.
## That is the whole reason the loop stores degrees: the figure and the chord
## stay independent, and either can change without touching the other.

## The tone that closes an ascending figure: the seventh when the chord has one,
## and the root an octave up when it does not. Written as one position rather
## than two patterns so that flipping the sevenths toggle re-shapes the figure
## instead of leaving it reaching for a note the chord no longer contains.
const TOP := 7

const PATTERNS := [
	{"name": "All at once", "steps": [[1, 3, TOP, 5]]},
	{"name": "Root pulse", "steps": [[1], [1], [1], [1]]},
	{"name": "Ascending", "steps": [[1], [3], [5], [TOP]]},
	{"name": "Up-down (1-3-5-3)", "steps": [[1], [3], [5], [3]]},
	{"name": "Alberti (1-5-3-5)", "steps": [[1], [5], [3], [5]]},
	{"name": "Descending", "steps": [[TOP], [5], [3], [1]]},
	{"name": "Waltz (1 - 35 - 35)", "steps": [[1], [3, 5], [3, 5]]},
	{"name": "Offbeat (1 - 35 - 1 - 35)", "steps": [[1], [3, 5], [1], [3, 5]]},
]

## The block chord, used as the fallback whenever an index cannot be trusted.
const DEFAULT_INDEX := 0


static func count() -> int:
	return PATTERNS.size()


static func name_at(index: int) -> String:
	return PATTERNS[_clamp_index(index)]["name"]


## How many moments the bar is divided into. Also the divisor the clock uses to
## turn a tempo into a step length, which is why it can never be zero.
static func step_count(index: int) -> int:
	return maxi(1, (PATTERNS[_clamp_index(index)]["steps"] as Array).size())


## The chord-tone positions struck on `step`, wrapped so a caller that has lost
## track of the pattern length still gets a real step rather than an error.
static func step_at(index: int, step: int) -> Array:
	var steps: Array = PATTERNS[_clamp_index(index)]["steps"]
	return steps[wrapi(step, 0, steps.size())]


## Turn a chord-tone position into a MIDI note, given the chord in root position
## as MusicTheory.chord_voicing builds it: root, third, fifth, and the seventh
## when the chord has one.
##
## Everything stays inside the app's C4-B5 range without a clamp: the highest
## root the voicing can produce is B4, so even the octave above it lands on the
## B5 that closes the keyboard.
static func midi_for(position: int, voicing: PackedInt32Array) -> int:
	match position:
		1:
			return voicing[0]
		3:
			return voicing[1]
		5:
			return voicing[2]
		TOP:
			return voicing[3] if voicing.size() > 3 else voicing[0] + 12
	return voicing[0]


static func _clamp_index(index: int) -> int:
	return clampi(index, 0, PATTERNS.size() - 1)
