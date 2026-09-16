class_name ChordLoopBar
extends PanelContainer

## The strip along the bottom of the chord panel: the progression you have
## built, the settings that shape how it is played, and the transport.
##
## It owns no state of its own. Every control writes into ChordLoop and every
## display is rebuilt from a ChordLoop signal, so the strip and the loop cannot
## drift apart - and the loop keeps running correctly whether or not this node
## exists.

## The same weight-700 face the numerals use. The empty strip has one job -
## telling you where chords come from - and at the theme's regular weight it
## read as a caption on the frame rather than an instruction.
const BOLD_FONT := preload("res://themes/font_bold.tres")

const HINT_FONT_SIZE := 18
const TITLE_WIDTH := 92.0
const TRANSPORT_SIZE := Vector2(88.0, 88.0)
## Two thirds of the transport. Emptying the loop is the counterpart to playing
## it, so it is sized against that rather than against the slots' own delete
## buttons - but smaller, because it is not what you came to the strip to do.
const CLEAR_SIZE := Vector2(58.0, 58.0)
## How far the clear button fades when there is nothing to clear. Short of a
## disabled state, which DrawnButton has no notion of, and short of hiding it,
## which would shift the whole strip the moment the first chord landed.
const CLEAR_IDLE_ALPHA := 0.35
## Tall enough for a slot's box and its delete button, so an empty strip is the
## same height as a full one and the panel does not jump when the first chord
## lands in it.
const TIMELINE_MIN_HEIGHT := 84.0

var _timeline: LoopTimeline
var _hint: Label
var _ostinato_picker: OptionButton
var _transport: IconButton
var _clear: IconButton
var _slots: Array[LoopSlot] = []
## The slot a drag left from, remembered because a drag that lands nowhere is a
## delete and by then there is nothing under the cursor to ask.
var _drag_from := -1


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL.darkened(0.15)
	style.border_color = Palette.PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", style)
	_build()

	ChordLoop.slots_changed.connect(_on_slots_changed)
	ChordLoop.playing_changed.connect(_on_playing_changed)
	ChordLoop.step_advanced.connect(_on_step_advanced)
	ChordLoop.ostinato_changed.connect(_on_ostinato_changed)
	# The numerals are spelled in the current key, so they change when it does -
	# iii in C major is III in C minor, and a seventh adds a 7 to the numeral.
	AppState.key_changed.connect(_on_key_changed)
	AppState.sevenths_changed.connect(_on_sevenths_changed)
	_rebuild()


## Catches a drag that ended without a drop. The engine sends this to every
## control, so the test is whether THIS strip started the drag, not whether it
## happens to be under the cursor now.
func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END or _drag_from < 0:
		return
	var from := _drag_from
	_drag_from = -1
	# LoopTimeline is the only drop target in the app, so an unsuccessful drag
	# means the chord was pulled out of the strip - which is how you delete one.
	#
	# Deferred because this notification is being propagated down the tree right
	# now, and removing the slot rebuilds the strip: pulling nodes out from under
	# a walk that is still in progress is how you get the one node it skipped.
	if not get_viewport().gui_is_drag_successful():
		ChordLoop.remove_slot.call_deferred(from)


# --- Construction ----------------------------------------------------------

## Build the chrome. Done in code rather than a scene because most of these
## nodes are drawn controls with no editor representation anyway, and keeping
## the layout beside the logic that drives it is easier to follow than a scene
## file that only makes sense with this script open next to it.
func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	row.add_child(_build_clear())
	row.add_child(_build_timeline())
	row.add_child(_build_settings())
	row.add_child(_build_transport())


## Empties the strip. The same can the slots carry, at the size of the job:
## this one does what every slot's delete button does, all at once.
func _build_clear() -> Control:
	_clear = IconButton.new()
	_clear.glyph = IconButton.Glyph.TRASH
	_clear.custom_minimum_size = CLEAR_SIZE
	_clear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clear.tooltip_text = "Remove every chord from the loop"
	_clear.pressed.connect(ChordLoop.clear)
	return _clear


## The sunken frame the slots sit in. Its own panel, a shade darker than the
## strip, so the area you can drop a chord into is visibly bounded.
func _build_timeline() -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Palette.BG
	frame_style.border_color = Palette.PANEL_EDGE
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", frame_style)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 12)
	inner.add_theme_constant_override("margin_top", 6)
	inner.add_theme_constant_override("margin_right", 12)
	inner.add_theme_constant_override("margin_bottom", 6)
	frame.add_child(inner)

	_timeline = LoopTimeline.new()
	_timeline.custom_minimum_size = Vector2(0.0, TIMELINE_MIN_HEIGHT)
	inner.add_child(_timeline)

	# The hint lives inside the timeline so that an empty strip still has
	# something to drop onto - a collapsed container would have no area at all.
	_hint = Label.new()
	_hint.text = "Press + beside a chord to build a loop"
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", BOLD_FONT)
	_hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	_hint.add_theme_color_override("font_color", Palette.TEXT_FAINT)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timeline.add_child(_hint)
	return frame


func _build_settings() -> Control:
	var settings := VBoxContainer.new()
	settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	settings.add_theme_constant_override("separation", 8)

	var tempo_row := HBoxContainer.new()
	tempo_row.add_theme_constant_override("separation", 10)
	tempo_row.add_child(_title("Tempo"))
	tempo_row.add_child(TempoSpinner.new())
	settings.add_child(tempo_row)

	var ostinato_row := HBoxContainer.new()
	ostinato_row.add_theme_constant_override("separation", 10)
	ostinato_row.add_child(_title("Ostinato"))
	_ostinato_picker = OptionButton.new()
	_ostinato_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ostinato_picker.tooltip_text = "How each chord is broken up across its bar"
	for i in Ostinato.count():
		_ostinato_picker.add_item(Ostinato.name_at(i), i)
	_ostinato_picker.select(ChordLoop.ostinato)
	_ostinato_picker.item_selected.connect(ChordLoop.set_ostinato)
	ostinato_row.add_child(_ostinato_picker)
	settings.add_child(ostinato_row)
	return settings


func _build_transport() -> Control:
	_transport = IconButton.new()
	_transport.glyph = IconButton.Glyph.PLAY
	# Deliberately untinted rather than coloured: in this app amber, green and
	# pink each name a chord function, and spending one of them on a transport
	# button would make the strip claim something about the music that is not
	# true. Prominence comes from its size instead.
	_transport.glyph_tint = Palette.TEXT
	_transport.custom_minimum_size = TRANSPORT_SIZE
	_transport.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_transport.tooltip_text = "Play the loop"
	_transport.pressed.connect(ChordLoop.toggle)
	return _transport


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(TITLE_WIDTH, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	return label


# --- Keeping up with the loop ----------------------------------------------

func _on_slots_changed(_slots_now: PackedInt32Array) -> void:
	_rebuild()


func _on_key_changed(_key: KeyDef) -> void:
	_rebuild()


func _on_sevenths_changed(_enabled: bool) -> void:
	_rebuild()


func _on_ostinato_changed(index: int) -> void:
	# ChordLoop may clamp what it was handed, so the picker follows the loop
	# rather than assuming its own selection took.
	if _ostinato_picker.selected != index:
		_ostinato_picker.select(index)


func _on_playing_changed(playing: bool) -> void:
	_transport.glyph = IconButton.Glyph.STOP if playing else IconButton.Glyph.PLAY
	_transport.tooltip_text = "Stop the loop" if playing else "Play the loop"
	if not playing:
		_highlight(-1)


func _on_step_advanced(slot: int, _step: int) -> void:
	_highlight(slot)


## Rebuild the row of slots from scratch.
##
## Eight nodes is cheap enough that diffing the list against the one on screen
## would cost more to read than it saves to run - unlike the chord rows, which
## are updated in place because rebuilding those means 84 piano keys.
func _rebuild() -> void:
	for slot in _slots:
		# Detached before freeing, not merely queued: queue_free leaves the node
		# parented until the end of the frame, and the timeline works out where a
		# drop lands by walking its children - so a stale slot still in the list
		# would shift every insertion point after it.
		_timeline.remove_child(slot)
		slot.queue_free()
	_slots.clear()

	var degrees := ChordLoop.slots
	_hint.visible = degrees.is_empty()
	# Nothing to throw away yet, and this is the state the strip is first seen
	# in - a fully lit trash can beside "press + to build a loop" invites a
	# press that would do nothing.
	_clear.modulate.a = CLEAR_IDLE_ALPHA if degrees.is_empty() else 1.0
	var chords := AppState.current_chords()
	for i in degrees.size():
		var chord := chords[degrees[i]]
		var slot := LoopSlot.new()
		slot.set_slot(i, chord.roman_numeral(), Palette.family_color(
				MusicTheory.chord_family(chord)))
		slot.drag_started.connect(_on_drag_started)
		_timeline.add_child(slot)
		_slots.append(slot)
	_highlight(ChordLoop.current_slot())


func _highlight(active: int) -> void:
	for i in _slots.size():
		_slots[i].set_active(i == active)


func _on_drag_started(index: int) -> void:
	_drag_from = index
