@tool
class_name PianoKey
extends Control

## A single piano key. Draws itself, tracks its own hover, and reports clicks.
##
## Kept as a real Control (rather than something the keyboard paints itself) so
## that hover and input come free from the engine, and so a single key can be
## reused on its own wherever one is needed.

signal pressed(pitch_class: int)

enum State {
	NORMAL,      ## Resting.
	IN_CHORD,    ## One of the notes of the chord being shown.
	IS_ROOT,     ## The note the chord is built on.
	IS_SEVENTH,  ## The added 7th - in the chord, but not part of the triad.
	DIMMED,      ## Explicitly greyed out - not part of the current key.
}

## Smallest legible label. Below this the text is dropped rather than drawn
## as an unreadable smudge - which is what happens on a narrow black key.
const MIN_LABEL_FONT_SIZE := 8
const LABEL_BOTTOM_MARGIN := 6.0

@export var pitch_class: int = 0
@export var is_black: bool = false

## Text drawn near the bottom of the key. Set from outside rather than derived
## from `pitch_class`, because only the caller knows the correct spelling: the
## same key is B-flat in one chord and A-sharp in another.
@export var label_text: String = "":
	set(value):
		label_text = value
		queue_redraw()

## The colour family this key highlights in. Set by the keyboard, which in turn
## takes it from whatever the caller decided the highlight means.
var highlight_base: Color = Palette.ACCENT:
	set(value):
		highlight_base = value
		queue_redraw()

var _state: int = State.NORMAL
var _hovered: bool = false
## One style box reused across redraws - building a new one every frame would
## allocate on every mouse move.
var _style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = StyleBoxFlat.new()
	# Real keys are square at the top and rounded at the bottom.
	_style.corner_radius_top_left = 0
	_style.corner_radius_top_right = 0
	_style.corner_radius_bottom_left = 4
	_style.corner_radius_bottom_right = 4
	_style.set_border_width_all(1)
	_style.border_color = Palette.KEY_EDGE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_key_state(new_state: int) -> void:
	if new_state == _state:
		return
	_state = new_state
	queue_redraw()


func get_key_state() -> int:
	return _state


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
			pressed.emit(pitch_class)
			accept_event()


## The fill for the current state. Chord highlighting overrides the key's own
## colour entirely, so a highlighted black key reads as clearly as a white one.
func _fill_color() -> Color:
	var base: Color
	match _state:
		State.IS_ROOT:
			base = highlight_base
		State.IS_SEVENTH:
			base = Palette.KEY_SEVENTH
		State.IN_CHORD:
			base = Palette.supporting_tone(highlight_base)
		State.DIMMED:
			base = (Palette.KEY_WHITE if not is_black else Palette.KEY_BLACK).darkened(0.35)
		_:
			base = Palette.KEY_BLACK if is_black else Palette.KEY_WHITE
	if _hovered:
		base = base.lightened(0.18) if not is_black or _state != State.NORMAL else base.lightened(0.35)
	return base


func _draw() -> void:
	if _style == null:
		return
	var fill := _fill_color()
	_style.bg_color = fill
	draw_style_box(_style, Rect2(Vector2.ZERO, size))
	_draw_label()


## Draw the note name near the bottom of the key, shrinking it until it fits the
## key's width. A black key is only about 60% as wide as a white one, so a fixed
## size that suits one would overflow the other.
func _draw_label() -> void:
	if label_text.is_empty():
		return
	var font := get_theme_default_font()
	if font == null:
		return
	var available := size.x - 4.0
	var font_size := clampi(int(size.x * 0.52), MIN_LABEL_FONT_SIZE, 20)
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > available and font_size > MIN_LABEL_FONT_SIZE:
		font_size -= 1
		text_size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	if text_size.x > available:
		return

	var baseline := size.y - font.get_descent(font_size) - LABEL_BOTTOM_MARGIN
	draw_string(font, Vector2((size.x - text_size.x) * 0.5, baseline), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.KEY_LABEL)
