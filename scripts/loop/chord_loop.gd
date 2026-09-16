extends Node

## Autoload holding the chord loop: an ordered list of scale degrees, a tempo,
## an ostinato, and the clock that turns all three into sound.
##
## Slots hold DEGREES, never chords. A degree is resolved against AppState at
## the moment it sounds, which is what lets the key change under a running loop:
## I - IV - V - I stays I - IV - V - I and simply transposes, and flipping the
## sevenths toggle re-voices the next beat instead of invalidating the loop.
##
## Sound leaves through AppState.activate_note - the same seam the chord rows
## use - so the audio layer needs to know nothing about looping, and this file
## can be deleted without touching it.

## Eight is as long a progression as the strip can show without the numerals
## shrinking past reading size. Longer loops are a different feature.
const MAX_SLOTS := 8

## Every chord occupies one bar, whatever figure is playing over it, so changing
## the ostinato re-shapes the loop without changing its length.
const BEATS_PER_BAR := 4

const MIN_TEMPO := 40
const MAX_TEMPO := 240
## One press of the spinner. Coarse on purpose: the useful gesture is "a bit
## faster", and a beginner nudging by one would be there all day.
const TEMPO_STEP := 10
const DEFAULT_TEMPO := 130

## Longest gap the clock will honour in one frame. A window drag or a stalled
## frame can hand _process a delta of several seconds, and catching up on it
## would fire a burst of notes all at once; the loop drops the missed steps and
## carries on in time instead.
const MAX_CATCH_UP := 0.1

signal slots_changed(slots: PackedInt32Array)
signal tempo_changed(bpm: int)
signal ostinato_changed(index: int)
signal playing_changed(playing: bool)
## Which slot is sounding, and which moment of its figure. The strip highlights
## from this without knowing anything about how the notes were chosen.
signal step_advanced(slot: int, step: int)

## Scale degrees, 0-6, in playing order.
var slots := PackedInt32Array()
var tempo_bpm := DEFAULT_TEMPO
var ostinato := Ostinato.DEFAULT_INDEX
var playing := false

var _slot := 0
var _step := 0
## Time accrued towards the next step. An accumulator rather than a chain of
## timers: awaiting one timer to start the next compounds a frame of error per
## step, which over a looping bar is audible drift.
var _elapsed := 0.0


func _ready() -> void:
	# Nothing to count while the loop is stopped, which is most of the time.
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += minf(delta, MAX_CATCH_UP)
	var duration := _step_duration()
	while _elapsed >= duration:
		_elapsed -= duration
		_advance()
		# The tempo may have been nudged mid-bar, so the next step is measured
		# afresh rather than against the length this one happened to have.
		duration = _step_duration()


# --- The progression -------------------------------------------------------

## Append a degree. Silently does nothing once the strip is full, because the
## button that calls this is one of seven identical ones and disabling them all
## on a full loop would be a harsher answer than the gesture deserves.
func add_slot(degree: int) -> void:
	if slots.size() >= MAX_SLOTS:
		return
	slots.append(wrapi(degree, 0, 7))
	slots_changed.emit(slots)


func remove_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	slots.remove_at(index)
	# The playhead may now be pointing past the end, or at nothing at all.
	if slots.is_empty():
		stop()
	else:
		_slot = mini(_slot, slots.size() - 1)
	slots_changed.emit(slots)


## Move the slot at `from` so that it lands at `to`, where `to` is an insertion
## point measured on the list as it looks BEFORE the move. That is what a drag
## reports - the gap the cursor is hovering over - so the correction for having
## pulled the slot out from under those gaps belongs here rather than in the UI.
func move_slot(from: int, to: int) -> void:
	if from < 0 or from >= slots.size():
		return
	to = clampi(to, 0, slots.size())
	if to > from:
		to -= 1
	if to == from:
		return
	var degree := slots[from]
	slots.remove_at(from)
	slots.insert(to, degree)
	slots_changed.emit(slots)


## Throw the whole progression away.
##
## Stops first. An empty loop has nothing to sound, so a transport left running
## over one would sit there showing a playing state and producing silence -
## and the next chord added would join a bar already half elapsed.
func clear() -> void:
	if slots.is_empty():
		return
	stop()
	slots.clear()
	slots_changed.emit(slots)


# --- Settings --------------------------------------------------------------

func set_tempo(bpm: int) -> void:
	bpm = clampi(bpm, MIN_TEMPO, MAX_TEMPO)
	if bpm == tempo_bpm:
		return
	tempo_bpm = bpm
	tempo_changed.emit(tempo_bpm)


## Nudge by one step in `direction` (+1 or -1), snapped to the step grid so a
## tempo typed in by hand tidies itself up on the first press rather than
## carrying its odd value forever.
func nudge_tempo(direction: int) -> void:
	var steps := float(tempo_bpm) / TEMPO_STEP
	var target := (ceilf(steps) if direction > 0 else floorf(steps)) * TEMPO_STEP
	if int(target) == tempo_bpm:
		target += direction * TEMPO_STEP
	set_tempo(int(target))


func set_ostinato(index: int) -> void:
	index = clampi(index, 0, Ostinato.count() - 1)
	if index == ostinato:
		return
	ostinato = index
	# The new figure has its own number of steps, so the one being counted
	# towards no longer means anything. Restart the bar rather than land the
	# next note at a moment that belongs to the old pattern.
	_step = 0
	_elapsed = 0.0
	ostinato_changed.emit(ostinato)


# --- Transport -------------------------------------------------------------

func play() -> void:
	if playing or slots.is_empty():
		return
	playing = true
	_slot = 0
	_step = 0
	_elapsed = 0.0
	set_process(true)
	playing_changed.emit(playing)
	# The first beat lands on the press rather than a bar's wait later.
	_fire()


func stop() -> void:
	if not playing:
		return
	playing = false
	set_process(false)
	playing_changed.emit(playing)


func toggle() -> void:
	if playing:
		stop()
	else:
		play()


## Where the playhead is, or -1 when the loop is not running. Lets a strip that
## was built mid-playback show the highlight without waiting for the next step.
func current_slot() -> int:
	return _slot if playing else -1


# --- The clock -------------------------------------------------------------

## How long one moment of the figure lasts. The bar is fixed and the figure
## divides it, so a three-note waltz falls as triplets against the same pulse a
## four-note pattern uses.
func _step_duration() -> float:
	var bar := 60.0 / float(tempo_bpm) * BEATS_PER_BAR
	return bar / float(Ostinato.step_count(ostinato))


func _advance() -> void:
	_step += 1
	if _step >= Ostinato.step_count(ostinato):
		_step = 0
		_slot += 1
		if _slot >= slots.size():
			_slot = 0
	_fire()


## Sound the current moment. The chord is looked up now rather than stored,
## which is the whole point of holding degrees.
func _fire() -> void:
	if slots.is_empty():
		stop()
		return
	var chords := AppState.current_chords()
	var voicing := MusicTheory.chord_voicing(chords[slots[_slot]])
	for position in Ostinato.step_at(ostinato, _step):
		AppState.activate_note(Ostinato.midi_for(position, voicing))
	step_advanced.emit(_slot, _step)
