class_name MusicTheory
extends RefCounted

## Static music-theory derivation. No nodes, no state - everything here is a
## pure function of its arguments so it can be reasoned about (and tested) on
## its own, independently of the UI that displays it.

## The three chords that anchor a key. Every circle wedge that is not one of
## these is just "some other key", and the same is true of the chord list.
enum Function { NONE, TONIC, SUBDOMINANT, DOMINANT }

const MAJOR_INTERVALS := [0, 2, 4, 5, 7, 9, 11]
const NATURAL_MINOR_INTERVALS := [0, 2, 3, 5, 7, 8, 10]

## The 12 circle positions, clockwise from C at the top. Each entry is the
## major tonic as [letter, accidental]; every other fact about the position
## (relative minor, key signature) is indexed by the same position number.
const MAJOR_TONICS := [
	[0, 0],   # 0  C
	[4, 0],   # 1  G
	[1, 0],   # 2  D
	[5, 0],   # 3  A
	[2, 0],   # 4  E
	[6, 0],   # 5  B
	[3, 1],   # 6  F#  (enharmonic with Gb)
	[1, -1],  # 7  Db
	[5, -1],  # 8  Ab
	[2, -1],  # 9  Eb
	[6, -1],  # 10 Bb
	[3, 0],   # 11 F
]

## Key signature per position: positive = sharps, negative = flats.
const SIGNATURES := [0, 1, 2, 3, 4, 5, 6, -5, -4, -3, -2, -1]

## The three positions at the bottom of the circle each have a second, equally
## standard spelling. They are separate, separately selectable keys here: Db
## major and C# major sound the same but are written differently, and picking
## one decides how every chord and every piano key below is spelled.
##
## The tonics are written out rather than derived, because "the other name for
## this key" is a convention, not something arithmetic can be trusted to pick.
const MAJOR_ALT_TONICS := {5: [0, -1], 6: [4, -1], 7: [0, 1]}   # Cb, Gb, C#
const MINOR_ALT_TONICS := {5: [5, -1], 6: [2, -1], 7: [5, 1]}   # Abm, Ebm, A#m
## Key signature of each alternative spelling - genuinely different from the
## primary one, since C-flat major needs 7 flats where B major needs 5 sharps.
const ALT_SIGNATURES := {5: -7, 6: -6, 7: 7}

## The major tonic at a circle position.
static func major_tonic(position: int) -> Note:
	var entry: Array = MAJOR_TONICS[wrapi(position, 0, 12)]
	return Note.new(entry[0], entry[1])


## The relative minor tonic at a circle position. A relative minor sits a minor
## third below its major, which is always two letter names down - so the letter
## is found by stepping back two, and the accidental by matching the pitch class.
static func minor_tonic(position: int) -> Note:
	var maj := major_tonic(position)
	var letter := wrapi(maj.letter - 2, 0, 7)
	var target_pc := wrapi(maj.pitch_class() - 3, 0, 12)
	return Note.new(letter, _accidental_for(letter, target_pc))


## Does this position carry two equally standard names?
static func has_alt_spelling(position: int) -> bool:
	return MAJOR_ALT_TONICS.has(wrapi(position, 0, 12))


## Build a KeyDef for a circle position, mode and spelling.
##
## `use_alt` is the whole mechanism behind C# major being a different key from
## Db major: the tonic Note carries the spelling and scale_notes() derives
## everything from it, so asking for C# yields C# D# E# F# G# A# B# with no
## special-casing anywhere downstream.
static func key_at(position: int, mode: int, use_alt: bool = false) -> KeyDef:
	position = wrapi(position, 0, 12)
	use_alt = use_alt and has_alt_spelling(position)
	var tonic: Note
	if use_alt:
		var table: Dictionary = MAJOR_ALT_TONICS if mode == KeyDef.Mode.MAJOR else MINOR_ALT_TONICS
		var entry: Array = table[position]
		tonic = Note.new(entry[0], entry[1])
	else:
		tonic = major_tonic(position) if mode == KeyDef.Mode.MAJOR else minor_tonic(position)
	return KeyDef.new(tonic, mode, position, use_alt)


## Signed key signature of a specific key: positive sharps, negative flats.
## Honours the spelling, so C# major reports 7 sharps where Db reports 5 flats.
static func signature_of(key: KeyDef) -> int:
	if key.use_alt_spelling and ALT_SIGNATURES.has(key.circle_position):
		return ALT_SIGNATURES[key.circle_position]
	return SIGNATURES[wrapi(key.circle_position, 0, 12)]


## Which accidental bends the natural letter `letter` onto `target_pc`.
## wrapi into -6..5 picks the shortest direction, so we get B flat (-1) rather
## than an absurd B sharp-sharp-sharp-... for the same sounding pitch.
static func _accidental_for(letter: int, target_pc: int) -> int:
	var natural_pc: int = Note.LETTER_SEMITONES[letter]
	return wrapi(target_pc - natural_pc, -6, 6)


## The seven spelled notes of a key's scale.
##
## The spelling rule is the whole trick: each successive degree takes the NEXT
## letter name, no matter what. That guarantees exactly one of each letter
## (C D E F G A B), and the accidental is then whatever is needed to land on the
## right pitch. F major therefore comes out as F G A B-flat C D E - never A-sharp.
static func scale_notes(key: KeyDef) -> Array[Note]:
	var intervals: Array = MAJOR_INTERVALS if key.is_major() else NATURAL_MINOR_INTERVALS
	var tonic_pc := key.tonic.pitch_class()
	var out: Array[Note] = []
	for degree in 7:
		var letter := wrapi(key.tonic.letter + degree, 0, 7)
		var target_pc := wrapi(tonic_pc + intervals[degree], 0, 12)
		out.append(Note.new(letter, _accidental_for(letter, target_pc)))
	return out


## The seven diatonic chords of a key, built by stacking thirds on each degree.
##
## Stacking is done in *scale-degree* space (degree, +2, +4, and +6 for sevenths)
## rather than in semitones. Because the scale is already correctly spelled, the
## right chord quality falls out of the arithmetic for both major and minor keys.
static func diatonic_chords(key: KeyDef, with_sevenths: bool) -> Array[Chord]:
	var scale := scale_notes(key)
	var offsets := [0, 2, 4, 6] if with_sevenths else [0, 2, 4]
	var out: Array[Chord] = []
	for degree in 7:
		var chord_notes: Array[Note] = []
		for offset in offsets:
			chord_notes.append(scale[wrapi(degree + offset, 0, 7)])
		out.append(Chord.new(chord_notes, _quality_of(chord_notes), degree))
	return out


## Which anchoring role a chord plays in a key.
##
## Read from the interval of the chord's root above the tonic rather than from
## its degree number, so it stays correct for any scale: a perfect fourth is
## the subdominant whether it is the IV of a major key or the iv of a minor one.
static func chord_function(key: KeyDef, chord: Chord) -> int:
	match wrapi(chord.root().pitch_class() - key.tonic.pitch_class(), 0, 12):
		0:
			return Function.TONIC
		5:
			return Function.SUBDOMINANT
		7:
			return Function.DOMINANT
	return Function.NONE


## The three functional families, which sort ALL seven degrees rather than only
## the three primaries.
##
## The grouping comes from thirds, not fifths: chords a diatonic third apart
## share two of their three notes (I = C E G and vi = A C E share C and E), and
## two shared notes is what lets one stand in for the other. The table is
## indexed by degree, which makes it right in both modes, since those
## third-relationships are the same in major and minor.
enum Family { TONIC, SUBDOMINANT, DOMINANT }

const DEGREE_FAMILIES := [
	Family.TONIC,        # I    home
	Family.SUBDOMINANT,  # ii   a third under IV, and shares two notes with it
	Family.TONIC,        # iii  shares two notes with I - though also two with V
	Family.SUBDOMINANT,  # IV
	Family.DOMINANT,     # V
	Family.TONIC,        # vi   the relative minor of I
	Family.DOMINANT,     # vii  V7 with its root removed
]


## Which functional family a chord belongs to. Unlike chord_function(), every
## degree has an answer, not just the three primaries.
static func chord_family(chord: Chord) -> int:
	return DEGREE_FAMILIES[wrapi(chord.degree, 0, 7)]


## The range the app displays and sounds: two octaves up from C4, ending on B5.
## Stated here so the keyboard, the tone bank and MIDI folding all agree.
const VOICING_BASE_MIDI := 60  # C4
const RANGE_OCTAVES := 2
const LOWEST_MIDI := VOICING_BASE_MIDI
const HIGHEST_MIDI := VOICING_BASE_MIDI + RANGE_OCTAVES * 12 - 1  # B5


## Shift a note by whole octaves until it lands on the keyboard.
##
## A controller spans far more than two octaves, so most of it would otherwise
## do nothing. Folding keeps the pitch class, so a C anywhere on the controller
## lights a C here - what is lost is only which octave it was played in.
static func fold_into_range(midi: int) -> int:
	while midi < LOWEST_MIDI:
		midi += 12
	while midi > HIGHEST_MIDI:
		midi -= 12
	return midi


## The chord as MIDI notes, in root position.
##
## Each note is placed at the first octave ABOVE the one before it, so the
## chord always sounds the way it is spelled instead of as an inversion. That
## keeps everything inside C4-B5: the worst case is a seventh chord rooted on
## B4, whose top note is A#5.
static func chord_voicing(chord: Chord) -> PackedInt32Array:
	var out := PackedInt32Array()
	var previous := VOICING_BASE_MIDI + chord.root().pitch_class() - 1
	for note in chord.notes:
		var midi := VOICING_BASE_MIDI + note.pitch_class()
		while midi <= previous:
			midi += 12
		out.append(midi)
		previous = midi
	return out


## The traditional name of each scale degree. Tonic, Subdominant and Dominant
## are not a separate idea from the rest - they are simply the three of these
## seven that also name a harmonic function.
const DEGREE_NAMES := [
	"Tonic",
	"Supertonic",
	"Mediant",
	"Subdominant",
	"Dominant",
	"Submediant",
	"Leading Tone",
]


## The name of the degree a chord is built on.
static func degree_name(key: KeyDef, chord: Chord) -> String:
	var degree := wrapi(chord.degree, 0, 7)
	if degree == 6:
		# The seventh is the one degree whose name depends on where it actually
		# sits. A semitone under the tonic it pulls towards it - it LEADS. Natural
		# minor puts it a whole tone below, with no such pull, and there it is
		# the subtonic instead. Read from the interval rather than the mode, so
		# this stays right for any scale.
		var above := wrapi(chord.root().pitch_class() - key.tonic.pitch_class(), 0, 12)
		return "Leading Tone" if above == 11 else "Subtonic"
	return DEGREE_NAMES[degree]


## Semitones from `root_pc` up to `pc`, always ascending (0-11).
static func _interval_above(root_pc: int, pc: int) -> int:
	return wrapi(pc - root_pc, 0, 12)


## Identify a chord's quality from the intervals its notes form above the root.
static func _quality_of(notes: Array[Note]) -> int:
	var root_pc := notes[0].pitch_class()
	var third := _interval_above(root_pc, notes[1].pitch_class())
	var fifth := _interval_above(root_pc, notes[2].pitch_class())

	if notes.size() < 4:
		if third == 4 and fifth == 7:
			return Chord.Quality.MAJOR
		if third == 3 and fifth == 7:
			return Chord.Quality.MINOR
		if third == 3 and fifth == 6:
			return Chord.Quality.DIMINISHED
		if third == 4 and fifth == 8:
			return Chord.Quality.AUGMENTED
		return Chord.Quality.UNKNOWN

	var seventh := _interval_above(root_pc, notes[3].pitch_class())
	if third == 4 and fifth == 7 and seventh == 11:
		return Chord.Quality.MAJOR7
	if third == 4 and fifth == 7 and seventh == 10:
		return Chord.Quality.DOMINANT7
	if third == 3 and fifth == 7 and seventh == 10:
		return Chord.Quality.MINOR7
	if third == 3 and fifth == 7 and seventh == 11:
		return Chord.Quality.MINOR_MAJOR7
	if third == 3 and fifth == 6 and seventh == 10:
		return Chord.Quality.HALF_DIM7
	if third == 3 and fifth == 6 and seventh == 9:
		return Chord.Quality.DIM7
	if third == 4 and fifth == 8 and seventh == 11:
		return Chord.Quality.AUG_MAJOR7
	return Chord.Quality.UNKNOWN


## Key signature of one specific key, spelled out. Takes the key rather than a
## position, because a position's two spellings have different signatures.
static func signature_text(key: KeyDef) -> String:
	var count := signature_of(key)
	if count == 0:
		return "no sharps or flats"
	return _accidental_count_text(count)


## Compact key signature for the ring of labels around the circle. Positions
## that carry two spellings show both counts, because the two really do differ.
## The sharp count is written first to match the wedges it labels, where the
## sharp spelling is the inner half - so label and ring read in the same order.
static func signature_short(position: int) -> String:
	position = wrapi(position, 0, 12)
	var count: int = SIGNATURES[position]
	if not ALT_SIGNATURES.has(position):
		return "\u2013" if count == 0 else _accidental_count_text(count)
	var alt: int = ALT_SIGNATURES[position]
	return "%s/%s" % [
		_accidental_count_text(maxi(count, alt)),
		_accidental_count_text(mini(count, alt)),
	]


static func _accidental_count_text(count: int) -> String:
	return "%d\u266f" % count if count > 0 else "%d\u266d" % -count


## The name on a wedge, for whichever of the position's spellings it represents.
static func wedge_label(position: int, mode: int, use_alt: bool = false) -> String:
	return key_at(position, mode, use_alt).short_name()



## The scale notes joined for display, e.g. "C  D  E  F  G  A  B".
static func scale_text(key: KeyDef) -> String:
	var parts := PackedStringArray()
	for n in scale_notes(key):
		parts.append(n.display_name())
	return "   ".join(parts)
