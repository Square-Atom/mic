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
@onready var _keyboard: PianoKeyboard = %Keyboard

var _chord: Chord = null
var _key: KeyDef = null


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	_roman.add_theme_font_override("font", BOLD_FONT)
	_roman.add_theme_color_override("font_color", Palette.ACCENT)
	_symbol.add_theme_color_override("font_color", Palette.TEXT)
	_notes.add_theme_color_override("font_color", Palette.TEXT_DIM)

	_keyboard.key_pressed.connect(_on_keyboard_key_pressed)
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
	_keyboard.set_highlighted(
		_chord.pitch_classes(), _chord.root().pitch_class(), _chord.seventh_pitch_class()
	)
	# Label straight from the chord's own notes so the keyboard shows the
	# spelling the chord actually uses - B-flat in F major, never A-sharp.
	var labels := {}
	for note in _chord.notes:
		labels[note.pitch_class()] = note.display_name()
	_keyboard.set_key_labels(labels)


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



func _on_keyboard_key_pressed(pitch_class: int) -> void:
	AppState.note_activated.emit(pitch_class)


func _gui_input(event: InputEvent) -> void:
	if _chord == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# Nothing listens to this yet - it is the hook a future audio layer
			# plugs into without this row needing to know about it.
			AppState.chord_activated.emit(_chord)
			accept_event()
