class_name Credits
extends RichTextLabel

## The credit line under the chord table.
##
## The links are real ones. A web address you cannot click is decoration, and
## the email is the whole point of inviting feedback - so both open through the
## OS, which on the web export means a new tab or the mail client.

const FONT_SIZE := 13
const SITE_URL := "https://www.pixelmancer.studio"
const SITE_LABEL := "www.pixelmancer.studio"
const CONTACT := "contact@pixelmancer.studio"


func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_underlined = true
	add_theme_font_size_override("normal_font_size", FONT_SIZE)
	add_theme_color_override("default_color", Palette.TEXT_FAINT)
	meta_clicked.connect(_on_meta_clicked)

	# The link colour is taken from the palette rather than written as a literal,
	# so it cannot drift from the rest of the interface.
	var link := Palette.RELATIVE.to_html(false)
	text = "[center]Created by Hau Tran at %s\nAny feedback, please send to %s[/center]" % [
		_link(SITE_URL, SITE_LABEL, link),
		_link("mailto:" + CONTACT, CONTACT, link),
	]


static func _link(target: String, label: String, color: String) -> String:
	return "[url=%s][color=#%s]%s[/color][/url]" % [target, color, label]


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
