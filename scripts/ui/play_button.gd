@tool
class_name PlayButton
extends Control

## The small button beside a chord row that sounds the chord.
##
## Drawn rather than labelled: at this size a word gets truncated and a glyph
## depends on whatever the font happens to carry. Three dots rising left to
## right reads as "one after another"; three dots stacked reads as "all at
## once" - which is exactly how the two chords differ on paper.

signal pressed

enum Mode {
	SEQUENCE,  ## Root, then third, then fifth.
	TOGETHER,  ## All of them struck at the same moment.
}

const DOT_COUNT := 3

## The glyph is a fraction of the button rather than a fixed size, so a button
## sized for a fingertip gets a mark to match instead of a small one adrift in
## a large box. Measured against the shorter side, which is what constrains the
## stacked arrangement.
const DOT_SPACING_RATIO := 0.233
const DOT_RADIUS_RATIO := 0.087
const CORNER_RATIO := 0.11

@export var mode: Mode = Mode.SEQUENCE:
	set(value):
		mode = value
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
	if _held:
		_held = false
		queue_redraw()
		pressed.emit()
		accept_event()


func _draw() -> void:
	if _style == null:
		return
	var span := minf(size.x, size.y)
	# The corner follows the button too, so a taller target does not end up
	# looking like a rectangle with the old button's corners stuck on it.
	_style.set_corner_radius_all(int(roundf(span * CORNER_RATIO)))
	_style.bg_color = Palette.PANEL_EDGE.lightened(0.16 if _held else (0.08 if _hovered else 0.0))
	_style.border_color = Palette.PANEL_EDGE.lightened(0.25)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))

	var centre := size * 0.5
	var spacing := span * DOT_SPACING_RATIO
	var radius := span * DOT_RADIUS_RATIO
	var ink := Palette.TEXT if _hovered or _held else Palette.TEXT_DIM
	for i in DOT_COUNT:
		var step := float(i) - (DOT_COUNT - 1) * 0.5
		var offset := Vector2(0.0, step * spacing)
		if mode == Mode.SEQUENCE:
			offset = Vector2(step * spacing, -step * spacing)
		draw_circle(centre + offset, radius, ink, true, -1.0, true)
