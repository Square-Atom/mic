extends Node

## Autoload singleton holding the one piece of state the whole UI shares:
## which key is selected, and whether chords are shown as sevenths.
##
## The circle writes to it; the chord panel listens. Neither knows the other
## exists, which is what lets either side be replaced or reused on its own.
## `chord_activated` is the deliberate seam for a future audio layer: a player
## can subscribe to it without a single change to the nodes that emit it.

signal key_changed(key: KeyDef)
signal sevenths_changed(enabled: bool)
## Sound requests, in MIDI notes rather than pitch classes: what to play needs
## an octave, and the voicing is decided before it gets here.
signal chord_activated(notes: PackedInt32Array, arpeggiate: bool)
signal note_activated(midi: int)

var selected_key: KeyDef = MusicTheory.key_at(0, KeyDef.Mode.MAJOR)
var show_sevenths: bool = false


## Select a key by circle position, mode and spelling. No-ops (and stays silent)
## if the same key is picked twice, so listeners never rebuild for nothing.
func select_key(position: int, mode: int, use_alt: bool = false) -> void:
	var next := MusicTheory.key_at(position, mode, use_alt)
	if next.equals(selected_key):
		return
	selected_key = next
	key_changed.emit(selected_key)


func set_show_sevenths(enabled: bool) -> void:
	if enabled == show_sevenths:
		return
	show_sevenths = enabled
	sevenths_changed.emit(show_sevenths)


## Ask for a single note. Emitting through AppState rather than letting the UI
## talk to the audio layer directly is what keeps the two unaware of each other.
func activate_note(midi: int) -> void:
	note_activated.emit(midi)


## Ask for a chord, either spread out in order or struck all at once.
func activate_chord(notes: PackedInt32Array, arpeggiate: bool) -> void:
	chord_activated.emit(notes, arpeggiate)


## The chords of the current key, honouring the sevenths toggle.
func current_chords() -> Array[Chord]:
	return MusicTheory.diatonic_chords(selected_key, show_sevenths)
