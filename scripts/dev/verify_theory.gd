# Headless check of the theory layer - not part of the running app.
# Run: Godot_v472.exe --headless --path <project> --script res://scripts/dev/verify_theory.gd

extends SceneTree

func _initialize() -> void:
	var failures := 0
	print("=== Circle positions, signatures, relatives ===")
	for slot in 12:
		var maj := MusicTheory.key_at(slot, KeyDef.Mode.MAJOR)
		var minr := MusicTheory.key_at(slot, KeyDef.Mode.MINOR)
		print("%2d  %-4s %-10s  rel %-5s  scale: %s" % [
			slot, maj.short_name(), MusicTheory.signature_short(slot),
			minr.short_name(), MusicTheory.scale_text(maj)])
		# A relative minor must contain exactly the same pitch classes as its major.
		var a := _pcs(MusicTheory.scale_notes(maj))
		var b := _pcs(MusicTheory.scale_notes(minr))
		a.sort(); b.sort()
		if a != b:
			print("   FAIL: relative minor note set differs: %s vs %s" % [a, b])
			failures += 1
		# Every key's scale must use each letter name exactly once.
		var letters := {}
		for n in MusicTheory.scale_notes(maj):
			letters[n.letter] = true
		if letters.size() != 7:
			print("   FAIL: duplicate letter names in scale")
			failures += 1

	print("\n=== Diatonic triads ===")
	for probe in [[0, KeyDef.Mode.MAJOR], [11, KeyDef.Mode.MAJOR], [0, KeyDef.Mode.MINOR], [6, KeyDef.Mode.MAJOR], [1, KeyDef.Mode.MAJOR]]:
		var key := MusicTheory.key_at(probe[0], probe[1])
		var line := PackedStringArray()
		for c in MusicTheory.diatonic_chords(key, false):
			line.append("%s=%s" % [c.roman_numeral(), c.symbol()])
		print("%-10s %s" % [key.display_name(), " ".join(line)])

	print("\n=== Diatonic sevenths ===")
	for probe in [[0, KeyDef.Mode.MAJOR], [1, KeyDef.Mode.MAJOR], [0, KeyDef.Mode.MINOR]]:
		var key := MusicTheory.key_at(probe[0], probe[1])
		var line := PackedStringArray()
		for c in MusicTheory.diatonic_chords(key, true):
			line.append("%s=%s" % [c.roman_numeral(), c.symbol()])
		print("%-10s %s" % [key.display_name(), " ".join(line)])

	print("\n=== Assertions ===")
	failures += _expect("C major triads", _syms(0, KeyDef.Mode.MAJOR, false), "C Dm Em F G Am B\u00b0")
	failures += _expect("F major triads", _syms(11, KeyDef.Mode.MAJOR, false), "F Gm Am B\u266d C Dm E\u00b0")
	failures += _expect("A minor triads", _syms(0, KeyDef.Mode.MINOR, false), "Am B\u00b0 C Dm Em F G")
	failures += _expect("G major sevenths", _syms(1, KeyDef.Mode.MAJOR, true), "Gmaj7 Am7 Bm7 Cmaj7 D7 Em7 F\u266f\u00f87")
	failures += _expect("F# major scale", MusicTheory.scale_text(MusicTheory.key_at(6, KeyDef.Mode.MAJOR)), "F\u266f   G\u266f   A\u266f   B   C\u266f   D\u266f   E\u266f")
	failures += _expect("D# minor scale", MusicTheory.scale_text(MusicTheory.key_at(6, KeyDef.Mode.MINOR)), "D\u266f   E\u266f   F\u266f   G\u266f   A\u266f   B   C\u266f")
	failures += _expect("Db major scale", MusicTheory.scale_text(MusicTheory.key_at(7, KeyDef.Mode.MAJOR)), "D\u266d   E\u266d   F   G\u266d   A\u266d   B\u266d   C")
	failures += _expect("C major numerals", _romans(0, KeyDef.Mode.MAJOR, false), "I ii iii IV V vi vii\u00b0")
	failures += _expect("A minor numerals", _romans(0, KeyDef.Mode.MINOR, false), "i ii\u00b0 III iv v VI VII")
	failures += _expect("C major V pitch classes", str(MusicTheory.diatonic_chords(MusicTheory.key_at(0, KeyDef.Mode.MAJOR), false)[4].pitch_classes()), "[7, 11, 2]")


	print("\n=== Circle direction vs. chord list ===")
	# One step clockwise round the circle must be the V, one step anticlockwise
	# the IV. If the circle ever disagrees with the chord list, one is wrong.
	for slot in 12:
		for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
			var key := MusicTheory.key_at(slot, mode)
			var chords := MusicTheory.diatonic_chords(key, false)
			var dominant := MusicTheory.key_at(slot + 1, mode)
			var subdominant := MusicTheory.key_at(slot - 1, mode)
			if chords[4].root().pitch_class() != dominant.tonic.pitch_class():
				print("  FAIL %s: V is %s but clockwise neighbour is %s" % [
					key.display_name(), chords[4].symbol(), dominant.short_name()])
				failures += 1
			if chords[3].root().pitch_class() != subdominant.tonic.pitch_class():
				print("  FAIL %s: IV is %s but anticlockwise neighbour is %s" % [
					key.display_name(), chords[3].symbol(), subdominant.short_name()])
				failures += 1
	print("  ok   V/IV match the circle neighbours for all 24 keys")

	print("\n=== Alternative spellings ===")
	# Each dual-name position must sound identical either way, while spelling
	# and key signature differ. That equivalence is the whole point of them.
	for slot in [5, 6, 7]:
		for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
			var primary := MusicTheory.key_at(slot, mode, false)
			var alternative := MusicTheory.key_at(slot, mode, true)
			var a := _pcs(MusicTheory.scale_notes(primary))
			var b := _pcs(MusicTheory.scale_notes(alternative))
			a.sort()
			b.sort()
			if a != b:
				print("  FAIL %s vs %s sound different" % [
					primary.display_name(), alternative.display_name()])
				failures += 1
			if MusicTheory.signature_of(primary) == MusicTheory.signature_of(alternative):
				print("  FAIL %s and %s report the same signature" % [
					primary.display_name(), alternative.display_name()])
				failures += 1
			print("  %-10s %-14s   %-10s %s" % [
				primary.display_name(), MusicTheory.signature_text(primary),
				alternative.display_name(), MusicTheory.signature_text(alternative)])

	failures += _expect("C# major scale",
			MusicTheory.scale_text(MusicTheory.key_at(7, KeyDef.Mode.MAJOR, true)),
			"C\u266f   D\u266f   E\u266f   F\u266f   G\u266f   A\u266f   B\u266f")
	failures += _expect("Cb major scale",
			MusicTheory.scale_text(MusicTheory.key_at(5, KeyDef.Mode.MAJOR, true)),
			"C\u266d   D\u266d   E\u266d   F\u266d   G\u266d   A\u266d   B\u266d")
	failures += _expect("Gb major scale",
			MusicTheory.scale_text(MusicTheory.key_at(6, KeyDef.Mode.MAJOR, true)),
			"G\u266d   A\u266d   B\u266d   C\u266d   D\u266d   E\u266d   F")
	failures += _expect("A# minor scale",
			MusicTheory.scale_text(MusicTheory.key_at(7, KeyDef.Mode.MINOR, true)),
			"A\u266f   B\u266f   C\u266f   D\u266f   E\u266f   F\u266f   G\u266f")
	failures += _expect("C# major chords",
			_alt_syms(7, KeyDef.Mode.MAJOR), "C\u266f D\u266fm E\u266fm F\u266f G\u266f A\u266fm B\u266f\u00b0")
	failures += _expect("Db major chords",
			_syms(7, KeyDef.Mode.MAJOR, false), "D\u266d E\u266dm Fm G\u266d A\u266d B\u266dm C\u00b0")
	failures += _expect("a plain key has no alt", str(MusicTheory.has_alt_spelling(0)), "false")
	failures += _expect("position 7 has an alt", str(MusicTheory.has_alt_spelling(7)), "true")

	print("\n=== Chord function markers ===")
	# Exactly three chords per key anchor it, and they must be degrees 1, 4 and
	# 5 in every key and both modes - that is what the row markers claim.
	for slot in 12:
		for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
			for use_alt in [false, true]:
				if use_alt and not MusicTheory.has_alt_spelling(slot):
					continue
				var key := MusicTheory.key_at(slot, mode, use_alt)
				var marked := {}
				for chord in MusicTheory.diatonic_chords(key, false):
					var fn := MusicTheory.chord_function(key, chord)
					if fn != MusicTheory.Function.NONE:
						marked[fn] = chord.degree
				if marked.size() != 3:
					print("  FAIL %s marks %d chords, expected 3" % [key.display_name(), marked.size()])
					failures += 1
					continue
				if marked[MusicTheory.Function.TONIC] != 0 \
						or marked[MusicTheory.Function.SUBDOMINANT] != 3 \
						or marked[MusicTheory.Function.DOMINANT] != 4:
					print("  FAIL %s marks the wrong degrees: %s" % [key.display_name(), marked])
					failures += 1
	print("  ok   tonic/subdominant/dominant land on degrees 1, 4, 5 in all 30 keys")

	print("\n=== Functional families ===")
	for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
		var key := MusicTheory.key_at(0, mode)
		var tags := PackedStringArray()
		for chord in MusicTheory.diatonic_chords(key, false):
			var fam: int = MusicTheory.chord_family(chord)
			var tag: String = ["T", "S", "D"][fam]
			tags.append("%s=%s" % [chord.roman_numeral(), tag])
		print("  %-10s %s" % [key.display_name(), " ".join(tags)])

	# The grouping only means anything because family members share two of their
	# three notes - that is what lets one substitute for another.
	for slot in 12:
		for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
			var probe := MusicTheory.key_at(slot, mode)
			var chords := MusicTheory.diatonic_chords(probe, false)
			for pair in [[0, 2], [0, 5], [3, 1], [4, 6]]:
				var shared := 0
				for pc in _pcs(chords[pair[0]].notes):
					if _pcs(chords[pair[1]].notes).has(pc):
						shared += 1
				if shared != 2:
					print("  FAIL %s: %s and %s share %d notes, expected 2" % [
						probe.display_name(), chords[pair[0]].symbol(),
						chords[pair[1]].symbol(), shared])
					failures += 1
	print("  ok   family members share exactly two notes, all 24 keys")

	print("\n=== Scale degree names ===")
	for mode in [KeyDef.Mode.MAJOR, KeyDef.Mode.MINOR]:
		var key := MusicTheory.key_at(0, mode)
		var names := PackedStringArray()
		for chord in MusicTheory.diatonic_chords(key, false):
			names.append(MusicTheory.degree_name(key, chord))
		print("  %-10s %s" % [key.display_name(), " / ".join(names)])

	# The seventh is the only degree whose name is not fixed: it leads only when
	# it sits a semitone under the tonic, which natural minor does not do.
	for slot in 12:
		var major := MusicTheory.key_at(slot, KeyDef.Mode.MAJOR)
		var minor := MusicTheory.key_at(slot, KeyDef.Mode.MINOR)
		var major_seventh := MusicTheory.diatonic_chords(major, false)[6]
		var minor_seventh := MusicTheory.diatonic_chords(minor, false)[6]
		if MusicTheory.degree_name(major, major_seventh) != "Leading Tone":
			print("  FAIL %s seventh is not a leading tone" % major.display_name())
			failures += 1
		if MusicTheory.degree_name(minor, minor_seventh) != "Subtonic":
			print("  FAIL %s seventh is not a subtonic" % minor.display_name())
			failures += 1
	print("  ok   seventh leads in every major key, is subtonic in every minor")

	print("\n=== Modes ===")
	# Every mode on C must keep C as its tonic while its signature moves, and
	# must land in the parent major the theory says it should.
	var expected_parent := ["C", "B\u266d", "A\u266d", "G", "F", "E\u266d", "D\u266d"]
	var home := MusicTheory.key_at(0, KeyDef.Mode.MAJOR)
	for mode in MusicTheory.MODE_NAMES.size():
		var key := MusicTheory.with_mode(home, mode)
		var parent := MusicTheory.parent_major(key).tonic.display_name()
		if key.circle_position != home.circle_position:
			print("  FAIL %s moved off C's wedge" % key.display_name())
			failures += 1
		if key.tonic.pitch_class() != 0:
			print("  FAIL %s moved off C" % key.display_name())
			failures += 1
		if parent != expected_parent[mode]:
			print("  FAIL %s parent is %s, expected %s" % [
				key.display_name(), parent, expected_parent[mode]])
			failures += 1
		print("  %-14s %-14s parent %-3s  %s" % [
			key.display_name(), MusicTheory.signature_text(key), parent,
			MusicTheory.scale_text(key)])

	failures += _expect("C Dorian chords", _mode_syms(KeyDef.Mode.DORIAN),
			"Cm Dm E\u266d F Gm A\u00b0 B\u266d")
	failures += _expect("C Lydian chords", _mode_syms(KeyDef.Mode.LYDIAN),
			"C D Em F\u266f\u00b0 G Am Bm")
	failures += _expect("C Mixolydian chords", _mode_syms(KeyDef.Mode.MIXOLYDIAN),
			"C Dm E\u00b0 F Gm Am B\u266d")
	# Mixolydian's seventh sits a whole tone below the tonic, so it does not lead.
	var mixo := MusicTheory.with_mode(home, KeyDef.Mode.MIXOLYDIAN)
	failures += _expect("Mixolydian seventh is a subtonic",
			MusicTheory.degree_name(mixo, MusicTheory.diatonic_chords(mixo, false)[6]), "Subtonic")

	# Subdominant and Dominant name perfect intervals. Lydian raises the fourth
	# and Locrian flattens the fifth, so those two cells must come back empty
	# while every other mode still names both.
	for probe_mode in KeyDef.Mode.values():
		var probe := MusicTheory.with_mode(home, probe_mode)
		var triads := MusicTheory.diatonic_chords(probe, false)
		var want_fourth := "" if probe_mode == KeyDef.Mode.LYDIAN else "Subdominant"
		var want_fifth := "" if probe_mode == KeyDef.Mode.LOCRIAN else "Dominant"
		failures += _expect("%s fourth" % probe.display_name(),
				MusicTheory.degree_name(probe, triads[3]), want_fourth)
		failures += _expect("%s fifth" % probe.display_name(),
				MusicTheory.degree_name(probe, triads[4]), want_fifth)
		# The circle marks its IV and V wedges from this same predicate, so a
		# name and a wedge can never disagree about whether the function is there.
		failures += _expect("%s marks a subdominant wedge" % probe.display_name(),
				str(MusicTheory.has_function_degree(probe_mode, 3)), str(want_fourth != ""))
		failures += _expect("%s marks a dominant wedge" % probe.display_name(),
				str(MusicTheory.has_function_degree(probe_mode, 4)), str(want_fifth != ""))

	# The formula is derived from the interval table, so it is worth pinning to
	# the textbook strings: if the two ever disagree, the table is wrong.
	var expected_formula := [
		"1 2 3 4 5 6 7",
		"1 2 \u266d3 4 5 6 \u266d7",
		"1 \u266d2 \u266d3 4 5 \u266d6 \u266d7",
		"1 2 3 \u266f4 5 6 7",
		"1 2 3 4 5 6 \u266d7",
		"1 2 \u266d3 4 5 \u266d6 \u266d7",
		"1 \u266d2 \u266d3 4 \u266d5 \u266d6 \u266d7",
	]
	for mode in MusicTheory.MODE_NAMES.size():
		failures += _expect(
			"%s formula" % MusicTheory.MODE_CLASSICAL_NAMES[mode],
			MusicTheory.mode_formula(mode), expected_formula[mode])
	print("\n=== Seventh handling ===")
	var v7 := MusicTheory.diatonic_chords(MusicTheory.key_at(0, KeyDef.Mode.MAJOR), true)[4]
	failures += _expect("C major V7 symbol", v7.symbol(), "G7")
	failures += _expect("C major V7 added note is F", str(v7.seventh_pitch_class()), "5")
	var triad := MusicTheory.diatonic_chords(MusicTheory.key_at(0, KeyDef.Mode.MAJOR), false)[0]
	failures += _expect("a triad reports no seventh", str(triad.seventh_pitch_class()), "-1")
	print("\n%s (%d failure(s))" % ["ALL CHECKS PASSED" if failures == 0 else "CHECKS FAILED", failures])
	quit(0 if failures == 0 else 1)


func _pcs(notes: Array[Note]) -> Array:
	var out := []
	for n in notes:
		out.append(n.pitch_class())
	return out


func _syms(slot: int, mode: int, sevenths: bool) -> String:
	var parts := PackedStringArray()
	for c in MusicTheory.diatonic_chords(MusicTheory.key_at(slot, mode), sevenths):
		parts.append(c.symbol())
	return " ".join(parts)


func _romans(slot: int, mode: int, sevenths: bool) -> String:
	var parts := PackedStringArray()
	for c in MusicTheory.diatonic_chords(MusicTheory.key_at(slot, mode), sevenths):
		parts.append(c.roman_numeral())
	return " ".join(parts)


func _expect(label: String, got: String, want: String) -> int:
	if got == want:
		print("  ok   %s -> %s" % [label, got])
		return 0
	print("  FAIL %s\n         got:  %s\n         want: %s" % [label, got, want])
	return 1


func _alt_syms(slot: int, mode: int) -> String:
	var parts := PackedStringArray()
	for c in MusicTheory.diatonic_chords(MusicTheory.key_at(slot, mode, true), false):
		parts.append(c.symbol())
	return " ".join(parts)


## Chord symbols for a mode built on the same tonic as C major.
func _mode_syms(mode: int) -> String:
	var key := MusicTheory.with_mode(MusicTheory.key_at(0, KeyDef.Mode.MAJOR), mode)
	var parts := PackedStringArray()
	for c in MusicTheory.diatonic_chords(key, false):
		parts.append(c.symbol())
	return " ".join(parts)
