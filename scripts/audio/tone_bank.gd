class_name ToneBank
extends RefCounted

## Synthesises one plucked tone per MIDI note and keeps them.
##
## Tones are built as AudioStreamWAV rather than pushed through an
## AudioStreamGenerator: generating in real time means running a synth in
## _process every frame, where a hitch becomes an audible glitch. Rendering
## once and handing the engine a finished buffer moves all of that cost off the
## audio path.
##
## Rendering is lazy. Building the whole two octaves up front costs a visible
## freeze at startup for notes most sessions never play; one note takes only a
## few milliseconds, so paying for each as it is first heard is unnoticeable.

const MIX_RATE := 22050
## The fundamental is 34 dB down by this point, so a longer tail is inaudible
## and only costs render time.
const DURATION := 1.5
## Nothing is asked for outside this range - it is exactly what the keyboard shows.
const LOWEST_MIDI := 60   # C4
const HIGHEST_MIDI := 83  # B5

## Partials in the tone. Eight is safe at this mix rate: the highest note is
## just under 988 Hz, so its eighth harmonic stays well under the 11 kHz
## Nyquist limit and never aliases.
const HARMONICS := 8
const BASE_DECAY := 2.6
## How much faster each successive partial dies away. Higher partials fading
## first is what makes a struck string sound bright at the attack and mellow
## a moment later, instead of like a held organ note.
const HARMONIC_DECAY := 0.55
const ATTACK_SECONDS := 0.004
## Every tone is normalised to this peak, so no note is louder than another.
const TARGET_PEAK := 0.5

var _cache := {}


## The tone for a MIDI note, rendering it the first time it is asked for.
func tone_for(midi: int) -> AudioStreamWAV:
	midi = clampi(midi, LOWEST_MIDI, HIGHEST_MIDI)
	if not _cache.has(midi):
		_cache[midi] = _render(midi)
	return _cache[midi]


func _render(midi: int) -> AudioStreamWAV:
	var freq := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var count := int(MIX_RATE * DURATION)

	# Render to floats first so the tone can be normalised before it is
	# quantised - scaling after encoding would just amplify rounding error.
	var samples := PackedFloat32Array()
	samples.resize(count)

	# One harmonic at a time, accumulating into the buffer. Each harmonic's
	# decay is stepped multiplicatively rather than by calling exp() per sample:
	# exp(-d*(t+dt)) is just exp(-d*t) * exp(-d*dt), and that constant can be
	# computed once. Over eight harmonics that removes hundreds of thousands of
	# exp() calls per note, which is most of the render cost.
	for h in range(1, HARMONICS + 1):
		var amplitude := 1.0 / pow(float(h), 1.3)
		var decay := BASE_DECAY * (1.0 + HARMONIC_DECAY * (h - 1))
		var envelope_step := exp(-decay / MIX_RATE)
		var envelope := 1.0
		var phase := 0.0
		var phase_step := TAU * freq * h / MIX_RATE
		for i in count:
			samples[i] += sin(phase) * envelope * amplitude
			envelope *= envelope_step
			phase += phase_step
			# Keep the argument small so sin() stays precise over a long tone.
			if phase > TAU:
				phase -= TAU

	var peak := 0.0
	var attack_frames := maxf(1.0, ATTACK_SECONDS * MIX_RATE)
	for i in count:
		# A few milliseconds of attack ramp. Starting at full amplitude puts a
		# step in the waveform, which is heard as a click.
		samples[i] *= minf(1.0, i / attack_frames)
		peak = maxf(peak, absf(samples[i]))

	var scale := (TARGET_PEAK / peak) if peak > 0.0 else 0.0
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, int(clampf(samples[i] * scale, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
