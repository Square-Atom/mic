class_name KeyDef
extends RefCounted

## Identifies one key on the circle of fifths: a tonic, a mode, and the circle
## position it occupies. Position is carried along because the circle's geometry
## (relative keys, neighbouring keys, key signature) is derived from it directly.

## The seven diatonic modes. The ORDER matters: each value is the scale degree
## of the parent major scale that the mode starts on, which is what lets the
## interval table be a plain rotation and the fifths offset be a lookup.
## Major and minor keep their familiar names - they are Ionian and Aeolian.
enum Mode { MAJOR, DORIAN, PHRYGIAN, LYDIAN, MIXOLYDIAN, MINOR, LOCRIAN }

var tonic: Note
var mode: int = Mode.MAJOR
## 0-11, clockwise from C at the top.
var circle_position: int = 0
## Which of the position's two names this key is. Only positions 5, 6 and 7 have
## a second one; everywhere else this is always false.
var use_alt_spelling: bool = false
## The ring the circle draws this key on - MAJOR for the outer, MINOR for the
## inner. Held separately from `mode` so that changing mode leaves the wedge
## alone: C Dorian is still drawn on C's wedge, because its tonic is still C.
## Only the notes inside change, which is the point of switching mode.
var circle_ring: int = Mode.MAJOR


func _init(p_tonic: Note = null, p_mode: int = Mode.MAJOR, p_position: int = 0,
		p_use_alt: bool = false, p_ring: int = -1) -> void:
	tonic = p_tonic if p_tonic != null else Note.new(0, 0)
	mode = p_mode
	circle_position = p_position
	use_alt_spelling = p_use_alt
	# A key picked straight off the circle sits on the ring it was picked from.
	circle_ring = p_ring if p_ring >= 0 else (Mode.MINOR if p_mode == Mode.MINOR else Mode.MAJOR)


func is_major() -> bool:
	return mode == Mode.MAJOR


func is_minor() -> bool:
	return mode == Mode.MINOR


## "Major", "Dorian", "Minor", and so on.
func mode_name() -> String:
	return MusicTheory.MODE_NAMES[mode]


## e.g. "C Major", "B\u266d Minor".
func display_name() -> String:
	return "%s %s" % [tonic.display_name(), mode_name()]


## Short form used on the circle wedges, e.g. "C", "Am".
func short_name() -> String:
	return tonic.display_name() + ("" if is_major() else "m")


func equals(other: KeyDef) -> bool:
	if other == null:
		return false
	# Spelling is part of the identity: Db major and C# major occupy the same
	# position and mode but are different keys to look at.
	return circle_position == other.circle_position 			and mode == other.mode 			and circle_ring == other.circle_ring 			and use_alt_spelling == other.use_alt_spelling
