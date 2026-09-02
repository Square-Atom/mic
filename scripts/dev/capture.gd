extends Node

## Development helper: loads the real main scene and writes a PNG of each state
## listed in SHOTS. Lets the UI be inspected without a human having to look at
## the window.
## Run: Godot_v472.exe --path <project> res://scenes/dev_capture.tscn

const SETTLE_FRAMES := 12

## [file name, circle position, mode, sevenths on, use alternative spelling]
const SHOTS := [
	["c_major_triads", 0, KeyDef.Mode.MAJOR, false, false],
	["f_major_sevenths", 11, KeyDef.Mode.MAJOR, true, false],
	["a_minor_sevenths", 0, KeyDef.Mode.MINOR, true, false],
	["db_major_triads", 7, KeyDef.Mode.MAJOR, false, false],
	["csharp_major_triads", 7, KeyDef.Mode.MAJOR, false, true],
	["c_mixolydian", 11, KeyDef.Mode.MIXOLYDIAN, false, false],
	["d_dorian", 0, KeyDef.Mode.DORIAN, false, false],
]

var _frames := 0
var _shot := 0


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	add_child(load("res://scenes/main.tscn").instantiate())
	_apply_shot()


func _apply_shot() -> void:
	var shot: Array = SHOTS[_shot]
	AppState.select_key(shot[1], shot[2], shot[4])
	AppState.set_show_sevenths(shot[3])


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < SETTLE_FRAMES:
		return
	_frames = 0
	var path: String = "user://%s.png" % SHOTS[_shot][0]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED: ", ProjectSettings.globalize_path(path))
	_shot += 1
	if _shot >= SHOTS.size():
		get_tree().quit()
		return
	_apply_shot()
