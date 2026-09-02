class_name Chord
extends RefCounted

## One diatonic chord: its spelled notes, its quality, and the scale degree it
## was built on. Quality is *derived* from the stacked notes rather than looked
## up in a per-mode table, so major and minor keys share one code path.

enum Quality {
	MAJOR,
	MINOR,
	DIMINISHED,
	AUGMENTED,
	MAJOR7,
	MINOR7,
	DOMINANT7,
	HALF_DIM7,
	DIM7,
	MINOR_MAJOR7,
	AUG_MAJOR7,
	UNKNOWN,
}

## Suffix appended to the root note name to form the chord symbol.
const QUALITY_SUFFIX := {
	Quality.MAJOR: "",
	Quality.MINOR: "m",
	Quality.DIMINISHED: "\u00b0",
	Quality.AUGMENTED: "+",
	Quality.MAJOR7: "maj7",
	Quality.MINOR7: "m7",
	Quality.DOMINANT7: "7",
	Quality.HALF_DIM7: "\u00f87",
	Quality.DIM7: "\u00b07",
	Quality.MINOR_MAJOR7: "m(maj7)",
	Quality.AUG_MAJOR7: "+maj7",
	Quality.UNKNOWN: "?",
}

## Whether the roman numeral for this quality is written in upper case.
const QUALITY_IS_UPPER := {
	Quality.MAJOR: true,
	Quality.MINOR: false,
	Quality.DIMINISHED: false,
	Quality.AUGMENTED: true,
	Quality.MAJOR7: true,
	Quality.MINOR7: false,
	Quality.DOMINANT7: true,
	Quality.HALF_DIM7: false,
	Quality.DIM7: false,
	Quality.MINOR_MAJOR7: false,
	Quality.AUG_MAJOR7: true,
	Quality.UNKNOWN: true,
}

## Suffix appended to the roman numeral. Differs from the chord symbol because
## the numeral already encodes major/minor through its letter case.
const QUALITY_NUMERAL_SUFFIX := {
	Quality.MAJOR: "",
	Quality.MINOR: "",
	Quality.DIMINISHED: "\u00b0",
	Quality.AUGMENTED: "+",
	Quality.MAJOR7: "maj7",
	Quality.MINOR7: "7",
	Quality.DOMINANT7: "7",
	Quality.HALF_DIM7: "\u00f87",
	Quality.DIM7: "\u00b07",
	Quality.MINOR_MAJOR7: "(maj7)",
	Quality.AUG_MAJOR7: "+maj7",
	Quality.UNKNOWN: "",
}

const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII"]

var notes: Array[Note] = []
var quality: int = Quality.UNKNOWN
## 0-6: which scale degree this chord is built on.
var degree: int = 0


func _init(p_notes: Array[Note] = [], p_quality: int = Quality.UNKNOWN, p_degree: int = 0) -> void:
	notes = p_notes
	quality = p_quality
	degree = p_degree


func root() -> Note:
	return notes[0]


## True once the chord has been extended past a plain triad.
func has_seventh() -> bool:
	return notes.size() >= 4


## The pitch class of the added 7th, or -1 for a triad. Handed to the keyboard
## so the note that turns a triad into a 7th chord is visibly the odd one out.
func seventh_pitch_class() -> int:
	return notes[3].pitch_class() if has_seventh() else -1


## Chord symbol, e.g. "Dm", "B\u00b0", "G7".
func symbol() -> String:
	return root().display_name() + QUALITY_SUFFIX.get(quality, "?")


## Roman numeral in the parent key, e.g. "ii", "vii\u00b0", "V7".
func roman_numeral() -> String:
	var numeral: String = ROMAN[degree]
	if not QUALITY_IS_UPPER.get(quality, true):
		numeral = numeral.to_lower()
	return numeral + QUALITY_NUMERAL_SUFFIX.get(quality, "")


## Note names joined for display, e.g. "F \u2013 A \u2013 C".
func note_names() -> String:
	var parts := PackedStringArray()
	for n in notes:
		parts.append(n.display_name())
	return " \u2013 ".join(parts)


## The pitch classes to light up on a keyboard.
func pitch_classes() -> Array[int]:
	var out: Array[int] = []
	for n in notes:
		out.append(n.pitch_class())
	return out
