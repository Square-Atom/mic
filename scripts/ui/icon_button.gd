@tool
class_name IconButton
extends DrawnButton

## The drawn buttons the loop strip needs: add, delete, transport and the two
## tempo arrows.
##
## One script with a glyph enum rather than five near-identical files. They all
## share a plate, a size and a press; the only thing that differs is a handful
## of lines, and splitting that across five scripts would hide how alike they
## are.

enum Glyph {
	PLUS,
	TRASH,
	PLAY,
	STOP,
	ARROW_UP,
	ARROW_DOWN,
	INFO,
	CLOSE,
}

## Stroke weight, as a fraction of the button's shorter side. The floor keeps
## the trash can from disappearing on the small delete button, where a
## proportional stroke would land under a pixel.
const STROKE_RATIO := 0.082
const MIN_STROKE := 1.5

@export var glyph: Glyph = Glyph.PLUS:
	set(value):
		glyph = value
		queue_redraw()


func _draw_glyph(centre: Vector2, span: float, ink_color: Color) -> void:
	var stroke := maxf(MIN_STROKE, span * STROKE_RATIO)
	match glyph:
		Glyph.PLUS:
			_draw_plus(centre, span, ink_color, stroke)
		Glyph.TRASH:
			_draw_trash(centre, span, ink_color, stroke)
		Glyph.PLAY:
			_draw_play(centre, span, ink_color)
		Glyph.STOP:
			_draw_stop(centre, span, ink_color)
		Glyph.ARROW_UP:
			_draw_arrow(centre, span, ink_color, -1.0)
		Glyph.ARROW_DOWN:
			_draw_arrow(centre, span, ink_color, 1.0)
		Glyph.INFO:
			_draw_info(centre, span, ink_color, stroke)
		Glyph.CLOSE:
			_draw_close(centre, span, ink_color, stroke)


func _draw_plus(centre: Vector2, span: float, ink_color: Color, stroke: float) -> void:
	var arm := span * 0.22
	draw_line(centre - Vector2(arm, 0.0), centre + Vector2(arm, 0.0), ink_color, stroke, true)
	draw_line(centre - Vector2(0.0, arm), centre + Vector2(0.0, arm), ink_color, stroke, true)


## A tapered can with a lid and a handle. Drawn as outline rather than a solid
## shape so it stays legible at the delete button's size, where a filled
## silhouette would read as a blob.
func _draw_trash(centre: Vector2, span: float, ink_color: Color, stroke: float) -> void:
	var half_width := span * 0.19
	var height := span * 0.42
	var top := centre.y - height * 0.45
	var bottom := top + height
	# The handle sits above the lid, and the lid overhangs the can either side.
	draw_line(
		Vector2(centre.x - half_width * 0.42, top - stroke * 2.0),
		Vector2(centre.x + half_width * 0.42, top - stroke * 2.0),
		ink_color, stroke, true)
	draw_line(
		Vector2(centre.x - half_width * 1.28, top),
		Vector2(centre.x + half_width * 1.28, top),
		ink_color, stroke, true)
	# Sides taper inwards, which is what stops the can reading as a plain box.
	var foot := half_width * 0.78
	draw_line(Vector2(centre.x - half_width, top + stroke),
			Vector2(centre.x - foot, bottom), ink_color, stroke, true)
	draw_line(Vector2(centre.x + half_width, top + stroke),
			Vector2(centre.x + foot, bottom), ink_color, stroke, true)
	draw_line(Vector2(centre.x - foot, bottom),
			Vector2(centre.x + foot, bottom), ink_color, stroke, true)


## A right-pointing triangle, nudged left so its visual weight - which sits
## behind the point, not at it - lands on the centre of the plate.
func _draw_play(centre: Vector2, span: float, ink_color: Color) -> void:
	var reach := span * 0.27
	var origin := centre - Vector2(reach * 0.12, 0.0)
	draw_colored_polygon(PackedVector2Array([
		origin + Vector2(-reach * 0.80, -reach),
		origin + Vector2(-reach * 0.80, reach),
		origin + Vector2(reach, 0.0),
	]), ink_color)


func _draw_stop(centre: Vector2, span: float, ink_color: Color) -> void:
	var side := span * 0.40
	draw_rect(Rect2(centre - Vector2(side, side) * 0.5, Vector2(side, side)), ink_color, true)


## A lowercase i: a separate dot above a stem.
##
## Drawn rather than typed, like every other mark here. A letter set in the
## theme font would be the one glyph on screen whose weight and size came from
## somewhere else, and it would shift the moment the font did.
func _draw_info(centre: Vector2, span: float, ink_color: Color, stroke: float) -> void:
	var stem_top := centre.y - span * 0.08
	var stem_bottom := centre.y + span * 0.20
	draw_circle(Vector2(centre.x, centre.y - span * 0.20), stroke * 0.62,
			ink_color, true, -1.0, true)
	draw_line(Vector2(centre.x, stem_top), Vector2(centre.x, stem_bottom),
			ink_color, stroke, true)


func _draw_close(centre: Vector2, span: float, ink_color: Color, stroke: float) -> void:
	var arm := span * 0.19
	draw_line(centre + Vector2(-arm, -arm), centre + Vector2(arm, arm), ink_color, stroke, true)
	draw_line(centre + Vector2(-arm, arm), centre + Vector2(arm, -arm), ink_color, stroke, true)


## The tempo arrows. `facing` is -1 for up and 1 for down, so the two share one
## triangle instead of being written out twice with the signs flipped by hand.
func _draw_arrow(centre: Vector2, span: float, ink_color: Color, facing: float) -> void:
	var half_width := span * 0.24
	var half_height := span * 0.16
	draw_colored_polygon(PackedVector2Array([
		centre + Vector2(-half_width, -half_height * facing),
		centre + Vector2(half_width, -half_height * facing),
		centre + Vector2(0.0, half_height * facing),
	]), ink_color)
