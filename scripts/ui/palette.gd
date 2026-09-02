class_name Palette
extends RefCounted

## Every colour the app draws, in one place. The circle wedges, the piano keys
## and the chord rows all pull from here so that a highlight means the same
## thing wherever it appears - amber is always "this is selected / in the chord".

const BG := Color("#12141a")
const PANEL := Color("#1a1d26")
const PANEL_EDGE := Color("#2b3040")
const TEXT := Color("#e8ebf2")
const TEXT_DIM := Color("#8a92a6")
const TEXT_FAINT := Color("#5d657a")

# Shared meaning of the accents. A colour means the same thing everywhere it
# appears, so the circle and the keyboards can be read against each other.
const ACCENT := Color("#f0a63c")          # the tonic: home, both on the circle and in a chord
const ACCENT_SEVENTH := Color("8361caff")  # the added 7th - in the chord, but not a triad tone

## Rows that are not the tonic, subdominant or dominant. They still need to be
## clearly lit, but in something quiet enough not to compete with the three
## chords that actually anchor the key.
const DEGREE_NEUTRAL := Color("#9fc0da")

# Keyboard roles. Root and chord tone are no longer fixed colours: a row takes
# its family from the chord's function and shades within it, so the highlighted
# keys and the circle wedge say the same thing about a chord.
const KEY_SEVENTH := ACCENT_SEVENTH
## How far the supporting tones of a chord sit below its root. Enough to be
## obvious, but not so far that they sink toward the resting keys.
const SUPPORTING_DARKEN := 0.22
## How far their hue turns as well. Value alone reads as the same colour under
## worse light; a small rotation makes them a deliberately different shade
## instead. Negative turns warm, which is the direction that suits the amber
## tonic - the pairing this was originally tuned against.
const SUPPORTING_HUE_SHIFT := -0.035
const RELATIVE := Color("2f77c6ff")        # the relative major/minor of the selection
const DOMINANT := Color("#cf5f7a")        # the V - one step clockwise on the circle
const SUBDOMINANT := Color("#5f9e7a")     # the IV - one step anticlockwise

# Circle of fifths.
const RING_MAJOR := Color("#242a3a")
const RING_MINOR := Color("#1b202c")
const RING_EDGE := Color("#12141a")
const HOVER_TINT := Color(1, 1, 1, 0.10)

# Piano keys.
## Resting keys sit well back: the point of the keyboard is the handful of keys
## that are lit. They have to stay darker than the DARKEST highlight - which is
## now a chord's third and fifth - or an unlit key would outshine a lit one.
## Still clearly separated from each other, so it reads as a piano.
const KEY_WHITE := Color("#474e60")
const KEY_BLACK := Color("#1b202c")
const KEY_EDGE := Color("#0d0f14")
const LABEL_ON_LIGHT := Color("#1a1d26")
const LABEL_ON_DARK := Color("#c6cede")

## Note names on the keys are always drawn dark, never switched for contrast.
## Only highlighted keys carry a label and every highlight is light enough to
## hold it, so a fixed colour is the better trade: a label that flips shade
## partway along a keyboard draws more attention than the contrast it buys.
const KEY_LABEL := LABEL_ON_LIGHT


## A chord tone that is not the root: darker, and turned slightly in hue. The
## root keeps the family's full brightness so it reads as the top of the chord,
## and the third and fifth sit under it - which is also how they sound.
static func supporting_tone(color: Color) -> Color:
	return Color.from_hsv(
		fposmod(color.h + SUPPORTING_HUE_SHIFT, 1.0),
		color.s,
		color.v * (1.0 - SUPPORTING_DARKEN),
		color.a
	)


## Text colour that stays readable on top of `background`.
static func contrast_text(background: Color) -> Color:
	# Rec. 601 luma - cheap, and accurate enough to pick between two colours.
	# Used for the circle wedges, whose resting rings are dark enough to need
	# light text; the piano keys deliberately opt out and use KEY_LABEL.
	var luma := 0.299 * background.r + 0.587 * background.g + 0.114 * background.b
	return LABEL_ON_LIGHT if luma > 0.5 else LABEL_ON_DARK
