class_name Note
extends RefCounted

## A *spelled* musical note: a letter name plus an accidental.
##
## We deliberately do NOT store a bare pitch class (0-11). Pitch classes cannot
## tell F major's fourth degree (B flat) apart from A sharp, even though only one
## of those spellings is correct in that key. Storing letter + accidental keeps
## the spelling, and the pitch class is derived on demand.

## Semitone distance of each natural letter from C, indexed by `letter`.
const LETTER_SEMITONES := [0, 2, 4, 5, 7, 9, 11]
const LETTER_NAMES := ["C", "D", "E", "F", "G", "A", "B"]

## Accidental glyphs keyed by semitone offset. Double flat / double sharp are
## included because keys like D sharp minor can legitimately produce them.
const ACCIDENTAL_NAMES := {-2: "\u266d\u266d", -1: "\u266d", 0: "", 1: "\u266f", 2: "\u00d7"}

## 0 = C, 1 = D, 2 = E, 3 = F, 4 = G, 5 = A, 6 = B.
var letter: int = 0
## Semitone offset applied to the letter, from -2 (double flat) to +2 (double sharp).
var accidental: int = 0


func _init(p_letter: int = 0, p_accidental: int = 0) -> void:
	letter = p_letter
	accidental = p_accidental


## The 0-11 pitch class this note sounds as. Wraps so that B sharp -> 0, C flat -> 11.
func pitch_class() -> int:
	return wrapi(LETTER_SEMITONES[letter] + accidental, 0, 12)


## Human-readable name, e.g. "B\u266d", "F\u266f", "C".
func display_name() -> String:
	return LETTER_NAMES[letter] + ACCIDENTAL_NAMES.get(accidental, "?")


## Number of letter steps from this note up to `other`, ignoring octaves (0-6).
func letter_distance(other: Note) -> int:
	return wrapi(other.letter - letter, 0, 7)
