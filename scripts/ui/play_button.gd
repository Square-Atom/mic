@tool
class_name PlayButton
extends DrawnButton

## The small button beside a chord row that sounds the chord.
##
## Three dots rising left to right reads as "one after another"; three dots
## stacked reads as "all at once" - which is exactly how the two chords differ
## on paper. The plate, the hover shading and the press handling come from
## DrawnButton; only the dots belong to this file.

enum Mode {
	SEQUENCE,  ## Root, then third, then fifth.
	TOGETHER,  ## All of them struck at the same moment.
}

const DOT_COUNT := 3

const DOT_SPACING_RATIO := 0.233
const DOT_RADIUS_RATIO := 0.087

@export var mode: Mode = Mode.SEQUENCE:
	set(value):
		mode = value
		queue_redraw()


func _draw_glyph(centre: Vector2, span: float, ink_color: Color) -> void:
	var spacing := span * DOT_SPACING_RATIO
	var radius := span * DOT_RADIUS_RATIO
	for i in DOT_COUNT:
		var step := float(i) - (DOT_COUNT - 1) * 0.5
		var offset := Vector2(0.0, step * spacing)
		if mode == Mode.SEQUENCE:
			offset = Vector2(step * spacing, -step * spacing)
		draw_circle(centre + offset, radius, ink_color, true, -1.0, true)
