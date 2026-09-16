class_name LoopTimeline
extends HBoxContainer

## The row of slots, and the only place a dragged chord can be dropped.
##
## Reordering is worked out from the cursor's x alone: the gap it is nearest is
## where the chord will land, and a caret is drawn there so the drop is not a
## guess. Anywhere else in the app is not a drop target at all, which is what
## makes "drag it out to delete" work without this script having to define
## where "out" is.

## Thickness of the insertion caret, and how far it overshoots the slots top and
## bottom so it reads as a mark between them rather than a border on one.
const CARET_WIDTH := 3.0
const CARET_OVERSHOOT := 4.0
## How far the caret sits into the gap between two slots.
const CARET_INSET := 3.0

## Where a drop would land, or -1 when nothing is being dragged over the strip.
var _caret := -1


func _ready() -> void:
	# Drops are found on the control under the cursor, so the strip has to take
	# the mouse. Its slots are children and still get their own clicks first.
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_constant_override("separation", 10)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not _is_slot_drag(data):
		return false
	var target := insert_index_at(at_position.x)
	if target != _caret:
		_caret = target
		queue_redraw()
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _is_slot_drag(data):
		return
	_clear_caret()
	ChordLoop.move_slot(int((data as Dictionary)["index"]), insert_index_at(at_position.x))


func _notification(what: int) -> void:
	# Fires whether the drop was taken or abandoned, so the caret is cleaned up
	# in both cases without needing to know which happened.
	if what == NOTIFICATION_DRAG_END:
		_clear_caret()


## The gap the cursor is over, counted on the list as it looks right now: 0 is
## before the first slot, and `slot count` is after the last. A slot is left of
## the cursor when its own centre is, which puts the boundary halfway across
## each slot and makes short drags behave.
func insert_index_at(x: float) -> int:
	var slots := _slots()
	for i in slots.size():
		if x < slots[i].position.x + slots[i].size.x * 0.5:
			return i
	return slots.size()


func _draw() -> void:
	if _caret < 0:
		return
	var slots := _slots()
	if slots.is_empty():
		return
	var separation := float(get_theme_constant("separation"))
	# Between two slots the caret goes in the gap; past the last one it hugs the
	# trailing edge, since there is no following slot to measure against.
	var x: float
	if _caret < slots.size():
		x = slots[_caret].position.x - separation * 0.5
	else:
		var last := slots[slots.size() - 1]
		x = last.position.x + last.size.x + separation * 0.5
	x = clampf(x, CARET_INSET, size.x - CARET_INSET)
	draw_line(
		Vector2(x, -CARET_OVERSHOOT),
		Vector2(x, size.y + CARET_OVERSHOOT),
		Palette.ACCENT, CARET_WIDTH, true)


func _clear_caret() -> void:
	if _caret < 0:
		return
	_caret = -1
	queue_redraw()


func _slots() -> Array[LoopSlot]:
	var out: Array[LoopSlot] = []
	for child in get_children():
		if child is LoopSlot:
			out.append(child)
	return out


func _is_slot_drag(data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).get("type", "") == LoopSlot.DRAG_TYPE
