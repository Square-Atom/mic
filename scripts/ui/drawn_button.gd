@tool
class_name DrawnButton
extends Control

## The chrome behind every button this app draws rather than labels.
##
## A word gets truncated at these sizes and a glyph depends on whatever the
## font happens to carry, so the marks are drawn. What they all share - the
## rounded plate, the hover and press shading, the corner that scales with the
## button - lives here; subclasses supply only the mark itself, through
## `_draw_glyph`.

signal pressed

## Every proportion is measured against the button's shorter side, so a button
## sized for a fingertip gets a mark to match instead of a small one adrift in
## a large box.
const CORNER_RATIO := 0.11

## The glyph's colour, when the default hover-following grey is not wanted.
## Fully transparent means "follow the hover state", which is what the dot
## buttons and the small controls do; the transport button opts out so that
## play and stop carry their own colour.
@export var glyph_tint := Color(0, 0, 0, 0):
	set(value):
		glyph_tint = value
		queue_redraw()

var _hovered := false
var _held := false
var _style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style = StyleBoxFlat.new()
	_style.set_border_width_all(1)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	_held = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_held = true
		queue_redraw()
		accept_event()
		return
	# Only a press that started on this button counts, so dragging off it and
	# releasing is the standard way to change your mind.
	if _held:
		_held = false
		queue_redraw()
		# A finger that landed here and then became half of a pinch is lifting
		# off a zoom, not finishing a press.
		if not PinchZoom.touch_became_gesture():
			pressed.emit()
		accept_event()


func _draw() -> void:
	if _style == null:
		return
	var span := minf(size.x, size.y)
	# The corner follows the button too, so a taller target does not end up
	# looking like a rectangle with a smaller button's corners stuck on it.
	_style.set_corner_radius_all(int(roundf(span * CORNER_RATIO)))
	_style.bg_color = Palette.PANEL_EDGE.lightened(0.16 if _held else (0.08 if _hovered else 0.0))
	_style.border_color = Palette.PANEL_EDGE.lightened(0.25)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
	_draw_glyph(size * 0.5, span, _ink())


## The colour the mark is drawn in. A tinted button still brightens under the
## cursor - the feedback is the point - it simply brightens within its own hue
## instead of turning grey.
func _ink() -> Color:
	if glyph_tint.a <= 0.0:
		return Palette.TEXT if _hovered or _held else Palette.TEXT_DIM
	return glyph_tint.lightened(0.18) if _hovered or _held else glyph_tint


## Draw the mark, centred on `centre` and sized against `span`. Subclasses
## override this and nothing else.
func _draw_glyph(_centre: Vector2, _span: float, _ink_color: Color) -> void:
	pass
