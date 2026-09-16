class_name LoopSlot
extends VBoxContainer

## One chord in the loop: its roman numeral in a box, with a delete button
## underneath.
##
## Built in code rather than from a scene because slots are created and thrown
## away constantly - every add, delete and reorder rebuilds the strip - and a
## scene file for eight nodes that never sit still is more indirection than it
## saves. The chord rows, which are made once and updated forever, are the
## opposite case and stay a scene.
##
## The box is the drag handle. Dropping it elsewhere in the strip reorders the
## loop; dropping it anywhere else deletes it, which the strip works out from
## the drag having failed rather than from any hit-testing of its own.

## Identifies this script's drag payload, so the strip can tell a slot being
## reordered from whatever else the engine might be carrying.
const DRAG_TYPE := "mic_loop_slot"

const BOLD_FONT := preload("res://themes/font_bold.tres")

const BOX_MIN_SIZE := Vector2(74.0, 58.0)
const DELETE_MIN_SIZE := Vector2(74.0, 22.0)
const NUMERAL_FONT_SIZE := 26
const CORNER_RADIUS := 8

signal drag_started(index: int)

var index := -1

var _box: PanelContainer
var _numeral: Label
var _delete: IconButton
var _style: StyleBoxFlat
var _color := Palette.DEGREE_NEUTRAL
var _active := false


func _init() -> void:
	# The slot as a whole is the drag target; the delete button sits on top of
	# it and takes its own clicks first, as any STOP child does.
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_constant_override("separation", 4)

	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(CORNER_RADIUS)
	_style.set_border_width_all(2)
	_style.set_content_margin_all(6)

	_box = PanelContainer.new()
	_box.custom_minimum_size = BOX_MIN_SIZE
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_stylebox_override("panel", _style)
	add_child(_box)

	_numeral = Label.new()
	_numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_numeral.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_numeral.add_theme_font_override("font", BOLD_FONT)
	_numeral.add_theme_font_size_override("font_size", NUMERAL_FONT_SIZE)
	_box.add_child(_numeral)

	_delete = IconButton.new()
	_delete.glyph = IconButton.Glyph.TRASH
	_delete.custom_minimum_size = DELETE_MIN_SIZE
	_delete.tooltip_text = "Remove this chord from the loop"
	_delete.pressed.connect(_on_delete_pressed)
	add_child(_delete)


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Drag to reorder, or drag out of the strip to remove"
	_repaint()


## Fill the slot in. `color` is the chord's functional family, the same one the
## matching row uses, so a numeral means the same thing in both places.
func set_slot(p_index: int, numeral: String, color: Color) -> void:
	index = p_index
	_numeral.text = numeral
	_color = color
	if is_node_ready():
		_repaint()


## Mark this slot as the one currently sounding.
func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	if is_node_ready():
		_repaint()


func _repaint() -> void:
	# Playing lifts the slot into its own colour; resting leaves it a panel with
	# a coloured numeral, so the highlight travelling along the strip is the
	# loudest thing on it.
	_style.bg_color = _color.darkened(0.55) if _active else Palette.PANEL
	_style.border_color = _color if _active else Palette.PANEL_EDGE.lightened(0.25)
	_numeral.add_theme_color_override("font_color", Palette.TEXT if _active else _color)
	_box.queue_redraw()


func _on_delete_pressed() -> void:
	ChordLoop.remove_slot(index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if index < 0:
		return null
	set_drag_preview(_make_preview())
	# The strip has to know which slot left, because a drag that lands nowhere
	# is a delete and by then the slot itself is no longer under the cursor.
	drag_started.emit(index)
	return {"type": DRAG_TYPE, "index": index}


## A copy of the box alone, without the delete button - what is being moved is
## the chord, and carrying its trash can along would suggest otherwise.
func _make_preview() -> Control:
	var preview_style := StyleBoxFlat.new()
	preview_style.set_corner_radius_all(CORNER_RADIUS)
	preview_style.set_border_width_all(2)
	preview_style.set_content_margin_all(6)
	preview_style.bg_color = _color.darkened(0.45)
	preview_style.border_color = _color

	var panel := PanelContainer.new()
	panel.custom_minimum_size = BOX_MIN_SIZE
	panel.modulate = Color(1.0, 1.0, 1.0, 0.85)
	panel.add_theme_stylebox_override("panel", preview_style)

	var label := Label.new()
	label.text = _numeral.text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", BOLD_FONT)
	label.add_theme_font_size_override("font_size", NUMERAL_FONT_SIZE)
	label.add_theme_color_override("font_color", Palette.TEXT)
	panel.add_child(label)
	return panel
