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
# Emitted for a future audio layer to consume; nothing listens yet, which is
# the point of the seam - so the "unused" warning is expected here.
@warning_ignore("unused_signal")
signal chord_activated(chord: Chord)
@warning_ignore("unused_signal")
signal note_activated(pitch_class: int)

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


## The chords of the current key, honouring the sevenths toggle.
func current_chords() -> Array[Chord]:
	return MusicTheory.diatonic_chords(selected_key, show_sevenths)
