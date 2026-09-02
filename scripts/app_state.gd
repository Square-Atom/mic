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
signal note_activated(midi: int, volume_db: float)
## Which notes are being physically held down on a controller.
signal held_notes_changed(held: Dictionary)
signal midi_enabled_changed(enabled: bool)

var selected_key: KeyDef = MusicTheory.key_at(0, KeyDef.Mode.MAJOR)
var show_sevenths: bool = false
var midi_enabled: bool = true
## Used as a set: the keys are MIDI notes currently held down.
var held_notes := {}


## Select a key by circle position, mode and spelling. No-ops (and stays silent)
## if the same key is picked twice, so listeners never rebuild for nothing.
func select_key(position: int, ring: int, use_alt: bool = false) -> void:
	var next := MusicTheory.key_at(position, ring, use_alt)
	# Picking a wedge moves the tonic; it does not undo the mode. The exception
	# is plain major and minor, where the two rings ARE the two modes, so
	# clicking one is how you ask for it.
	if not (selected_key.is_major() or selected_key.is_minor()):
		next = MusicTheory.with_mode(next, selected_key.mode)
	if next.equals(selected_key):
		return
	selected_key = next
	key_changed.emit(selected_key)


## Re-flavour the current key. The wedge POSITION never moves - that is the
## whole point of the mode selector - but the ring follows the mode.
##
## Only Aeolian belongs on the inner ring; that ring exists to show relative
## minors and is hidden in every other mode. So a key sitting on it moves out to
## its relative major first - the same clock position, one ring out - rather
## than being left highlighted on a ring that is no longer drawn. Ionian does
## the same in reverse, which is how Am becomes C Major rather than being
## stranded on the Am wedge.
func set_mode(mode: int) -> void:
	if mode == selected_key.mode:
		return
	var ring: int = KeyDef.Mode.MINOR if mode == KeyDef.Mode.MINOR else KeyDef.Mode.MAJOR
	var wedge := MusicTheory.key_at(
			selected_key.circle_position, ring, selected_key.use_alt_spelling)
	selected_key = MusicTheory.with_mode(wedge, mode)
	key_changed.emit(selected_key)


func set_show_sevenths(enabled: bool) -> void:
	if enabled == show_sevenths:
		return
	show_sevenths = enabled
	sevenths_changed.emit(show_sevenths)


## Ask for a single note. Emitting through AppState rather than letting the UI
## talk to the audio layer directly is what keeps the two unaware of each other.
func activate_note(midi: int, volume_db: float = 0.0) -> void:
	note_activated.emit(midi, volume_db)


## Mark a note as physically held, so the keyboards can show it pressed. This
## is separate from activate_note: sounding a note and holding a key down are
## different events, and only one of them repeats while you keep your finger
## on it.
func set_note_held(midi: int, held: bool) -> void:
	if held:
		held_notes[midi] = true
	else:
		held_notes.erase(midi)
	held_notes_changed.emit(held_notes)


func set_midi_enabled(enabled: bool) -> void:
	if enabled == midi_enabled:
		return
	midi_enabled = enabled
	if not enabled and not held_notes.is_empty():
		# Nothing will send the note-offs once input is closed.
		held_notes.clear()
		held_notes_changed.emit(held_notes)
	midi_enabled_changed.emit(midi_enabled)


## Ask for a chord, either spread out in order or struck all at once.
func activate_chord(notes: PackedInt32Array, arpeggiate: bool) -> void:
	chord_activated.emit(notes, arpeggiate)


## The chords of the current key, honouring the sevenths toggle.
func current_chords() -> Array[Chord]:
	return MusicTheory.diatonic_chords(selected_key, show_sevenths)
