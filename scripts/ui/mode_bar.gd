class_name ModeBar
extends HBoxContainer

## The mode selector under the circle.
##
## Holds the TONIC still and changes the flavour: picking Mixolydian while in C
## gives C Mixolydian, not G. The circle does not move either - C stays lit with
## F and G either side, because those chords keep their roots. What changes is
## the chords themselves, which is what the table and keyboards show.

const CHIP_SCENE := preload("res://scenes/mode_chip.tscn")
## The row labels itself, so the heading travels with it rather than being a
## separate node in the column that has to be kept in step.
const BOLD_FONT := preload("res://themes/font_bold.tres")
const HEADING := "MODE"
## Tracks the chip's bottom padding plus its border, so the heading follows if
## the buttons are ever resized.
const HEADING_LIFT := ModeChip.PADDING_V + 1
const ALIAS_FONT_SIZE := 17
const COLUMN_SEPARATION := 3

var _chips: Array[ModeChip] = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_build_heading())
	for mode in MusicTheory.MODE_NAMES.size():
		add_child(_build_column(mode))
	AppState.key_changed.connect(_on_key_changed)
	_refresh()


## Sits at the head of the row. Pulled to the bottom so it lines up with the
## chips rather than with the names above them, then lifted by the chip's own
## bottom padding - aligning the boxes is not the same as aligning the text
## inside them.
func _build_heading() -> Control:
	var heading := Label.new()
	heading.text = HEADING
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Palette.TEXT_FAINT)

	var wrapper := MarginContainer.new()
	wrapper.add_theme_constant_override("margin_bottom", HEADING_LIFT)
	wrapper.size_flags_vertical = Control.SIZE_SHRINK_END
	wrapper.add_child(heading)
	return wrapper


## A column is the familiar name sitting above its chip, outside the button, so
## "Major" reads as a gloss on Ionian rather than part of the control. The five
## modes with no other name still get the label, left empty, so every chip in
## the row lines up.
func _build_column(mode: int) -> VBoxContainer:
	var classical: String = MusicTheory.MODE_CLASSICAL_NAMES[mode]
	var familiar: String = MusicTheory.MODE_NAMES[mode]

	var alias := Label.new()
	alias.text = "" if familiar == classical else familiar
	alias.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alias.add_theme_font_size_override("font_size", ALIAS_FONT_SIZE)
	alias.add_theme_font_override("font", BOLD_FONT)
	alias.add_theme_color_override("font_color", Palette.RELATIVE)

	var chip: ModeChip = CHIP_SCENE.instantiate()
	chip.set_mode_name(classical)
	chip.pressed.connect(_on_chip_pressed.bind(mode))
	_chips.append(chip)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", COLUMN_SEPARATION)
	column.add_child(alias)
	column.add_child(chip)
	return column


func _on_key_changed(_key: KeyDef) -> void:
	_refresh()


func _on_chip_pressed(mode: int) -> void:
	AppState.set_mode(mode)


func _refresh() -> void:
	for mode in _chips.size():
		_chips[mode].set_active(mode == AppState.selected_key.mode)
