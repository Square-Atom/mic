class_name MusicTheory
extends RefCounted

## Static music-theory derivation. No nodes, no state - everything here is a
## pure function of its arguments so it can be reasoned about (and tested) on
## its own, independently of the UI that displays it.

## The three chords that anchor a key. Every circle wedge that is not one of
## these is just "some other key", and the same is true of the chord list.
enum Function { NONE, TONIC, SUBDOMINANT, DOMINANT }

## Semitones above the tonic for each degree, one row per mode. Every row is
## the major scale rotated to start on a different degree, which is exactly
## what a mode is - written out rather than computed so each is readable and
## checkable at a glance.
const MODE_INTERVALS := [
	[0, 2, 4, 5, 7, 9, 11],  # Major / Ionian
	[0, 2, 3, 5, 7, 9, 10],  # Dorian
	[0, 1, 3, 5, 7, 8, 10],  # Phrygian
	[0, 2, 4, 6, 7, 9, 11],  # Lydian
	[0, 2, 4, 5, 7, 9, 10],  # Mixolydian
	[0, 2, 3, 5, 7, 8, 10],  # Minor / Aeolian
	[0, 1, 3, 5, 6, 8, 10],  # Locrian
]

## The names keys are usually called by, and the ones used in headings.
const MODE_NAMES := [
	"Major", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Minor", "Locrian",
]

## The classical names. Only two of them differ from the list above: major and
## minor are simply Ionian and Aeolian under older names, and showing both makes
## that plain instead of leaving the seven looking like five modes plus two
## outsiders.
const MODE_CLASSICAL_NAMES := [
	"Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian",
]

## How far each mode's tonic sits from its parent major's tonic, in fifths -
## which is to say, how far round the circle. Reading the degrees in
## circle-of-fifths order gives I=0, V=+1, II=+2, VI=+3, III=+4, VII=+5, IV=-1.
## This is what lets the mode selector hold a tonic still and move the
## signature instead.
const MODE_FIFTHS_OFFSET := [0, 2, 4, -1, 1, 3, 5]

## What each mode sounds like. The formula is not written here - see
## mode_formula(), which reads it off the interval table so the two can never
## drift apart.
const MODE_DESCRIPTIONS := [
	"The standard major scale; sounds bright, stable, and happy.",
	"A minor-type scale with a raised 6th degree; sounds jazzy, mystical, or bittersweet.",
	"A minor-type scale with a lowered 2nd degree; sounds dark, Spanish, or exotic.",
	"A major-type scale with a raised 4th degree; sounds dreamy, floating, and magical.",
	"A major-type scale with a lowered 7th degree; sounds bluesy, classic rock, and laid-back.",
	"The standard natural minor scale; sounds sad, serious, and pensive.",
	"A diminished scale with lowered 5th and 2nd degrees; sounds tense, unstable, and dark.",
]



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


## The tonic of a mode built on a circle position.
##
## A mode starts on a degree of its parent major scale, and Mode's values ARE
## those degree numbers - so this is a lookup into the parent's scale rather
## than a separate calculation. Minor comes out as the sixth degree, which is
## the relative minor, exactly as before.
static func mode_tonic(position: int, mode: int, use_alt: bool = false) -> Note:
	var parent_tonic := major_tonic(position)
	if use_alt and has_alt_spelling(position):
		var entry: Array = MAJOR_ALT_TONICS[wrapi(position, 0, 12)]
		parent_tonic = Note.new(entry[0], entry[1])
	var parent := KeyDef.new(parent_tonic, KeyDef.Mode.MAJOR, position, use_alt)
	return scale_notes(parent)[wrapi(mode, 0, 7)]


## Does this position carry two equally standard names?
static func has_alt_spelling(position: int) -> bool:
	return MAJOR_ALT_TONICS.has(wrapi(position, 0, 12))


## Build a KeyDef for a wedge on the circle. `ring` is MAJOR for the outer ring
## or MINOR for the inner, and it is also the key's starting mode.
##
## `use_alt` is the mechanism behind C# major being a different key from Db
## major: the tonic Note carries the spelling and scale_notes() derives
## everything from it, so asking for C# yields C# D# E# F# G# A# B# with no
## special-casing anywhere downstream.
static func key_at(position: int, ring: int, use_alt: bool = false) -> KeyDef:
	position = wrapi(position, 0, 12)
	use_alt = use_alt and has_alt_spelling(position)
	return KeyDef.new(mode_tonic(position, ring, use_alt), ring, position, use_alt, ring)


## The same key re-flavoured into another mode.
##
## Neither the tonic nor the wedge moves: C Dorian is still C, drawn on C's
## wedge, with F and G still either side of it. What changes is the set of
## notes above that tonic - and therefore the key signature, which is why
## signature_of() works it out rather than reading it off the position.
static func with_mode(key: KeyDef, mode: int) -> KeyDef:
	return KeyDef.new(key.tonic, mode, key.circle_position, key.use_alt_spelling, key.circle_ring)


## Signed key signature of a specific key: positive sharps, negative flats.
##
## The wedge fixes a starting signature and the mode shifts it. One step round
## the circle is one fifth and one accidental, so the shift is the difference
## between the two modes' distances from their parent major: C on the major
## wedge has none, while C Dorian has two flats, because a Dorian tonic sits
## two fifths above its parent's.
static func signature_of(key: KeyDef) -> int:
	var base: int = SIGNATURES[wrapi(key.circle_position, 0, 12)]
	if key.use_alt_spelling and ALT_SIGNATURES.has(key.circle_position):
		base = ALT_SIGNATURES[key.circle_position]
	return base + MODE_FIFTHS_OFFSET[key.circle_ring] - MODE_FIFTHS_OFFSET[key.mode]


## The major key whose signature this mode borrows. For a plain major or minor
## key that is the wedge itself, or its relative.
static func parent_major(key: KeyDef) -> KeyDef:
	var steps: int = MODE_FIFTHS_OFFSET[key.circle_ring] - MODE_FIFTHS_OFFSET[key.mode]
	return key_at(key.circle_position + steps, KeyDef.Mode.MAJOR, key.use_alt_spelling)


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
	var intervals: Array = MODE_INTERVALS[key.mode]
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


## Whether a note falls on the keyboard the app draws.
##
## Notes outside it are ignored rather than folded in by octaves. Folding meant
## a C two octaves down lit the C here, so a key you did not press appeared to
## respond - which is harder to make sense of than silence.
static func is_in_range(midi: int) -> bool:
	return midi >= LOWEST_MIDI and midi <= HIGHEST_MIDI


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

## The interval a name asserts, for the degrees whose name is a claim about
## distance rather than merely position. Subdominant and Dominant do not mean
## "the fourth" and "the fifth" - they name the PERFECT fourth and fifth, the
## two consonances a tonic is heard against. Lydian raises the fourth and
## Locrian flattens the fifth, and once the interval is gone, so is the pull
## the name describes.
const FUNCTION_INTERVALS := {3: 5, 4: 7}


## The name of the degree a chord is built on.
static func degree_name(key: KeyDef, chord: Chord) -> String:
	var degree := wrapi(chord.degree, 0, 7)
	var above := _interval_above(key.tonic.pitch_class(), chord.root().pitch_class())
	if degree == 6:
		# The seventh depends on where it actually sits. A semitone under the
		# tonic it pulls towards it - it LEADS. Natural minor puts it a whole tone
		# below, with no such pull, and there it is the subtonic instead. Read from
		# the interval rather than the mode, so this stays right for any scale.
		return "Leading Tone" if above == 11 else "Subtonic"
	# The same reasoning for the two function names. Calling Lydian's raised
	# fourth a subdominant would promise the reader a pull that is not there, so
	# the cell is left empty and the colour carries the meaning on its own.
	if FUNCTION_INTERVALS.has(degree) and above != FUNCTION_INTERVALS[degree]:
		return ""
	return DEGREE_NAMES[degree]


## Whether `mode` still spells the perfect interval that `degree` is named for.
##
## Only the fourth and fifth degrees make such a claim; every other degree is
## named for its position alone and is always present. Lydian raises the fourth
## and Locrian flattens the fifth, and in those two cases the key a fifth away
## on the circle has a tonic the scale does not even contain - so marking it
## would point the reader at a note that is not in the mode.
static func has_function_degree(mode: int, degree: int) -> bool:
	if not FUNCTION_INTERVALS.has(degree):
		return true
	return MODE_INTERVALS[wrapi(mode, 0, 7)][degree] == FUNCTION_INTERVALS[degree]


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


## The mode's degrees written against the major scale, e.g. "1 2 b3 4 5 6 b7".
##
## Read off the interval table rather than spelled out, so a mode's formula and
## the notes it actually produces cannot disagree - the formula IS the table,
## expressed as distance from major.
static func mode_formula(mode: int) -> String:
	var intervals: Array = MODE_INTERVALS[wrapi(mode, 0, 7)]
	var major: Array = MODE_INTERVALS[KeyDef.Mode.MAJOR]
	var parts := PackedStringArray()
	for degree in 7:
		var shift: int = intervals[degree] - major[degree]
		var mark := ""
		if shift < 0:
			mark = "\u266d"
		elif shift > 0:
			mark = "\u266f"
		parts.append("%s%d" % [mark, degree + 1])
	return " ".join(parts)


## What the mode sounds like, in words.
static func mode_description(mode: int) -> String:
	return MODE_DESCRIPTIONS[wrapi(mode, 0, 7)]


## The name on a wedge, for whichever of the position's spellings it represents.
static func wedge_label(position: int, mode: int, use_alt: bool = false) -> String:
	return key_at(position, mode, use_alt).short_name()



## The scale notes joined for display, e.g. "C  D  E  F  G  A  B".
static func scale_text(key: KeyDef) -> String:
	var parts := PackedStringArray()
	for n in scale_notes(key):
		parts.append(n.display_name())
	return "   ".join(parts)
