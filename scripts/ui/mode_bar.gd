class_name ModeBar
extends HBoxContainer

## The mode selector under the circle.
##
## Holds the TONIC still and changes the flavour: picking Mixolydian while in C
## gives you C Mixolydian, not G. That is how a composer thinks about modes, and
## it is why the key signature - and so the circle's highlight - moves instead.
## Watching the highlight travel to F when you pick C Mixolydian is the lesson.

const CHIP_SCENE := preload("res://scenes/mode_chip.tscn")

var _chips: Array[ModeChip] = []


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER
	for mode in MusicTheory.MODE_NAMES.size():
		var chip: ModeChip = CHIP_SCENE.instantiate()
		add_child(chip)
		chip.set_mode_name(MusicTheory.MODE_NAMES[mode])
		chip.pressed.connect(_on_chip_pressed.bind(mode))
		_chips.append(chip)
	AppState.key_changed.connect(_on_key_changed)
	_refresh()


func _on_key_changed(_key: KeyDef) -> void:
	_refresh()


func _on_chip_pressed(mode: int) -> void:
	var key: KeyDef = AppState.selected_key
	if mode == key.mode:
		return
	# The position moves so the tonic does not.
	AppState.select_key(MusicTheory.position_for_mode(key, mode), mode, key.use_alt_spelling)


func _refresh() -> void:
	for mode in _chips.size():
		_chips[mode].set_active(mode == AppState.selected_key.mode)
