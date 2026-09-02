extends Node

## Lets a MIDI controller play the on-screen keyboards.
##
## Like the audio layer, this talks only to AppState: it turns controller
## events into the same activate_note() call the on-screen keys already make,
## so nothing else in the app knows or cares where a note came from.
##
## Godot's MIDI support is input only, which is all this needs. Ports are held
## open only while the toggle is on, so an unused controller is not claimed.

## Softest and loudest a struck key can sound. Every tone is rendered at the
## same peak, so without this the controller would feel like a typewriter.
const QUIETEST_DB := -22.0
const LOUDEST_DB := 0.0
## MIDI velocity is 1-127; 0 means note-off sent as a note-on.
const MAX_VELOCITY := 127.0

var _open := false


func _ready() -> void:
	AppState.midi_enabled_changed.connect(_on_midi_enabled_changed)
	_set_open(AppState.midi_enabled)


func _exit_tree() -> void:
	_set_open(false)


func _on_midi_enabled_changed(enabled: bool) -> void:
	_set_open(enabled)


func _set_open(open: bool) -> void:
	if open == _open:
		return
	_open = open
	if open:
		OS.open_midi_inputs()
	else:
		OS.close_midi_inputs()


func _input(event: InputEvent) -> void:
	if not _open or event is not InputEventMIDI:
		return
	var midi := event as InputEventMIDI
	match midi.message:
		MIDI_MESSAGE_NOTE_ON:
			# A note-on with zero velocity is how many controllers say note-off.
			if midi.velocity > 0:
				_press(midi.pitch, midi.velocity)
			else:
				_release(midi.pitch)
		MIDI_MESSAGE_NOTE_OFF:
			_release(midi.pitch)


func _press(pitch: int, velocity: int) -> void:
	var midi := MusicTheory.fold_into_range(pitch)
	AppState.activate_note(midi, _velocity_db(velocity))
	AppState.set_note_held(midi, true)
	get_viewport().set_input_as_handled()


func _release(pitch: int) -> void:
	# The tones decay on their own, so a release only clears the highlight -
	# there is no note to cut short.
	AppState.set_note_held(MusicTheory.fold_into_range(pitch), false)
	get_viewport().set_input_as_handled()


func _velocity_db(velocity: int) -> float:
	return lerpf(QUIETEST_DB, LOUDEST_DB, clampf(velocity / MAX_VELOCITY, 0.0, 1.0))
