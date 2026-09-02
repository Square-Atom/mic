class_name KeyDef
extends RefCounted

## Identifies one key on the circle of fifths: a tonic, a mode, and the circle
## position it occupies. Position is carried along because the circle's geometry
## (relative keys, neighbouring keys, key signature) is derived from it directly.

enum Mode { MAJOR, MINOR }

var tonic: Note
var mode: int = Mode.MAJOR
## 0-11, clockwise from C at the top.
var circle_position: int = 0
## Which of the position's two names this key is. Only positions 5, 6 and 7 have
## a second one; everywhere else this is always false.
var use_alt_spelling: bool = false


func _init(p_tonic: Note = null, p_mode: int = Mode.MAJOR, p_position: int = 0,
		p_use_alt: bool = false) -> void:
	tonic = p_tonic if p_tonic != null else Note.new(0, 0)
	mode = p_mode
	circle_position = p_position
	use_alt_spelling = p_use_alt


func is_major() -> bool:
	return mode == Mode.MAJOR


## e.g. "C Major", "B\u266d Minor".
func display_name() -> String:
	return "%s %s" % [tonic.display_name(), "Major" if is_major() else "Minor"]


## Short form used on the circle wedges, e.g. "C", "Am".
func short_name() -> String:
	return tonic.display_name() + ("" if is_major() else "m")


func equals(other: KeyDef) -> bool:
	if other == null:
		return false
	# Spelling is part of the identity: Db major and C# major occupy the same
	# position and mode but are different keys to look at.
	return circle_position == other.circle_position 			and mode == other.mode 			and use_alt_spelling == other.use_alt_spelling
