class_name ChordRow
extends PanelContainer

## One line of the cheatsheet: a chord's roman numeral, its symbol, its spelled
## notes, and a keyboard showing exactly which keys to press.
##
## Rows are created once and updated in place through `set_chord()`. Rebuilding
## them on every key change would throw away and re-create seven keyboards (84
## key nodes) for no reason, and would flicker while doing it.

## A weight-700 system font. The theme's default font has no bold face of its
## own, so the numeral column needs its own resource to stand out.
const BOLD_FONT := preload("res://themes/font_bold.tres")

@onready var _roman: Label = %Roman
@onready var _symbol: Label = %ChordName
@onready var _notes: Label = %NoteNames
@onready var _degree_name: Label = %DegreeName
@onready var _keyboard: PianoKeyboard = %Keyboard
@onready var _play_in_order: PlayButton = %PlayInOrder
@onready var _play_together: PlayButton = %PlayTogether

var _chord: Chord = null
var _key: KeyDef = null
## The chord as MIDI notes, kept because both the keyboard and the buttons
## need it and it is what the display and the sound agree on.
var _voicing := PackedInt32Array()


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	_roman.add_theme_font_override("font", BOLD_FONT)
	_symbol.add_theme_color_override("font_color", Palette.TEXT)

	_keyboard.key_pressed.connect(_on_keyboard_key_pressed)
	_play_in_order.pressed.connect(_on_play_in_order)
	_play_together.pressed.connect(_on_play_together)
	# set_chord may have been called before the node was ready; apply it now.
	if _chord != null:
		_apply()


## Show `chord` as it functions within `key`. Safe to call before the row has
## entered the tree. The key is passed in rather than read from AppState so the
## row stays usable outside this screen.
func set_chord(chord: Chord, key: KeyDef) -> void:
	_chord = chord
	_key = key
	if is_node_ready():
		_apply()


func _apply() -> void:
	_keyboard.highlight_color = _function_color()
	_roman.text = _chord.roman_numeral()
	_symbol.text = _chord.symbol()
	_notes.text = _chord.note_names()
	# One voicing drives both halves of the row, so what you see lit is exactly
	# what you hear when you press a button.
	_voicing = MusicTheory.chord_voicing(_chord)
	var seventh := _voicing[3] if _chord.has_seventh() else -1
	_keyboard.set_highlighted(_voicing, _voicing[0], seventh)
	# Label straight from the chord's own notes so the keyboard shows the
	# spelling the chord actually uses - B-flat in F major, never A-sharp.
	var labels := {}
	for i in _chord.notes.size():
		labels[_voicing[i]] = _chord.notes[i].display_name()
	_keyboard.set_key_labels(labels)

	# The numeral, its name and the note list take the chord's FAMILY colour,
	# while the keyboard keeps the primary-chord colouring. Two different facts
	# about the same chord, told in two different places: the text says which
	# family it belongs to, the keys say whether it is one of the three
	# primaries.
	_degree_name.text = MusicTheory.degree_name(_key, _chord)
	var family := _family_color()
	_roman.add_theme_color_override("font_color", family)
	_notes.add_theme_color_override("font_color", family)
	_degree_name.add_theme_color_override("font_color", family)


## The colour of this chord's functional family. Every degree has one, so all
## seven rows are coloured - unlike the keyboard, where only the three primary
## chords are picked out.
func _family_color() -> Color:
	match MusicTheory.chord_family(_chord):
		MusicTheory.Family.SUBDOMINANT:
			return Palette.SUBDOMINANT
		MusicTheory.Family.DOMINANT:
			return Palette.DOMINANT
	return Palette.ACCENT


## The colour family this row works in. The tonic, subdominant and dominant
## take the very colours the circle gives them, so one chord looks the same
## wherever it appears; the remaining degrees share a quiet blue-grey.
func _function_color() -> Color:
	match MusicTheory.chord_function(_key, _chord):
		MusicTheory.Function.TONIC:
			return Palette.ACCENT
		MusicTheory.Function.SUBDOMINANT:
			return Palette.SUBDOMINANT
		MusicTheory.Function.DOMINANT:
			return Palette.DOMINANT
	return Palette.DEGREE_NEUTRAL


func _on_keyboard_key_pressed(midi: int) -> void:
	AppState.activate_note(midi)


func _on_play_in_order() -> void:
	AppState.activate_chord(_voicing, true)


func _on_play_together() -> void:
	AppState.activate_chord(_voicing, false)



