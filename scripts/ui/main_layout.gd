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
## Portrait is 9:16, and its width is dictated by the chord table rather than
## chosen: one ChordRow measures 1062px across and the panel 1110, so anything
## narrower would clip the rows rather than shrink them. That makes the whole
## interface small on a phone, which is the cost of keeping the row as it is;
## the row has to get narrower before this number can.
const LANDSCAPE_BASE := Vector2i(1920, 1080)
const PORTRAIT_BASE := Vector2i(1180, 2100)

## How tall the circle is allowed to be when stacked. Left to expand it would
## take its full width squared - over 1100px - and push the table off screen.
const PORTRAIT_CIRCLE_HEIGHT := 700.0

## The rule between the two halves, thin enough to divide without dividing
## attention.
const DIVIDER_THICKNESS := 1.0

## The table gets a little more room than the circle, in either direction.
const PANEL_RATIO := 1.2

@onready var _layout: BoxContainer = %Layout
@onready var _divider: ColorRect = %Divider
@onready var _panel: Control = %ChordPanel
@onready var _right: Control = %RightPane
@onready var _circle_pane: Control = %CirclePane

var _is_portrait := false


func _ready() -> void:
	_divider.color = Palette.PANEL_EDGE
	get_window().size_changed.connect(_on_window_resized)
	# Apply once up front rather than waiting for a resize, so the very first
	# frame is already in the right orientation.
	_apply(_window_is_portrait())


func _on_window_resized() -> void:
	var portrait := _window_is_portrait()
	if portrait != _is_portrait:
		_apply(portrait)


## Read the real window, never the viewport. content_scale_size changes the
## viewport's logical size, so testing that would feed back on itself: going
## portrait would reshape the viewport, which would look landscape again.
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

	# Expand along the axis the box now runs in, and merely fill across it.
	var along := Control.SIZE_EXPAND_FILL
	var across := Control.SIZE_FILL
	_panel.size_flags_horizontal = across if portrait else along
	_panel.size_flags_vertical = along if portrait else across
	_right.size_flags_horizontal = across if portrait else along
	_right.size_flags_vertical = along if portrait else across
	_panel.size_flags_stretch_ratio = PANEL_RATIO

	# The rule is one pixel on the axis it divides and stretches on the other.
	_divider.custom_minimum_size = Vector2(0.0, DIVIDER_THICKNESS) if portrait \
			else Vector2(DIVIDER_THICKNESS, 0.0)
	_divider.size_flags_horizontal = along if portrait else across
	_divider.size_flags_vertical = across if portrait else along

	# Stacked, the circle is capped and centres itself inside the full width;
	# side by side it takes whatever height is going.
	if portrait:
		_circle_pane.custom_minimum_size = Vector2(0.0, PORTRAIT_CIRCLE_HEIGHT)
	else:
		_circle_pane.custom_minimum_size = Vector2.ZERO
	_circle_pane.size_flags_vertical = across if portrait else along
