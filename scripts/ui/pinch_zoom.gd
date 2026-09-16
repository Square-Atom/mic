class_name PinchZoom
extends Node

## Two-finger pinch to zoom the whole interface, two-finger drag to pan it, and
## a two-finger double tap to put it back.
##
## Built into the app rather than left to the browser. Godot's web page turns
## browser zoom off and its canvas swallows touch, so a pinch never reaches the
## browser - and if it did, the browser would only be magnifying pixels already
## drawn, so text would blur. Zooming here redraws at the new size and stays
## sharp.
##
## The zoom is the viewport's canvas transform, not a scale on any node. The
## layout never learns it happened, so no container re-sorts and MainLayout's
## sizing is left alone, while the GUI already maps taps through the canvas
## transform - every button stays exactly where it is drawn.
##
## One finger is never touched. Everything the app does with a single touch -
## keys, wedges, buttons, dragging chords - behaves as it always has.

const MIN_ZOOM := 1.0
const MAX_ZOOM := 3.0

## A two-finger touch counts as a tap when both fingers are down for less than
## this, and move less than TAP_SLOP between them.
const TAP_MAX_MS := 250
const TAP_SLOP := 24.0
## Two such taps within this long of each other reset the zoom.
const DOUBLE_TAP_MS := 400

## True from the moment a second finger lands until the next touch sequence
## begins. Static, because the controls that need it - a button deciding
## whether its release was a click - have no reason to hold a reference to
## this node.
##
## It stays set after the fingers lift on purpose. The emulated mouse release
## that Godot generates from a touch can arrive either side of the touch event
## itself, so clearing the flag on release would sometimes let a pinch's last
## lift count as a click. It is only cleared when a fresh first finger lands.
static var _sequence_was_gesture := false

## Screen positions of the fingers currently down, by touch index.
var _touches := {}
var _zoom := 1.0
var _offset := Vector2.ZERO

var _last_distance := 0.0
var _last_midpoint := Vector2.ZERO

var _tap_started_ms := 0
var _tap_travel := 0.0
var _last_tap_ms := -DOUBLE_TAP_MS


## Whether the touch sequence now under way - or the one that just ended -
## turned into a pinch. Controls that act on release check this so that
## lifting the fingers after a zoom is not also a press.
static func touch_became_gesture() -> bool:
	return _sequence_was_gesture


func _ready() -> void:
	# The viewport's size changes when the window resizes or MainLayout flips
	# orientation. The clamp is measured against that size, so the old zoom no
	# longer means anything; starting again at 1x is the only safe answer.
	get_viewport().size_changed.connect(reset)


## Back to 1x with nothing panned.
func reset() -> void:
	_zoom = MIN_ZOOM
	_offset = Vector2.ZERO
	_apply()


# _input rather than _gui_input or _unhandled_input: the gesture has to be seen
# before any control does, so it can take the events a pinch should not hand on.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseMotion and _is_swallowing_emulated_mouse(event):
		# Godot turns the first finger into a mouse. Mid-pinch that finger is
		# moving, and as a mouse it would drag a loop chord or slide off a button;
		# none of that should happen while the view is being moved.
		get_viewport().set_input_as_handled()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touches.is_empty():
			_sequence_was_gesture = false
		_touches[event.index] = event.position
		if _touches.size() == 2:
			_begin_pinch()
		if _touches.size() >= 2:
			get_viewport().set_input_as_handled()
		return

	if not _touches.has(event.index):
		return
	_touches.erase(event.index)
	if _touches.is_empty() and _sequence_was_gesture:
		_finish_tap()


func _on_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	var before: Vector2 = _touches[event.index]
	_touches[event.index] = event.position
	if not _sequence_was_gesture:
		return
	_tap_travel += before.distance_to(event.position)
	get_viewport().set_input_as_handled()
	# Once one of the two fingers has lifted, the other simply rests: panning on
	# one finger would fight with everything one finger already does.
	if _touches.size() >= 2:
		_update_pinch()


func _begin_pinch() -> void:
	_sequence_was_gesture = true
	# A chord drag begun by the first finger has to be abandoned, not dropped.
	# The loop strip deletes a chord whose drag ends outside it, so it checks
	# touch_became_gesture() before treating this cancel as a drag-out.
	get_viewport().gui_cancel_drag()
	var pair := _pair()
	_last_distance = pair[0].distance_to(pair[1])
	_last_midpoint = (pair[0] + pair[1]) * 0.5
	_tap_started_ms = Time.get_ticks_msec()
	_tap_travel = 0.0


func _update_pinch() -> void:
	var pair := _pair()
	var distance := pair[0].distance_to(pair[1])
	var midpoint := (pair[0] + pair[1]) * 0.5
	if _last_distance > 0.0 and distance > 0.0:
		# The content point that was under the fingers stays under them, so the
		# zoom grows out from the pinch rather than from the corner, and moving
		# the fingers together pans in the same step.
		var anchor := (_last_midpoint - _offset) / _zoom
		_zoom = clampf(_zoom * distance / _last_distance, MIN_ZOOM, MAX_ZOOM)
		_offset = midpoint - anchor * _zoom
		_apply()
	_last_distance = distance
	_last_midpoint = midpoint


func _finish_tap() -> void:
	var now := Time.get_ticks_msec()
	if now - _tap_started_ms > TAP_MAX_MS or _tap_travel > TAP_SLOP:
		return
	if now - _last_tap_ms <= DOUBLE_TAP_MS:
		reset()
		# Spent, so a third quick tap starts a new pair rather than resetting
		# again.
		_last_tap_ms = -DOUBLE_TAP_MS
	else:
		_last_tap_ms = now


## Write the zoom out, first keeping the view inside the content. Zoomed in,
## the content is larger than the screen, so its left and top edges may only
## move left and up, and never so far that its far edges come inside the
## screen - no background showing past the interface in any direction.
func _apply() -> void:
	var screen := get_viewport().get_visible_rect().size
	_offset = _offset.clamp(screen - screen * _zoom, Vector2.ZERO)
	get_viewport().canvas_transform = Transform2D(
			Vector2(_zoom, 0.0), Vector2(0.0, _zoom), _offset)


## The two fingers the gesture follows: the two lowest touch indices, so a
## third finger resting on the glass cannot take the pinch over.
func _pair() -> Array[Vector2]:
	var indices := _touches.keys()
	indices.sort()
	var pair: Array[Vector2] = [_touches[indices[0]], _touches[indices[1]]]
	return pair


func _is_swallowing_emulated_mouse(event: InputEvent) -> bool:
	return (_sequence_was_gesture and not _touches.is_empty()
			and event.device == InputEvent.DEVICE_ID_EMULATION)
