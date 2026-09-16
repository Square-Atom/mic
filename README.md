# M.I.C. — Music Interactive Cheatsheet

Pick a key on the circle of fifths and see every chord it contains: how each one
is spelled, which piano keys to press, and what it sounds like.

For people learning to write music who know roughly what they want to hear, but
not yet which chords will give it to them.

## What it does

- **Circle of fifths** — click a wedge to change key. Outer ring for majors,
  inner ring for their relative minors, and all seven modes from Ionian to
  Locrian, each with its formula and a line on how it sounds.
- **The seven diatonic chords** as a table: roman numeral, chord symbol, spelled
  notes, the degree's name, and a keyboard with exactly the right keys lit.
  Toggle sevenths on to extend all seven at once.
- **One colour language** — amber is the tonic, green the subdominant, pink the
  dominant, on the circle and on the keyboards alike, so a chord looks the same
  wherever it appears.
- **Everything is audible.** Play a chord spread out or struck all at once, play
  the scale, or press single keys. The tones are synthesised at runtime, so the
  project carries no audio files.
- **Chord loops** — build a progression, drag the chords to reorder them, pick a
  tempo and an ostinato, and play it round. Slots hold *degrees* rather than
  chords, so changing key transposes the whole progression with it.
- **MIDI in** — a note held down on a controller lights up in every chord that
  contains it, which is a quick way to ask what you can play over what.

## Running it

Open the project in Godot 4.7 and press <kbd>F5</kbd>. It also exports to the
web.

## Credits

Created by Hau Tran at [www.pixelmancer.studio](https://www.pixelmancer.studio),
with advising from Dang Le at 23:59 Studio.

Feedback → contact@pixelmancer.studio
