class_name MainLayout
extends Control

## Switches the whole interface between landscape and portrait.
##
## Both halves stay in one BoxContainer that simply changes axis. A browser
## window is resized continuously, so rebuilding the tree - or swapping to a
## second scene - on every crossing would be visible to the reader, and the
## legend, mode bar and description would have to exist twice and be kept in
## step by hand.
##
## The container is a plain BoxContainer rather than an HBoxContainer because
## the engine refuses to reorient those: HBoxContainer.set_vertical() fails
## outright with "Can't change orientation of HBoxContainer".

## The design size each orientation is scaled against. Landscape matches the
## project's own viewport setting.
##
## Portrait's width is dictated rather than chosen: one ChordRow measures 1058px
## across and the panel 1106, so anything narrower would clip the rows instead
## of shrinking them. Allow for the 28px margins either side and the base has
## to clear 1162. That leaves the interface small on a phone, which is the cost
## of keeping the row as it is; the row has to get narrower before this can.
const LANDSCAPE_BASE := Vector2i(1920, 1080)
const PORTRAIT_BASE := Vector2i(1180, 2100)

## The smallest the stacked circle may be squeezed to. Its own contents need
## 440px, so below this the wedges would start clipping rather than shrinking.
const PORTRAIT_CIRCLE_MIN := 440.0

## The rule between the two halves, thin enough to divide without dividing
## attention.
const DIVIDER_THICKNESS := 1.0

## The table gets a little more room than the circle, side by side.
const PANEL_RATIO := 1.2

@onready var _margin: MarginContainer = %Margin
@onready var _layout: BoxContainer = %Layout
@onready var _divider: ColorRect = %Divider
@onready var _panel: Control = %ChordPanel
@onready var _right: Control = %RightPane
@onready var _circle_pane: Control = %CirclePane

var _is_portrait := false


func _ready() -> void:
	_divider.color = Palette.PANEL_EDGE
	get_window().size_changed.connect(_on_window_resized)
	# The circle is measured against whatever width the layout ends up with, so
	# refit whenever that changes rather than only when the orientation does.
	_layout.resized.connect(_fit_circle)
	# Apply once up front rather than waiting for a resize, so the very first
	# frame is already in the right orientation.
	_apply(_window_is_portrait())


func _on_window_resized() -> void:
	var portrait := _window_is_portrait()
	if portrait != _is_portrait:
		_apply(portrait)
	else:
		# Same orientation, different width: the circle still has to be refitted.
		_fit_circle()


## Read the real window, never the viewport. content_scale_size reshapes the
## viewport, so testing that would feed back on itself: going portrait would
## resize the viewport, which would then measure as landscape again.
func _window_is_portrait() -> bool:
	var win := get_window().size
	return win.y > win.x


func _apply(portrait: bool) -> void:
	_is_portrait = portrait
	get_window().content_scale_size = PORTRAIT_BASE if portrait else LANDSCAPE_BASE
	_layout.vertical = portrait

	# The circle leads in portrait and follows in landscape, so the halves trade
	# places rather than merely changing axis.
	_layout.move_child(_right if portrait else _panel, 0)
	_layout.move_child(_divider, 1)
	_layout.move_child(_panel if portrait else _right, 2)

	# Along the axis the box runs in, portrait expands nothing. A tall narrow
	# window leaves far more height than the content needs, and anything set to
	# expand would swallow that slack as empty space - which is how a gap opened
	# between the circle and the table. Natural heights keep the two together at
	# the top, with the leftover below them where it reads as margin.
	if portrait:
		_panel.size_flags_horizontal = Control.SIZE_FILL
		_panel.size_flags_vertical = Control.SIZE_FILL
		_right.size_flags_horizontal = Control.SIZE_FILL
		_right.size_flags_vertical = Control.SIZE_FILL
		_divider.custom_minimum_size = Vector2(0.0, DIVIDER_THICKNESS)
		_circle_pane.size_flags_vertical = Control.SIZE_FILL
		_fit_circle()
	else:
		# Side by side they share the width, the table taking the larger share.
		_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_panel.size_flags_vertical = Control.SIZE_FILL
		_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_right.size_flags_vertical = Control.SIZE_FILL
		_divider.custom_minimum_size = Vector2(DIVIDER_THICKNESS, 0.0)
		_circle_pane.custom_minimum_size = Vector2.ZERO
		_circle_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# The rule fills the axis it does not divide, in either orientation.
	_divider.size_flags_horizontal = Control.SIZE_FILL
	_divider.size_flags_vertical = Control.SIZE_FILL
	_panel.size_flags_stretch_ratio = PANEL_RATIO


## Size the stacked circle to the width, unless doing so would push the table
## off the bottom.
##
## A circle wants to be a square as wide as the panel, and on a tall window
## there is room for exactly that. On a short one there is not, and the table is
## the thing worth keeping - so the circle takes whatever height is left once
## everything else has claimed its minimum, and stops at its own.
##
## The room is measured from the viewport, never from the layout's own size. A
## Control is never smaller than its minimum, so a circle that has grown too
## tall inflates the layout to match - and measuring that would report the room
## its own overflow created, leaving it no way back down.
func _fit_circle() -> void:
	if not _is_portrait or _margin == null:
		return
	var avail := get_viewport_rect().size
	avail.x -= _margin.get_theme_constant("margin_left")
	avail.x -= _margin.get_theme_constant("margin_right")
	avail.y -= _margin.get_theme_constant("margin_top")
	avail.y -= _margin.get_theme_constant("margin_bottom")
	var used := DIVIDER_THICKNESS
	used += _layout.get_theme_constant("separation") * 2.0
	used += _panel.get_combined_minimum_size().y
	used += _right.get_theme_constant("separation") * maxi(_right.get_child_count() - 1, 0)
	for child in _right.get_children():
		if child != _circle_pane and child is Control:
			used += (child as Control).get_combined_minimum_size().y
	var room := avail.y - used
	# The width is the ceiling: a circle wider than the panel would be clipped.
	_circle_pane.custom_minimum_size.y = clampf(room, PORTRAIT_CIRCLE_MIN, avail.x)
