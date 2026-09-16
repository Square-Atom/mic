class_name TempoSpinner
extends HBoxContainer

## Tempo, typed or nudged.
##
## A SpinBox would give this for free but brings its own arrows, its own theme
## and a font that will not match the drawn buttons beside it. This is a text
## field between two IconButtons, and the value it edits lives in ChordLoop
## rather than here - the field is only ever showing what the loop already
## thinks, which is why an out-of-range entry can simply be clamped and
## redisplayed without anything having to be undone.

const BUTTON_SIZE := Vector2(34.0, 34.0)
const FIELD_MIN_WIDTH := 64.0
const FIELD_FONT_SIZE := 20

var _field: LineEdit


func _init() -> void:
	add_theme_constant_override("separation", 6)

	var down := IconButton.new()
	down.glyph = IconButton.Glyph.ARROW_DOWN
	down.custom_minimum_size = BUTTON_SIZE
	down.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	down.tooltip_text = "Slower by %d BPM" % ChordLoop.TEMPO_STEP
	down.pressed.connect(func() -> void: ChordLoop.nudge_tempo(-1))
	add_child(down)

	_field = LineEdit.new()
	_field.custom_minimum_size = Vector2(FIELD_MIN_WIDTH, 0.0)
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_field.add_theme_font_size_override("font_size", FIELD_FONT_SIZE)
	_field.tooltip_text = "Beats per minute (%d-%d)" % [ChordLoop.MIN_TEMPO, ChordLoop.MAX_TEMPO]
	add_child(_field)

	var up := IconButton.new()
	up.glyph = IconButton.Glyph.ARROW_UP
	up.custom_minimum_size = BUTTON_SIZE
	up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	up.tooltip_text = "Faster by %d BPM" % ChordLoop.TEMPO_STEP
	up.pressed.connect(func() -> void: ChordLoop.nudge_tempo(1))
	add_child(up)


func _ready() -> void:
	# Enter commits; clicking away commits too, so a typed value is never left
	# sitting in the box looking as though it had taken effect.
	_field.text_submitted.connect(_on_submitted)
	_field.focus_exited.connect(_on_focus_lost)
	ChordLoop.tempo_changed.connect(_on_tempo_changed)
	_show(ChordLoop.tempo_bpm)


func _on_submitted(text: String) -> void:
	_commit(text)
	_field.release_focus()


func _on_focus_lost() -> void:
	_commit(_field.text)


## Take whatever was typed, or put the current tempo back if it was not a
## number. String.to_int() reads "abc" as 0, which would otherwise clamp to the
## minimum and quietly replace the tempo with 40.
func _commit(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_valid_int():
		ChordLoop.set_tempo(trimmed.to_int())
	_show(ChordLoop.tempo_bpm)


func _on_tempo_changed(bpm: int) -> void:
	_show(bpm)


func _show(bpm: int) -> void:
	var text := str(bpm)
	if _field.text == text:
		return
	_field.text = text
	_field.caret_column = text.length()
