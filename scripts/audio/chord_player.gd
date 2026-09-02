extends Node

## Turns the app's activation signals into sound.
##
## This is the audio layer the rest of the app was built to accept: it connects
## to AppState and nothing else, and no other script knows it exists. Deleting
## this file silences the app without breaking anything.
##
## One AudioStreamPlayer holds an AudioStreamPolyphonic, which can start several
## overlapping voices by itself. That is why there is no pool of players here
## and no voice-stealing logic to get wrong.

const POLYPHONY := 24
## Gap between notes of an arpeggio. Slow enough to hear each note land,
## quick enough that the three still read as one chord.
const ARPEGGIO_GAP := 0.22
const VOLUME_DB := -4.0

var _bank := ToneBank.new()
var _playback: AudioStreamPlaybackPolyphonic
## Bumped by every new arpeggio so an earlier one abandons its remaining notes
## rather than interleaving with the new one.
var _sequence_token := 0
## Next note to pre-render during idle frames. Rendering the first note of a
## chord on the click that asks for it is audible as lag, so the bank fills
## itself in the background once the app is up, a note at a time.
var _warm_next := -1


func _ready() -> void:
	var polyphonic := AudioStreamPolyphonic.new()
	polyphonic.polyphony = POLYPHONY
	var player := AudioStreamPlayer.new()
	player.stream = polyphonic
	player.volume_db = VOLUME_DB
	add_child(player)
	player.play()
	_playback = player.get_stream_playback() as AudioStreamPlaybackPolyphonic

	AppState.note_activated.connect(play_note)
	AppState.chord_activated.connect(_on_chord_activated)
	_warm_next = ToneBank.LOWEST_MIDI


func _process(_delta: float) -> void:
	if _warm_next < 0:
		return
	if _warm_next > ToneBank.HIGHEST_MIDI:
		_warm_next = -1
		set_process(false)
		return
	# One per frame: the whole bank in a single frame would freeze the UI, and
	# nothing needs it that urgently.
	_bank.tone_for(_warm_next)
	_warm_next += 1


func play_note(midi: int, volume_db: float = 0.0) -> void:
	if _playback == null:
		return
	_playback.play_stream(_bank.tone_for(midi), 0.0, volume_db)


func _on_chord_activated(notes: PackedInt32Array, arpeggiate: bool) -> void:
	if arpeggiate:
		_play_in_order(notes)
	else:
		for midi in notes:
			play_note(midi)


func _play_in_order(notes: PackedInt32Array) -> void:
	_sequence_token += 1
	var token := _sequence_token
	for midi in notes:
		if token != _sequence_token:
			return
		play_note(midi)
		await get_tree().create_timer(ARPEGGIO_GAP).timeout
