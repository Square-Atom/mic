class_name ModeDescription
extends VBoxContainer

## What the selected mode sounds like, under the mode buttons.
##
## The chips give a mode a name; this says why you would reach for it. The
## formula comes from MusicTheory rather than being written out here, so it
## always describes the scale the app is actually building.

const DESCRIPTION_FONT_SIZE := 17
const FORMULA_FONT_SIZE := 18

var _description: Label
var _formula: Label


func _ready() -> void:
	add_theme_constant_override("separation", 2)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_description = Label.new()
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)
	_description.add_theme_color_override("font_color", Palette.TEXT_DIM)
	add_child(_description)

	_formula = Label.new()
	_formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formula.add_theme_font_size_override("font_size", FORMULA_FONT_SIZE)
	_formula.add_theme_color_override("font_color", Palette.TEXT)
	add_child(_formula)

	AppState.key_changed.connect(_on_key_changed)
	_refresh()


func _on_key_changed(_key: KeyDef) -> void:
	_refresh()


func _refresh() -> void:
	var mode: int = AppState.selected_key.mode
	_description.text = MusicTheory.mode_description(mode)
	_formula.text = "Formula:   " + MusicTheory.mode_formula(mode)
