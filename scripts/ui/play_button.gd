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
const DOT_RADIUS := 3.9
const DOT_SPACING := 10.5
const CORNER_RADIUS := 7

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
	_style.set_corner_radius_all(CORNER_RADIUS)
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
	_style.bg_color = Palette.PANEL_EDGE.lightened(0.16 if _held else (0.08 if _hovered else 0.0))
	_style.border_color = Palette.PANEL_EDGE.lightened(0.25)
	draw_style_box(_style, Rect2(Vector2.ZERO, size))

	var centre := size * 0.5
	var ink := Palette.TEXT if _hovered or _held else Palette.TEXT_DIM
	for i in DOT_COUNT:
		var step := float(i) - (DOT_COUNT - 1) * 0.5
		var offset := Vector2(step * DOT_SPACING, -step * DOT_SPACING) if mode == Mode.SEQUENCE \
				else Vector2(0.0, step * DOT_SPACING)
		draw_circle(centre + offset, DOT_RADIUS, ink, true, -1.0, true)
