@tool
class_name PianoKeyboard
extends Control

## One octave of piano keys, C through B, that can light up an arbitrary set of
## pitch classes. This is the reusable building block of the app - the chord
## panel stacks seven of them, and anything else that needs to show "which notes
## are these" can drop one in.
##
## Public contract:
##   set_highlighted(pitch_classes, root_pc, seventh_pc) - light these notes up
##   set_key_labels(labels)                              - name keys by pitch class
##   clear_highlights() / clear_key_labels()             - back to resting
##   key_pressed(pitch_class)                            - a key was clicked

signal key_pressed(pitch_class: int)

const WHITE_PITCH_CLASSES := [0, 2, 4, 5, 7, 9, 11]

## Black keys straddle the boundary *after* the white key at `after_white`,
## which is why there is no black key after index 2 (E/F) or 6 (B/C).
const BLACK_KEYS := [
	{"pc": 1, "after_white": 0},   # C#/Db
	{"pc": 3, "after_white": 1},   # D#/Eb
	{"pc": 6, "after_white": 3},   # F#/Gb
	{"pc": 8, "after_white": 4},   # G#/Ab
	{"pc": 10, "after_white": 5},  # A#/Bb
]

## A real piano's black keys are about 0.58 of a white key. These are a little
## wider than that so a two-character name like "B-flat" still fits on one.
const BLACK_WIDTH_RATIO := 0.68
const BLACK_HEIGHT_RATIO := 0.62

## Width of ONE white key. The keyboard derives its whole width from this and
## never stretches, because a keyboard that fills whatever space it is given
## ends up with keys far too fat to read as a piano.
@export var white_key_width: float = 24.0:
	set(value):
		white_key_width = value
		custom_minimum_size.x = value * WHITE_PITCH_CLASSES.size()
		_layout_keys()

@export var key_height: float = 66.0:
	set(value):
		key_height = value
		custom_minimum_size.y = value
		_layout_keys()


var _white_keys: Array[PianoKey] = []
var _black_keys: Array[PianoKey] = []
var _all_keys: Array[PianoKey] = []


func _ready() -> void:
	custom_minimum_size = Vector2(white_key_width * WHITE_PITCH_CLASSES.size(), key_height)
	_build_keys()
	_layout_keys()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_keys()


func _build_keys() -> void:
	# White keys are added first so the black keys end up later in the child
	# order. Godot draws children in order and hit-tests them in reverse, so
	# that single decision gives black keys both the correct overlap *and*
	# priority for clicks in the region where the two overlap.
	for pc in WHITE_PITCH_CLASSES:
		_white_keys.append(_make_key(pc, false))
	for entry in BLACK_KEYS:
		_black_keys.append(_make_key(entry["pc"], true))
	_all_keys = _white_keys + _black_keys


func _make_key(pitch_class: int, is_black: bool) -> PianoKey:
	var key := PianoKey.new()
	key.pitch_class = pitch_class
	key.is_black = is_black
	key.pressed.connect(_on_key_pressed)
	add_child(key)
	return key


func _layout_keys() -> void:
	if _white_keys.is_empty():
		return
	var white_w := size.x / float(WHITE_PITCH_CLASSES.size())
	for i in _white_keys.size():
		_white_keys[i].position = Vector2(i * white_w, 0.0)
		_white_keys[i].size = Vector2(white_w, size.y)

	var black_w := white_w * BLACK_WIDTH_RATIO
	for i in _black_keys.size():
		# Centre the black key on the seam between its two white neighbours.
		var seam := float(int(BLACK_KEYS[i]["after_white"]) + 1) * white_w
		_black_keys[i].position = Vector2(seam - black_w * 0.5, 0.0)
		_black_keys[i].size = Vector2(black_w, size.y * BLACK_HEIGHT_RATIO)


func _on_key_pressed(pitch_class: int) -> void:
	key_pressed.emit(pitch_class)


## Light up `pitch_classes`. `root_pc` and `seventh_pc` get their own accents so
## the note the chord is built on, and the note that extends it past a triad,
## are both distinguishable from the plain chord tones. Pass -1 to skip either.
func set_highlighted(pitch_classes: Array, root_pc: int = -1, seventh_pc: int = -1) -> void:
	for key in _all_keys:
		if root_pc >= 0 and key.pitch_class == root_pc:
			key.set_key_state(PianoKey.State.IS_ROOT)
		elif seventh_pc >= 0 and key.pitch_class == seventh_pc:
			key.set_key_state(PianoKey.State.IS_SEVENTH)
		elif pitch_classes.has(key.pitch_class):
			key.set_key_state(PianoKey.State.IN_CHORD)
		else:
			key.set_key_state(PianoKey.State.NORMAL)


func clear_highlights() -> void:
	for key in _all_keys:
		key.set_key_state(PianoKey.State.NORMAL)


## Name individual keys, as {pitch_class: text}. Keys not in the dictionary are
## left blank, so passing only the chord's notes labels exactly those.
func set_key_labels(labels: Dictionary) -> void:
	for key in _all_keys:
		key.label_text = labels.get(key.pitch_class, "")


func clear_key_labels() -> void:
	for key in _all_keys:
		key.label_text = ""


## Grey out every key that is not in `pitch_classes`. Useful for showing a scale
## as "these are the notes you have to work with".
func set_dimmed_except(pitch_classes: Array) -> void:
	for key in _all_keys:
		key.set_key_state(
			PianoKey.State.NORMAL if pitch_classes.has(key.pitch_class) else PianoKey.State.DIMMED
		)
