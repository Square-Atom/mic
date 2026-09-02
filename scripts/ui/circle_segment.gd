@tool
class_name CircleSegment
extends Control

## One clickable wedge of the circle of fifths.
##
## Every segment's rectangle covers the whole circle, so the twelve wedges of a
## ring all overlap completely. What keeps them from fighting over the mouse is
## `_has_point()`: it hit-tests in POLAR space, so a segment claims a pixel only
## if that pixel really is inside its own arc. The engine then treats each wedge
## as an ordinary button - pixel-accurate hover, no rectangular dead zones, and
## exactly one wedge responding to any given point.

signal selected(position: int, mode: int, use_alt: bool)

enum State {
	NORMAL,       ## Resting.
	TONIC,        ## The key the user picked - home.
	DOMINANT,     ## Its V, one step clockwise. The chord that pulls back home.
	SUBDOMINANT,  ## Its IV, one step anticlockwise. The chord that moves away.
}

## How far the drawn wedge is pulled in from its true hit area, so neighbouring
## wedges read as separate tiles. Hit-testing still uses the full arc, so the
## gaps are visual only and never swallow a click.
const DRAW_ANGLE_PAD := 0.010
const DRAW_RADIUS_PAD := 2.0
## Arc tessellation step. 2 degrees is smooth at any size we render at.
const ARC_STEP := 0.0349

## The related key is drawn as an inner outline rather than a fill, because a
## wedge can be two things at once - in Lydian the parent IS the dominant - and
## a second fill colour would have to fight the first for the same pixels.
##
## The stroke is centred on its path, so the path is inset by half the width
## plus the gap. Expressing it as a GAP is what makes the tuning obvious: it is
## the bare space left outside the outline, and at zero the outline sits flush
## to the wedge's edge with no rim of fill showing past it.
const COMPANION_GAP := 0.0
const COMPANION_WIDTH := 5.0

var circle_position: int = 0
var mode: int = KeyDef.Mode.MAJOR
## Which of the position's two spellings this wedge is. Positions with only one
## name always have this false.
var use_alt: bool = false
var label: String = ""

## Where this wedge sits within its ring, as fractions from the inner edge to
## the outer. A position with two names splits its ring band in half so each
## spelling becomes its own button; every other wedge takes the whole band.
var band_from: float = 0.0
var band_to: float = 1.0

var centre: Vector2 = Vector2.ZERO
var inner_radius: float = 0.0
var outer_radius: float = 0.0
var start_angle: float = 0.0
var end_angle: float = 0.0

## True when this wedge is also the related key. Kept apart from `_state` so
## a wedge can carry a function AND the relation at the same time.
var _is_companion: bool = false
var _state: int = State.NORMAL
var _hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Position the wedge in polar space. Called by the parent on every resize.
func configure(p_centre: Vector2, p_inner: float, p_outer: float, p_start: float, p_end: float) -> void:
	centre = p_centre
	inner_radius = p_inner
	outer_radius = p_outer
	start_angle = p_start
	end_angle = p_end
	queue_redraw()


func set_segment_state(new_state: int) -> void:
	if new_state == _state:
		return
	_state = new_state
	queue_redraw()


## Polar hit test - the reason overlapping wedges behave as separate buttons.
func _has_point(point: Vector2) -> bool:
	if outer_radius <= 0.0:
		return false
	var offset := point - centre
	var radius := offset.length()
	if radius < inner_radius or radius > outer_radius:
		return false
	# Rebase the point's angle onto the wedge's own start. Wrapping into
	# [0, TAU) makes the comparison correct even for the wedge that straddles
	# the -PI/+PI seam, which a plain `start <= a and a <= end` would miss.
	var relative_angle := wrapf(offset.angle() - start_angle, 0.0, TAU)
	return relative_angle <= (end_angle - start_angle)


func _on_mouse_entered() -> void:
	_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			selected.emit(circle_position, mode, use_alt)
			accept_event()


func _fill_color() -> Color:
	match _state:
		State.TONIC:
			return Palette.ACCENT
		State.DOMINANT:
			return Palette.DOMINANT
		State.SUBDOMINANT:
			return Palette.SUBDOMINANT
		_:
			return Palette.RING_MAJOR if mode == KeyDef.Mode.MAJOR else Palette.RING_MINOR


## Tessellate the wedge into a polygon: out along the outer arc, back along the
## inner one. Padding is applied here only, never to the hit test. `inset` pulls
## the whole shape further in, which is how the companion outline is drawn
## inside the fill rather than on top of its edge.
func _build_polygon(inset: float = 0.0) -> PackedVector2Array:
	var mid_radius := (inner_radius + outer_radius) * 0.5
	# A linear inset has to become an angular one at the arc's radius, or the
	# ends of the wedge would pull in by a different amount from its sides.
	var angle_inset := inset / maxf(1.0, mid_radius)
	var a0 := start_angle + DRAW_ANGLE_PAD + angle_inset
	var a1 := end_angle - DRAW_ANGLE_PAD - angle_inset
	var r0 := inner_radius + DRAW_RADIUS_PAD + inset
	var r1 := maxf(r0 + 1.0, outer_radius - DRAW_RADIUS_PAD - inset)
	var steps := maxi(2, int(ceil((a1 - a0) / ARC_STEP)))
	var points := PackedVector2Array()
	for i in steps + 1:
		var angle := lerpf(a0, a1, float(i) / float(steps))
		points.append(centre + Vector2(cos(angle), sin(angle)) * r1)
	for i in range(steps, -1, -1):
		var angle := lerpf(a0, a1, float(i) / float(steps))
		points.append(centre + Vector2(cos(angle), sin(angle)) * r0)
	return points


func set_companion(is_companion: bool) -> void:
	if is_companion == _is_companion:
		return
	_is_companion = is_companion
	queue_redraw()


func _draw() -> void:
	if outer_radius <= 0.0:
		return
	var points := _build_polygon()
	var fill := _fill_color()
	draw_colored_polygon(points, fill)
	if _hovered:
		draw_colored_polygon(points, Palette.HOVER_TINT)
	if _is_companion:
		# Drawn inside the fill, so a wedge that is both a function and the
		# related key shows the function's colour with this ring inside it.
		var outline := _build_polygon(COMPANION_GAP + COMPANION_WIDTH * 0.5)
		outline.append(outline[0])
		draw_polyline(outline, Palette.RELATIVE, COMPANION_WIDTH, true)

	var font := get_theme_default_font()
	if font == null:
		return
	var mid_angle := (start_angle + end_angle) * 0.5
	var mid_radius := (inner_radius + outer_radius) * 0.5
	var anchor := centre + Vector2(cos(mid_angle), sin(mid_angle)) * mid_radius
	var band := outer_radius - inner_radius
	var text_color := Palette.contrast_text(fill if not _hovered else fill.lightened(0.1))

	# One name per wedge now, so the label always gets its band to itself.
	# The 0.62 factor only bites on a split half-band; a full band hits the cap,
	# which keeps split and unsplit wedges reading at the same weight.
	var font_size := clampi(int(band * 0.62), 9, 30)
	_draw_centred(font, label, font_size, anchor, text_color)



## Draw `text` centred both horizontally and vertically on `anchor`.
func _draw_centred(font: Font, text: String, font_size: int, anchor: Vector2, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# draw_string takes a baseline, so centre on the ascent/descent midpoint
	# rather than on the full line height.
	var baseline := anchor.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(anchor.x - text_size.x * 0.5, baseline), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
