class_name Legend
extends HBoxContainer

## The swatch row under the circle, naming what each wedge colour means.
## Without it the wedge colours are decoration; with it they are information.
##
## The keyboards used to carry a legend of their own. They no longer need one:
## a row's colour comes from the chord's function and its shading from each
## note's place in the chord, and both sit inches from the chord's own name,
## roman numeral and note list. A legend that restates its neighbour is noise.

const SWATCH_SIZE := 13
const LABEL_FONT_SIZE := 16
const ENTRY_SEPARATION := 6
const ROW_SEPARATION := 16


func _ready() -> void:
	add_theme_constant_override("separation", ROW_SEPARATION)
	# Colours come straight from Palette, never re-typed as literals here.
	_add_entry(Palette.ACCENT, "Tonic (I)")
	_add_entry(Palette.SUBDOMINANT, "Subdominant (IV)")
	_add_entry(Palette.DOMINANT, "Dominant (V)")
	# Outlined, because the circle marks the related key with an inner border
	# rather than a fill - a solid swatch here would describe the wrong thing.
	_add_entry(Palette.RELATIVE, "Relative key", true)


func _add_entry(color: Color, text: String, outlined: bool = false) -> void:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", ENTRY_SEPARATION)

	var swatch := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.0) if outlined else color
	if outlined:
		style.set_border_width_all(2)
		style.border_color = color
	swatch.add_theme_stylebox_override("panel", style)
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Palette.TEXT_DIM)

	entry.add_child(swatch)
	entry.add_child(label)
	add_child(entry)
