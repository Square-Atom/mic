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
const ACCENT_DEEP := Color("#e2662f")     # the supporting notes of a chord
const ACCENT_SEVENTH := Color("#9b7ede")  # the added 7th - in the chord, but not a triad tone

# Keyboard roles, named separately from the raw colours so the highlight
# meanings can be re-pointed without hunting through the drawing code.
const KEY_ROOT := ACCENT
const KEY_CHORD_TONE := ACCENT_DEEP
const KEY_SEVENTH := ACCENT_SEVENTH
const RELATIVE := Color("#6fb3c9")        # the relative major/minor of the selection
const DOMINANT := Color("#cf5f7a")        # the V - one step clockwise on the circle
const SUBDOMINANT := Color("#5f9e7a")     # the IV - one step anticlockwise

# Circle of fifths.
const RING_MAJOR := Color("#242a3a")
const RING_MINOR := Color("#1b202c")
const RING_EDGE := Color("#12141a")
const HOVER_TINT := Color(1, 1, 1, 0.10)

# Piano keys.
const KEY_WHITE := Color("#e9edf5")
const KEY_BLACK := Color("#222634")
const KEY_EDGE := Color("#0d0f14")
const LABEL_ON_LIGHT := Color("#1a1d26")
const LABEL_ON_DARK := Color("#c6cede")


## Text colour that stays readable on top of `background`.
static func contrast_text(background: Color) -> Color:
	# Rec. 601 luma - cheap, and accurate enough to pick between two colours.
	# The threshold sits at 0.5 so the deep orange (luma ~0.52) takes dark text,
	# which reads better on it than white does.
	var luma := 0.299 * background.r + 0.587 * background.g + 0.114 * background.b
	return LABEL_ON_LIGHT if luma > 0.5 else LABEL_ON_DARK
