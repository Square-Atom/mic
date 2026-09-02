class_name ModeChip
extends PanelContainer

## One mode in the selector beside the circle.

signal pressed

@onready var _label: Label = %ModeName

## Held until the node is in the tree: the bar builds a chip, names it and only
## then parents it, so the label does not exist yet at that point.
var _pending_name := ""
var _hovered := false
var _active := false
var _style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style = StyleBoxFlat.new()
	_style.set_corner_radius_all(6)
	_style.set_border_width_all(1)
	_style.content_margin_left = 10
	_style.content_margin_right = 10
	_style.content_margin_top = 5
	_style.content_margin_bottom = 5
	add_theme_stylebox_override("panel", _style)
	mouse_entered.connect(func(): _hovered = true; _restyle())
	mouse_exited.connect(func(): _hovered = false; _restyle())
	if not _pending_name.is_empty():
		_label.text = _pending_name
	_restyle()


## Safe to call before the chip has entered the tree.
func set_mode_name(text: String) -> void:
	_pending_name = text
	if is_node_ready():
		_label.text = text


func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	_restyle()


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		pressed.emit()
		accept_event()


func _restyle() -> void:
	if _style == null:
		return
	_style.bg_color = Palette.PANEL.lightened(0.06 if _hovered else 0.0)
	_style.border_color = Palette.ACCENT if _active else Palette.PANEL_EDGE
	_style.set_border_width_all(2 if _active else 1)
	_label.add_theme_color_override(
		"font_color", Palette.ACCENT if _active else Palette.TEXT_DIM)
