class_name CircleOfFifths
extends Control

## The circle of fifths: an outer ring of the 12 major keys, an inner ring of
## their relative minors, and the key signature for each position around the
## outside. Clicking any wedge selects that key.
##
## The wedges are CircleSegment children; this node owns the geometry and the
## selection states, and paints the things that are not wedges (the signature
## labels and the centre readout).

## Radii as fractions of the circle's half-size, from the outside in.
const R_SIGNATURE := 0.94
const R_MAJOR_OUTER := 0.86
const R_MAJOR_INNER := 0.62
const R_MINOR_OUTER := 0.60
const R_MINOR_INNER := 0.36

const SECTOR := TAU / 12.0

## Circle size as a fraction of the square it is given. Under 1.0 so the chord
## panel can take the width back, and so there is slack to shift into.
@export var radius_scale: float = 0.99
## Nudge right, as a fraction of the control's width. Opens up the gap between
## the circle and the panel on its left.
@export var centre_offset_x: float = 0.02

var _segments: Array[CircleSegment] = []
var _radius: float = 0.0
var _centre: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_segments()
	_update_geometry()
	# Read the current selection rather than waiting for a signal, so this node
	# is correct no matter what order the scene tree happens to be readied in.
	_refresh_states()
	AppState.key_changed.connect(_on_key_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_geometry()


func _build_segments() -> void:
	# Minors are added first so the majors sit later in the child order. The
	# rings never overlap in polar space, so this is purely for draw ordering
	# of the labels; it keeps the outer ring's text on top if radii are tweaked.
	for mode in [KeyDef.Mode.MINOR, KeyDef.Mode.MAJOR]:
		for slot in 12:
			if MusicTheory.has_alt_spelling(slot):
				_add_spelling_pair(slot, mode)
			else:
				_add_segment(slot, mode, false, 0.0, 1.0)


## Two names means two keys, so it means two buttons: the ring band splits in
## half. Which spelling gets which half is decided by its key signature, not by
## which one the position calls primary - the sharp spelling always takes the
## inner half and the flat one the outer, so reading inward always means
## reading sharper. Every dual position has exactly one of each, so both halves
## are always filled exactly once.
func _add_spelling_pair(slot: int, mode: int) -> void:
	var primary_is_sharp := MusicTheory.signature_of(MusicTheory.key_at(slot, mode, false)) > 0
	var sharp_uses_alt := not primary_is_sharp
	_add_segment(slot, mode, sharp_uses_alt, 0.0, 0.5)
	_add_segment(slot, mode, not sharp_uses_alt, 0.5, 1.0)


func _add_segment(slot: int, mode: int, use_alt: bool, band_from: float, band_to: float) -> void:
	var segment := CircleSegment.new()
	segment.circle_position = slot
	segment.mode = mode
	segment.use_alt = use_alt
	segment.label = MusicTheory.wedge_label(slot, mode, use_alt)
	segment.band_from = band_from
	segment.band_to = band_to
	segment.selected.connect(_on_segment_selected)
	add_child(segment)
	_segments.append(segment)


## Recompute the polar layout and push it to every wedge. Each segment's own
## rect spans the whole control, so its local coordinates match ours and the
## polar maths needs no extra transform.
func _update_geometry() -> void:
	_radius = minf(size.x, size.y) * 0.5 * radius_scale
	_centre = size * 0.5 + Vector2(size.x * centre_offset_x, 0.0)
	for segment in _segments:
		var is_major: bool = segment.mode == KeyDef.Mode.MAJOR
		var ring_inner := _radius * (R_MAJOR_INNER if is_major else R_MINOR_INNER)
		var ring_outer := _radius * (R_MAJOR_OUTER if is_major else R_MINOR_OUTER)
		# A split wedge takes only part of its ring's radial band.
		var inner := lerpf(ring_inner, ring_outer, segment.band_from)
		var outer := lerpf(ring_inner, ring_outer, segment.band_to)
		# Position 0 (C) sits at the top. Screen angles grow clockwise because
		# Y points down, which is exactly the direction the circle reads in.
		var start := -PI * 0.5 - SECTOR * 0.5 + SECTOR * segment.circle_position
		segment.position = Vector2.ZERO
		segment.size = size
		segment.configure(_centre, inner, outer, start, start + SECTOR)
	queue_redraw()


func _on_segment_selected(slot: int, mode: int, use_alt: bool) -> void:
	AppState.select_key(slot, mode, use_alt)


func _on_key_changed(_key: KeyDef) -> void:
	_refresh_states()


## Colour every wedge by how it relates to the current selection.
##
## These are the three chords a beginner reaches for first, and the circle hands
## them over for free: one step CLOCKWISE is the dominant (V), because clockwise
## motion *is* a rise of a fifth - that is what the circle of fifths is. One step
## anticlockwise is the subdominant (IV). Same clock position on the other ring
## is the relative key. So the tonic and its two strongest neighbours are always
## the three wedges touching each other, wherever the selection happens to be.
func _refresh_states() -> void:
	var key := AppState.selected_key
	# The two rings exist to show major against its relative minor. In any other
	# mode that pairing is not what is on screen, and the second ring would just
	# be twelve keys with no bearing on the one selected - so it is hidden.
	var single_ring := not (key.is_major() or key.is_minor())
	for segment in _segments:
		var state := _state_for(segment, key)
		var companion := _is_companion(segment, key)
		# An off-ring wedge stays hidden unless it is carrying something. A
		# mode's parent always lives on the major ring, whichever ring the key
		# was reached from, and hiding it would mark a wedge nobody can see.
		segment.visible = not single_ring \
				or segment.mode == key.circle_ring \
				or state != CircleSegment.State.NORMAL \
				or companion
		segment.set_segment_state(state)
		segment.set_companion(companion)
	queue_redraw()


func _state_for(segment: CircleSegment, key: KeyDef) -> int:
	# The wedge a key is drawn on is remembered, not derived from its mode, so
	# switching mode leaves the circle exactly where it was.
	var ring: int = key.circle_ring
	if segment.circle_position == key.circle_position:
		# The other spelling of the selected position is a different key, so it
		# lights up no more than any other wedge.
		if segment.use_alt != key.use_alt_spelling:
			return CircleSegment.State.NORMAL
		if segment.mode == ring:
			return CircleSegment.State.TONIC
	# V and IV are marked only on the selection's own ring, so a major key's
	# dominant reads as the major chord it actually is.
	if segment.mode == ring:
		var steps := wrapi(segment.circle_position - key.circle_position, 0, 12)
		if (steps == 1 or steps == 11) and _matches_spelling(segment, key):
			# A wedge a fifth away only means that function while the mode still
			# spells the perfect interval. Lydian has no perfect fourth and Locrian
			# no perfect fifth, so there the mark would send the reader to a key
			# built on a note the scale does not contain.
			var degree := 4 if steps == 1 else 3
			if MusicTheory.has_function_degree(key.mode, degree):
				if steps == 1:
					return CircleSegment.State.DOMINANT
				return CircleSegment.State.SUBDOMINANT
	return CircleSegment.State.NORMAL


## The key worth naming alongside this one, which the blue wedge marks.
##
## A plain major or minor key - one whose mode IS the ring it sits on - points
## at its relative on the other ring of the same wedge, which is the pairing the
## two rings exist to show. Every other mode points at the major key whose
## signature it borrows, so the wedge agrees with the "same notes as" line in
## the panel.
func _is_companion(segment: CircleSegment, key: KeyDef) -> bool:
	if key.mode == key.circle_ring:
		var other := KeyDef.Mode.MAJOR if key.circle_ring == KeyDef.Mode.MINOR \
				else KeyDef.Mode.MINOR
		return segment.circle_position == key.circle_position \
				and segment.mode == other \
				and segment.use_alt == key.use_alt_spelling
	var parent := MusicTheory.parent_major(key)
	# Matched against the PARENT's spelling rather than the key's. C-flat Dorian
	# is an alternative spelling, but its parent sits at a position with no
	# second spelling at all, so comparing the key's flag would never match.
	return segment.circle_position == parent.circle_position \
			and segment.mode == KeyDef.Mode.MAJOR \
			and segment.use_alt == parent.use_alt_spelling


## Where a neighbouring position offers two spellings, pick the one that leans
## the same way as the selected key. D-flat major's IV is G-flat, not F-sharp,
## even though both wedges sit at the same clock position - so the flat-side
## half lights up for a flat key and the sharp-side half for a sharp one.
func _matches_spelling(segment: CircleSegment, key: KeyDef) -> bool:
	if not MusicTheory.has_alt_spelling(segment.circle_position):
		return true
	var neighbour := MusicTheory.key_at(segment.circle_position, segment.mode, segment.use_alt)
	return (MusicTheory.signature_of(neighbour) < 0) == (MusicTheory.signature_of(key) < 0)


func _draw() -> void:
	if _radius <= 0.0:
		return
	var font := get_theme_default_font()
	if font == null:
		return
	_draw_signature_ring(font)
	_draw_centre_readout(font)


## The sharp/flat count for each position, just outside the major ring.
func _draw_signature_ring(font: Font) -> void:
	var key := AppState.selected_key
	var font_size := clampi(int(_radius * 0.055), 8, 20)
	for slot in 12:
		var angle := -PI * 0.5 + SECTOR * slot
		var anchor := _centre + Vector2(cos(angle), sin(angle)) * (_radius * R_SIGNATURE)
		var is_current := slot == key.circle_position
		var color := Palette.ACCENT if is_current else Palette.TEXT_FAINT
		_draw_centred(font, MusicTheory.signature_short(slot), font_size, anchor, color)


## The hole in the middle names the selected key and spells out its scale -
## the single most useful thing to have in view while reading the chord list.
func _draw_centre_readout(font: Font) -> void:
	var key := AppState.selected_key
	var hole := _radius * R_MINOR_INNER
	var title_size := clampi(int(hole * 0.26), 12, 34)
	var body_size := clampi(int(hole * 0.15), 9, 19)

	_draw_centred(font, key.display_name(), title_size, _centre - Vector2(0, hole * 0.30), Palette.TEXT)
	_draw_centred(font, MusicTheory.signature_text(key), body_size,
			_centre + Vector2(0, hole * 0.02), Palette.TEXT_DIM)

	# The scale is too wide to fit the hole on one line, so split it in two.
	var notes := MusicTheory.scale_notes(key)
	var first := PackedStringArray()
	var second := PackedStringArray()
	for i in notes.size():
		if i < 4:
			first.append(notes[i].display_name())
		else:
			second.append(notes[i].display_name())
	_draw_centred(font, "  ".join(first), body_size, _centre + Vector2(0, hole * 0.36), Palette.RELATIVE)
	_draw_centred(font, "  ".join(second), body_size, _centre + Vector2(0, hole * 0.62), Palette.RELATIVE)


func _draw_centred(font: Font, text: String, font_size: int, anchor: Vector2, color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := anchor.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(anchor.x - text_size.x * 0.5, baseline), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
