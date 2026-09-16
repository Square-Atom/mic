class_name InfoOverlay
extends Control

## What the app is and who made it, behind the i beside the circle.
##
## This text used to run along the bottom of the chord table, where it cost
## every screen a strip of height to say something worth reading once. Behind a
## button it costs nothing until it is asked for, and the table keeps the room.
##
## Built as a Control laid over the whole screen rather than a Window. The app
## rewrites content_scale_size whenever the orientation changes and an embedded
## subwindow is measured against that, so a dialog opened in one orientation
## would be sized for the other. An overlay is another Control in the same tree
## and scales with everything around it.
##
## The links are real ones. A web address you cannot click is decoration, and
## the email is the whole point of inviting feedback - so both open through the
## OS, which on the web export means a new tab or the mail client.

const TITLE := "Music Interactive Cheatsheet (M.I.C.)"
const SITE_URL := "https://www.pixelmancer.studio"
const SITE_LABEL := "www.pixelmancer.studio"
const CONTACT := "contact@pixelmancer.studio"
const ADVISOR := "Dang Le"
## No link, because none was given for it. The name stands on its own rather
## than being pointed at a guessed address.
const ADVISOR_STUDIO := "23:59 Studio"

const TITLE_FONT_SIZE := 22
const BODY_FONT_SIZE := 15
## The text column's width, which is what sets the panel's: sizing the panel
## instead would leave the wrapping label to work out its height from a width it
## has not been given yet.
const TEXT_WIDTH := 460.0
const PANEL_PADDING := 24
const CLOSE_SIZE := Vector2(32.0, 32.0)

## How far the app behind is dimmed. Enough that the panel is plainly in front,
## not so far that the circle and the table stop being visible - the point of
## the panel is to be read and dismissed, not to replace the screen.
const SCRIM_ALPHA := 0.72


func _ready() -> void:
	# The overlay swallows every click that is not on the panel, which is what
	# stops the app behind being operated through it.
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_set_open(false)


## Clicking the dimmed area closes. The panel sets its own filter to STOP so
## that clicks inside it never arrive here and it cannot dismiss itself.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_set_open(true)


func close() -> void:
	_set_open(false)


func _set_open(is_open: bool) -> void:
	visible = is_open
	# Escape is only ours while the panel is up; leaving the handler live would
	# have a hidden overlay quietly eating the key from anything else that wants
	# it later.
	set_process_unhandled_key_input(is_open)


func _build() -> void:
	var scrim := ColorRect.new()
	scrim.color = Color(Palette.BG, SCRIM_ALPHA)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	centre.add_child(_build_panel())


func _build_panel() -> Control:
	var panel := PanelContainer.new()
	# Containers pass the mouse through by default, which here would mean every
	# click on the panel also reaching the scrim behind it and closing what the
	# reader just opened.
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PANEL
	style.border_color = Palette.PANEL_EDGE.lightened(0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", PANEL_PADDING)
	margin.add_theme_constant_override("margin_top", PANEL_PADDING)
	margin.add_theme_constant_override("margin_right", PANEL_PADDING)
	margin.add_theme_constant_override("margin_bottom", PANEL_PADDING)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	column.add_child(_build_heading())
	column.add_child(HSeparator.new())
	column.add_child(_build_details())
	return panel


## The app's name, with the close button pinned to the far end of the same line.
func _build_heading() -> Control:
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Palette.TEXT)
	heading.add_child(title)

	var close_button := IconButton.new()
	close_button.glyph = IconButton.Glyph.CLOSE
	close_button.custom_minimum_size = CLOSE_SIZE
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.tooltip_text = "Close"
	close_button.pressed.connect(close)
	heading.add_child(close_button)
	return heading


func _build_details() -> Control:
	var details := RichTextLabel.new()
	details.bbcode_enabled = true
	# Without fit_content a RichTextLabel claims a default height, which in a
	# panel sized to its contents means a block of dead space under the text.
	details.fit_content = true
	details.scroll_active = false
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.meta_underlined = true
	details.custom_minimum_size = Vector2(TEXT_WIDTH, 0.0)
	details.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)
	details.add_theme_color_override("default_color", Palette.TEXT_DIM)
	details.meta_clicked.connect(_on_meta_clicked)

	# The link colour is taken from the palette rather than written as a literal,
	# so it cannot drift from the rest of the interface.
	var link := Palette.RELATIVE.to_html(false)
	# One entry per line of the panel. The credit and the advising line belong
	# together, so only the feedback line is set apart by a blank one.
	details.text = "%s\n%s\n\n%s" % [
		"Created by Hau Tran at " + _link(SITE_URL, SITE_LABEL, link),
		"With advising from " + ADVISOR + " at " + ADVISOR_STUDIO,
		"Any feedback, please send to " + _link("mailto:" + CONTACT, CONTACT, link),
	]
	return details


static func _link(target: String, label: String, color: String) -> String:
	return "[url=%s][color=#%s]%s[/color][/url]" % [target, color, label]


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
