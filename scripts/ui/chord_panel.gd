class_name ChordPanel
extends PanelContainer

## The left-hand half of the screen: everything the selected key gives you.
## A header naming the key and its scale, a toggle between triads and sevenths,
## and seven ChordRows - one per diatonic degree.

const CHORD_ROW_SCENE := preload("res://scenes/chord_row.tscn")
const DEGREE_COUNT := 7

@onready var _key_title: Label = %KeyTitle
@onready var _key_info: Label = %KeyInfo
@onready var _scale_notes: Label = %ScaleNotes
@onready var _sevenths_toggle: CheckButton = %SeventhsToggle
@onready var _midi_toggle: CheckButton = %MidiToggle
@onready var _rows_box: VBoxContainer = %Rows

var _rows: Array[ChordRow] = []


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL.darkened(0.35)
	style.border_color = Palette.PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(0)
	add_theme_stylebox_override("panel", style)

	_key_title.add_theme_color_override("font_color", Palette.TEXT)
	_key_info.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_scale_notes.add_theme_color_override("font_color", Palette.TEXT)

	# The seven rows are built once; only their contents change afterwards.
	for i in DEGREE_COUNT:
		var row: ChordRow = CHORD_ROW_SCENE.instantiate()
		_rows_box.add_child(row)
		_rows.append(row)

	_sevenths_toggle.button_pressed = AppState.show_sevenths
	_sevenths_toggle.toggled.connect(_on_sevenths_toggled)
	_midi_toggle.button_pressed = AppState.midi_enabled
	_midi_toggle.toggled.connect(AppState.set_midi_enabled)
	AppState.key_changed.connect(_on_key_changed)
	AppState.sevenths_changed.connect(_on_sevenths_changed)
	_refresh()


func _on_sevenths_toggled(enabled: bool) -> void:
	AppState.set_show_sevenths(enabled)


func _on_key_changed(_key: KeyDef) -> void:
	_refresh()


func _on_sevenths_changed(_enabled: bool) -> void:
	_refresh()


func _refresh() -> void:
	var key: KeyDef = AppState.selected_key
	_key_title.text = key.display_name()

	_key_info.text = "%s   ·   %s" % [
		MusicTheory.signature_text(key), _companion_text(key),
	]
	_scale_notes.text = MusicTheory.scale_text(key)

	var chords := AppState.current_chords()
	for i in _rows.size():
		_rows[i].set_chord(chords[i], key)

## Names the key most worth knowing alongside this one. Major and minor point at
## each other, because that pairing is exactly what the circle's two rings show.
## Every other mode points at its parent major instead - the useful fact about
## C Dorian is that it is B-flat major's notes with C as home.
func _companion_text(key: KeyDef) -> String:
	# The spelling carries across too: C# major's relative is A# minor, not Bb minor.
	if key.is_major():
		var relative_minor := MusicTheory.key_at(
				key.circle_position, KeyDef.Mode.MINOR, key.use_alt_spelling)
		return "Relative minor: " + relative_minor.display_name()
	if key.is_minor():
		var relative_major := MusicTheory.key_at(
				key.circle_position, KeyDef.Mode.MAJOR, key.use_alt_spelling)
		return "Relative major: " + relative_major.display_name()
	return "Same notes as " + MusicTheory.parent_major(key).display_name()
