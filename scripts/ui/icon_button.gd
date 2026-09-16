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

## How far the solid marks - the play triangle and the stop square - are rounded
## off, as a fraction of the button. Small on purpose: enough to take the needle
## off the triangle's point and the hard edge off the square, not so much that
## either stops reading as its shape.
const GLYPH_CORNER_RATIO := 0.05

## Points along each corner's arc. Four is plenty at the size these are drawn:
## the arc spans a few pixels, and more vertices cost more than they show.
const CORNER_SEGMENTS := 4

## Width of the hairline traced over a filled mark to soften its edge. One pixel
## is the whole point - it is a fade, not a border.
const SMOOTHING_WIDTH := 1.0

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
	_fill_smooth(_rounded(PackedVector2Array([
		origin + Vector2(-reach * 0.80, -reach),
		origin + Vector2(-reach * 0.80, reach),
		origin + Vector2(reach, 0.0),
	]), span * GLYPH_CORNER_RATIO), ink_color)


func _draw_stop(centre: Vector2, span: float, ink_color: Color) -> void:
	var half := span * 0.20
	_fill_smooth(_rounded(PackedVector2Array([
		centre + Vector2(-half, -half),
		centre + Vector2(half, -half),
		centre + Vector2(half, half),
		centre + Vector2(-half, half),
	]), span * GLYPH_CORNER_RATIO), ink_color)


## Fill a polygon and soften its edge.
##
## draw_colored_polygon has no antialiasing of its own, so the shape is filled
## and then its own outline traced back over it as a hairline. That hairline IS
## antialiased, and being the same colour it reads as a fade along the fill's
## edge rather than as a border - which is all the triangle's diagonals and the
## square's corner arcs need to stop looking stepped.
##
## The line is centred on the edge, so it softens outwards by half a pixel and
## the mark keeps the size it was measured for.
func _fill_smooth(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	# draw_polyline leaves the path open. Without closing it by hand, the edge
	# back to the first point keeps its hard step - on the triangle that is the
	# upper diagonal, which is the most visible edge on the mark.
	outline.append(points[0])
	draw_polyline(outline, color, SMOOTHING_WIDTH, true)


## A convex polygon with its corners rounded off, as a point list ready to fill.
##
## Each corner becomes the arc that sits tangent to both of its edges: the arc's
## centre lies along the corner's bisector, and it meets each edge the same
## distance back from the point. Sharper corners need to be met further back -
## which is why the triangle's tip is cut further in than the square's corners,
## and why both end up looking rounded by the same amount.
##
## The rounding lives in the point list rather than in a thick stroke traced
## round a sharp shape. A stroke wide enough to round a corner would push the
## mark outside the bounds it was measured against, and would leave the fill
## and the stroke disagreeing about where the edge is.
func _rounded(points: PackedVector2Array, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var count := points.size()
	for i in count:
		var corner := points[i]
		var previous := points[(i - 1 + count) % count]
		var following := points[(i + 1) % count]
		var to_previous := (previous - corner).normalized()
		var to_following := (following - corner).normalized()

		# Half the interior angle, which is what sets how far back the arc has to
		# meet each edge. A straight-through "corner" has no arc to draw.
		var half_angle := acos(clampf(to_previous.dot(to_following), -1.0, 1.0)) * 0.5
		if half_angle <= 0.001 or half_angle >= PI * 0.5 - 0.001:
			out.append(corner)
			continue

		# Never eat past the middle of an edge, or two corners sharing it would
		# round into each other and turn the shape inside out.
		var setback := minf(
			radius / tan(half_angle),
			minf(previous.distance_to(corner), following.distance_to(corner)) * 0.5)
		# The radius actually achieved, which is smaller than asked for whenever
		# the setback above had to be capped.
		var actual := setback * tan(half_angle)
		var start := corner + to_previous * setback
		var finish := corner + to_following * setback
		var arc_centre := corner + (to_previous + to_following).normalized() \
				* (actual / sin(half_angle))

		var from_angle := (start - arc_centre).angle()
		# The short way round: the arc of a corner never exceeds a half turn, so
		# wrapping into -PI..PI always picks the sweep that stays on the shape.
		var sweep := wrapf((finish - arc_centre).angle() - from_angle, -PI, PI)
		for step in CORNER_SEGMENTS + 1:
			var t := float(step) / CORNER_SEGMENTS
			out.append(arc_centre + Vector2(actual, 0.0).rotated(from_angle + sweep * t))
	return out


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
