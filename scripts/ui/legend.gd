class_name Legend
extends HBoxContainer

## A row of colour swatches with labels. Without one of these the new wedge and
## key colours are just decoration - the legend is what turns them into
## information a beginner can actually read.
##
## Two presets, because the same colours are used in two places and must be
## explained in both. Entries are built from Palette so a colour is never
## written down twice.

enum Preset {
	CIRCLE,  ## Explains the circle-of-fifths wedge colours.
	PIANO,   ## Explains the piano key highlight colours.
}

@export var preset: Preset = Preset.CIRCLE
@export var swatch_size: int = 11
@export var label_font_size: int = 13

## The "7th" swatch, hidden while the sevenths toggle is off - explaining a
## colour that is nowhere on screen would only be confusing.
var _seventh_entry: Control = null


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	for entry in _entries():
		var node := _add_entry(entry[0], entry[1])
		if preset == Preset.PIANO and entry[1] == "7th":
			_seventh_entry = node
	if _seventh_entry != null:
		_seventh_entry.visible = AppState.show_sevenths
		AppState.sevenths_changed.connect(_on_sevenths_changed)


func _on_sevenths_changed(enabled: bool) -> void:
	_seventh_entry.visible = enabled


func _entries() -> Array:
	match preset:
		Preset.PIANO:
			return [
				[Palette.KEY_ROOT, "Root"],
				[Palette.KEY_CHORD_TONE, "Chord tone"],
				[Palette.KEY_SEVENTH, "7th"],
			]
		_:
			return [
				[Palette.ACCENT, "Tonic (I)"],
				[Palette.SUBDOMINANT, "Subdominant (IV)"],
				[Palette.DOMINANT, "Dominant (V)"],
				[Palette.RELATIVE, "Relative key"],
			]


func _add_entry(color: Color, text: String) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 6)

	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(swatch_size, swatch_size)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", label_font_size)
	label.add_theme_color_override("font_color", Palette.TEXT_DIM)

	entry.add_child(swatch)
	entry.add_child(label)
	add_child(entry)
	return entry
