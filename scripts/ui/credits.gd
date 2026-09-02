class_name Credits
extends HBoxContainer

## The footer under the chord table: the app's name on the left, the author's
## details on the right, divided by a rule.
##
## Both halves expand equally, so the rule sits midway while the name stays
## pinned to the table's left edge and the details to its right edge.
##
## The links are real ones. A web address you cannot click is decoration, and
## the email is the whole point of inviting feedback - so both open through the
## OS, which on the web export means a new tab or the mail client.

const TITLE := "Music Interactive Cheatsheet (M.I.C.)"
const TITLE_FONT_SIZE := 18
const FONT_SIZE := 13
const SITE_URL := "https://www.pixelmancer.studio"
const SITE_LABEL := "www.pixelmancer.studio"
const CONTACT := "contact@pixelmancer.studio"


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	_add_title()
	_add_rule()
	_add_details()


func _add_title() -> void:
	var title := Label.new()
	title.text = TITLE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The details run to two lines, so centre the single-line name against them
	# rather than letting it sit on the first line.
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Palette.TEXT_DIM)
	add_child(title)


func _add_rule() -> void:
	var rule := VSeparator.new()
	# The theme only styles HSeparator, so a bare VSeparator would fall back to
	# Godot's default grey. Match the panel edge the horizontal rules already use.
	var line := StyleBoxLine.new()
	line.color = Palette.PANEL_EDGE
	line.thickness = 1
	line.vertical = true
	rule.add_theme_stylebox_override("separator", line)
	add_child(rule)


func _add_details() -> void:
	var details := RichTextLabel.new()
	details.bbcode_enabled = true
	# Without fit_content a RichTextLabel claims a default height and the footer
	# either clips its second line or leaves dead space below it.
	details.fit_content = true
	details.scroll_active = false
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.meta_underlined = true
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	details.add_theme_color_override("default_color", Palette.TEXT_FAINT)
	details.meta_clicked.connect(_on_meta_clicked)

	# The link colour is taken from the palette rather than written as a literal,
	# so it cannot drift from the rest of the interface.
	var link := Palette.RELATIVE.to_html(false)
	details.text = "[right]Created by Hau Tran at %s\nAny feedback, please send to %s[/right]" % [
		_link(SITE_URL, SITE_LABEL, link),
		_link("mailto:" + CONTACT, CONTACT, link),
	]
	add_child(details)


static func _link(target: String, label: String, color: String) -> String:
	return "[url=%s][color=#%s]%s[/color][/url]" % [target, color, label]


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
