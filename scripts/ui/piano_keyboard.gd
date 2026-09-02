@tool
class_name PianoKeyboard
extends Control

## Two octaves of piano keys, C4 to B5, that can light up an arbitrary set of
## notes. This is the reusable building block of the app - the chord panel
## stacks seven of them, and anything else that needs to show "which notes are
## these" can drop one in.
##
## Two octaves rather than one because chords are voiced in root position: a
## chord rooted above C would otherwise have to wrap, and the keys would read
## left-to-right in a different order from the one they sound in.
##
## Public contract:
##   highlight_color                                       - the colour family to light in
##   set_highlighted(notes, root_midi, seventh_midi)       - light these notes up
##   set_key_labels(labels)                                - name keys by MIDI note
##   clear_highlights() / clear_key_labels()               - back to resting
##   key_pressed(midi)                                     - a key was clicked

signal key_pressed(midi: int)

const OCTAVES := 2
const BASE_MIDI := 60  # C4
## Semitone offset of each white key within an octave.
const WHITE_OFFSETS := [0, 2, 4, 5, 7, 9, 11]
const WHITE_PER_OCTAVE := 7

## Black keys straddle the boundary *after* the white key at `after_white`,
## which is why there is none after index 2 (E/F) or 6 (B/C).
const BLACK_KEYS := [
	{"offset": 1, "after_white": 0},   # C#/Db
	{"offset": 3, "after_white": 1},   # D#/Eb
	{"offset": 6, "after_white": 3},   # F#/Gb
	{"offset": 8, "after_white": 4},   # G#/Ab
	{"offset": 10, "after_white": 5},  # A#/Bb
]

## A real piano's black keys are about 0.58 of a white key. These are a little
## wider than that so a two-character name like "B-flat" still fits on one.
const BLACK_WIDTH_RATIO := 0.68
const BLACK_HEIGHT_RATIO := 0.62

## Width of ONE white key. The keyboard derives its whole width from this and
## never stretches, because a keyboard that fills whatever space it is given
## ends up with keys far too fat to read as a piano.
@export var white_key_width: float = 26.0:
	set(value):
		white_key_width = value
		custom_minimum_size.x = value * _white_key_count()
		_layout_keys()

@export var key_height: float = 76.0:
	set(value):
		key_height = value
		custom_minimum_size.y = value
		_layout_keys()

## The colour this keyboard highlights in. The keyboard has no opinion about
## what a highlight means, so the caller decides - which is what lets each chord
## row colour its keys by the chord's role in the key.
var highlight_color: Color = Palette.ACCENT:
	set(value):
		highlight_color = value
		for key in _all_keys:
			key.highlight_base = value

var _white_keys: Array[PianoKey] = []
var _black_keys: Array[PianoKey] = []
var _all_keys: Array[PianoKey] = []


static func _white_key_count() -> int:
	return OCTAVES * WHITE_PER_OCTAVE


func _ready() -> void:
	custom_minimum_size = Vector2(white_key_width * _white_key_count(), key_height)
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
	for octave in OCTAVES:
		for offset in WHITE_OFFSETS:
			_white_keys.append(_make_key(BASE_MIDI + octave * 12 + offset, false))
	for octave in OCTAVES:
		for entry in BLACK_KEYS:
			_black_keys.append(_make_key(BASE_MIDI + octave * 12 + int(entry["offset"]), true))
	_all_keys = _white_keys + _black_keys


func _make_key(midi: int, is_black: bool) -> PianoKey:
	var key := PianoKey.new()
	key.midi = midi
	key.is_black = is_black
	key.highlight_base = highlight_color
	key.pressed.connect(_on_key_pressed)
	add_child(key)
	return key


func _layout_keys() -> void:
	if _white_keys.is_empty():
		return
	var white_w := size.x / float(_white_key_count())
	for i in _white_keys.size():
		_white_keys[i].position = Vector2(i * white_w, 0.0)
		_white_keys[i].size = Vector2(white_w, size.y)

	# Walk the octaves in the same order they were built, so each key is found
	# by construction rather than by unpicking its index.
	var black_w := white_w * BLACK_WIDTH_RATIO
	var index := 0
	for octave in OCTAVES:
		for entry in BLACK_KEYS:
			var white_index := octave * WHITE_PER_OCTAVE + int(entry["after_white"])
			# Centre the black key on the seam between its two white neighbours.
			var seam := float(white_index + 1) * white_w
			_black_keys[index].position = Vector2(seam - black_w * 0.5, 0.0)
			_black_keys[index].size = Vector2(black_w, size.y * BLACK_HEIGHT_RATIO)
			index += 1


func _on_key_pressed(midi: int) -> void:
	key_pressed.emit(midi)


## Light up `notes`. `root_midi` and `seventh_midi` get their own accents so the
## note the chord is built on, and the note that extends it past a triad, are
## both distinguishable from the plain chord tones. Pass -1 to skip either.
func set_highlighted(notes: Array, root_midi: int = -1, seventh_midi: int = -1) -> void:
	for key in _all_keys:
		if root_midi >= 0 and key.midi == root_midi:
			key.set_key_state(PianoKey.State.IS_ROOT)
		elif seventh_midi >= 0 and key.midi == seventh_midi:
			key.set_key_state(PianoKey.State.IS_SEVENTH)
		elif notes.has(key.midi):
			key.set_key_state(PianoKey.State.IN_CHORD)
		else:
			key.set_key_state(PianoKey.State.NORMAL)


func clear_highlights() -> void:
	for key in _all_keys:
		key.set_key_state(PianoKey.State.NORMAL)


## Name individual keys, as {midi: text}. Keys not in the dictionary are left
## blank, so passing only the chord's notes labels exactly those.
func set_key_labels(labels: Dictionary) -> void:
	for key in _all_keys:
		key.label_text = labels.get(key.midi, "")


func clear_key_labels() -> void:
	for key in _all_keys:
		key.label_text = ""
