class_name GalaxyOpl
extends RefCounted
## Our own OPL2 (Yamaha YM3812) synthesiser, written from the chip's public
## application manual: nine channels of two operators each (a modulator
## and a carrier), four waveforms (sine, half sine, absolute sine and
## quarter "pulse" sine; the last three only after register 0x01 bit 5),
## ADSR envelopes with key-scale rate, F-number and block, the frequency
## multiple, total and key-scale level, the modulator's feedback, FM or
## additive connection, and tremolo and vibrato (depths in register 0xBD).
##
## GDScript is too slow to run this in real time, so the Galaxy sounds and
## songs are rendered once ([GalaxyAdlibSound], [GalaxyMusic]) into audio
## streams that are cached. The chip makes [constant CHIP_RATE] samples a
## second; the streams keep that rate and Godot resamples them to the
## output's rate. The rhythm mode (0xBD bit 5) is not built: no Keen 4
## sound or song uses it (docs/keen4/file-formats.md, "AUDIO.CK4").

const CHIP_RATE := 49716
const CHANNELS := 9
const REGISTER_COUNT := 256
## The register offset of each channel's modulator; its carrier is 3 further.
const MODULATOR_OFFSETS: PackedInt32Array = [0, 1, 2, 8, 9, 10, 16, 17, 18]
const CARRIER_DISTANCE := 3
## Operator registers: 0x20-0x35, 0x40-0x55, 0x60-0x75, 0x80-0x95, 0xE0-0xF5.
const OPERATOR_SLOTS := 0x16
const SLOTS_PER_ROW := 8
const OPERATORS_PER_ROW := 6
const TEST_REGISTER := 0x01
const WAVEFORM_ENABLE := 0x20
const NOTE_SELECT_REGISTER := 0x08
const NOTE_SELECT := 0x40
const DEPTH_REGISTER := 0xBD
const DEEP_TREMOLO := 0x80
const DEEP_VIBRATO := 0x40
const CHARACTER := 0x20
const LEVELS := 0x40
const ATTACK_DECAY := 0x60
const SUSTAIN_RELEASE := 0x80
const F_NUMBER_LOW := 0xA0
const KEY_BLOCK := 0xB0
const FEEDBACK_CONNECTION := 0xC0
const WAVEFORM := 0xE0
const KEY_ON := 0x20
## The waveform is read by the phase's top 10 bits.
const WAVE_SIZE := 1024
const WAVE_MASK := WAVE_SIZE - 1
const WAVE_SHIFT := GalaxyOplOperator.PHASE_BITS - 10
const WAVEFORMS := 4
## An operator's full output (the chip's 13-bit output); added to the
## carrier's phase it shifts the waveform by 4 whole cycles.
const FULL_OUTPUT := 4096.0
## Feedback 1-7 adds (last two outputs) >> (9 - feedback) to the
## modulator's phase: a modulation of pi/16 up to 4 pi (manual).
const FEEDBACK_SHIFT_BASE := 9
## One channel at full volume is this part of 16-bit full scale: the AdLib
## sounds then sound about as loud as the PC speaker's, and the loudest
## song stays below full scale.
const CHANNEL_SHARE := 0.5
## Tremolo: 3.7 Hz, 1 dB or 4.8 dB deep; vibrato: 6.4 Hz, 7 or 14 cents
## (manual).
const TREMOLO_HZ := 3.7
const TREMOLO_DB: PackedFloat32Array = [1.0, 4.8]
const VIBRATO_HZ := 6.4
const VIBRATO_CENTS: PackedFloat32Array = [7.0, 14.0]
const CENTS_PER_OCTAVE := 1200.0
## The attenuation table covers twice the silent level, so a sum of
## envelope, total level, key scaling and tremolo never runs off its end.
const GAIN_SIZE := 1024
const AMPLITUDE_DB := 20.0
const BYTES_PER_SAMPLE := 2
const PCM_FULL_SCALE := 32767.0

var _registers := PackedByteArray()
var _operators: Array[GalaxyOplOperator] = []
var _f_numbers := PackedInt32Array()
var _blocks := PackedInt32Array()
var _keys := PackedByteArray()
var _feedbacks := PackedInt32Array()
var _additive := PackedByteArray()
var _waveforms_enabled := false
var _note_select := false
var _deep_tremolo := false
var _deep_vibrato := false
## Samples made so far: the clock of tremolo and vibrato.
var _sample := 0
## The four waveforms one after another, at full output.
var _waves := PackedFloat32Array()
## Attenuation in envelope steps to a factor of the full output.
var _gains := PackedFloat32Array()


func _init() -> void:
	_registers.resize(REGISTER_COUNT)
	for index in CHANNELS * 2:
		_operators.append(GalaxyOplOperator.new())
	_f_numbers.resize(CHANNELS)
	_blocks.resize(CHANNELS)
	_keys.resize(CHANNELS)
	_feedbacks.resize(CHANNELS)
	_additive.resize(CHANNELS)
	_build_tables()
	for channel in CHANNELS:
		_update_channel(channel)


## Writes [param value] to chip register [param register], as a program
## would through the AdLib's ports.
func write(register: int, value: int) -> void:
	register &= 0xFF
	value &= 0xFF
	_registers[register] = value
	if register == TEST_REGISTER:
		_waveforms_enabled = (value & WAVEFORM_ENABLE) != 0
	elif register == NOTE_SELECT_REGISTER:
		_note_select = (value & NOTE_SELECT) != 0
		for channel in CHANNELS:
			_update_channel(channel)
	elif register == DEPTH_REGISTER:
		_deep_tremolo = (value & DEEP_TREMOLO) != 0
		_deep_vibrato = (value & DEEP_VIBRATO) != 0
	elif register >= CHARACTER and register < F_NUMBER_LOW:
		_write_operator(register, value)
	elif register >= WAVEFORM:
		_write_operator(register, value)
	elif register >= F_NUMBER_LOW and register < F_NUMBER_LOW + CHANNELS:
		var channel := register - F_NUMBER_LOW
		_f_numbers[channel] = (_f_numbers[channel] & 0x300) | value
		_update_channel(channel)
	elif register >= KEY_BLOCK and register < KEY_BLOCK + CHANNELS:
		_write_key_block(register - KEY_BLOCK, value)
	elif register >= FEEDBACK_CONNECTION and register < FEEDBACK_CONNECTION + CHANNELS:
		var channel := register - FEEDBACK_CONNECTION
		_feedbacks[channel] = (value >> 1) & 7
		_additive[channel] = value & 1


## The value last written to [param register].
func register_value(register: int) -> int:
	return _registers[register & 0xFF]


## The next [param count] samples at [constant CHIP_RATE]; 1.0 is 16-bit
## full scale.
func generate(count: int) -> PackedFloat32Array:
	var mix := PackedFloat32Array()
	mix.resize(maxi(count, 0))
	if count <= 0:
		return mix
	for channel in CHANNELS:
		var modulator := _operators[channel * 2]
		var carrier := _operators[channel * 2 + 1]
		if (
			modulator.stage == GalaxyOplOperator.Stage.OFF
			and carrier.stage == GalaxyOplOperator.Stage.OFF
		):
			continue
		GalaxyOplVoice.render(self, channel, mix, count)
	_sample += count
	return mix


## Whether both operators of [param channel] are silent (envelope done).
func is_channel_silent(channel: int) -> bool:
	return (
		_operators[channel * 2].stage == GalaxyOplOperator.Stage.OFF
		and _operators[channel * 2 + 1].stage == GalaxyOplOperator.Stage.OFF
	)


## The modulator (0) or carrier (1) of [param channel]; for the voice
## renderer and tests.
func operator(channel: int, which: int) -> GalaxyOplOperator:
	return _operators[channel * 2 + which]


## The numbers [GalaxyOplVoice] needs besides the operators.
func channel_settings(channel: int) -> Dictionary:
	return {
		"feedback": _feedbacks[channel],
		"additive": _additive[channel] == 1,
		"waves": _waves,
		"gains": _gains,
		"sample": _sample,
		"tremolo_steps": TREMOLO_DB[1 if _deep_tremolo else 0] / GalaxyOplOperator.STEP_DB,
		"vibrato_depth":
		pow(2.0, VIBRATO_CENTS[1 if _deep_vibrato else 0] / CENTS_PER_OCTAVE) - 1.0,
	}


## The frequency in Hz of [param f_number] in [param block] with the
## frequency multiple [param multiple] (manual).
static func note_frequency(f_number: int, block: int, multiple := 1.0) -> float:
	return f_number * CHIP_RATE * pow(2.0, block - GalaxyOplOperator.PHASE_BITS) * multiple


## Samples as 16-bit little-endian audio, clamped to full scale.
static func to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * BYTES_PER_SAMPLE)
	for index in samples.size():
		var value := clampf(samples[index], -1.0, 1.0) * PCM_FULL_SCALE
		bytes.encode_s16(index * BYTES_PER_SAMPLE, roundi(value))
	return bytes


## A stream of 16-bit audio at the chip's rate; with [param loop_begin]
## and [param loop_end] (in samples, both >= 0) it loops between them.
static func make_stream(pcm: PackedByteArray, loop_begin := -1, loop_end := -1) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CHIP_RATE
	stream.stereo = false
	stream.data = pcm
	if loop_begin >= 0 and loop_end > loop_begin:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = loop_begin
		stream.loop_end = loop_end
	return stream


func _write_operator(register: int, value: int) -> void:
	var slot := register & 0x1F
	if slot >= OPERATOR_SLOTS or slot % SLOTS_PER_ROW >= OPERATORS_PER_ROW:
		return
	var in_row := slot % SLOTS_PER_ROW
	var channel := (slot / SLOTS_PER_ROW) * 3 + in_row % 3
	var op := _operators[channel * 2 + (1 if in_row >= CARRIER_DISTANCE else 0)]
	match register & 0xE0:
		CHARACTER:
			op.tremolo = (value & 0x80) != 0
			op.vibrato = (value & 0x40) != 0
			op.sustained = (value & 0x20) != 0
			op.key_scale_rate = (value & 0x10) != 0
			op.multiple = value & 0x0F
		LEVELS:
			op.key_scale_level = value >> 6
			op.total_level = value & 0x3F
		ATTACK_DECAY:
			op.attack_rate = value >> 4
			op.decay_rate = value & 0x0F
		SUSTAIN_RELEASE:
			op.sustain_level = value >> 4
			op.release_rate = value & 0x0F
		WAVEFORM:
			op.waveform = value & 3
	_update_channel(channel)


func _write_key_block(channel: int, value: int) -> void:
	_f_numbers[channel] = (_f_numbers[channel] & 0xFF) | ((value & 3) << 8)
	_blocks[channel] = (value >> 2) & 7
	var key := (value & KEY_ON) != 0
	_update_channel(channel)
	if key and _keys[channel] == 0:
		_operators[channel * 2].key_on()
		_operators[channel * 2 + 1].key_on()
	elif not key and _keys[channel] == 1:
		_operators[channel * 2].key_off()
		_operators[channel * 2 + 1].key_off()
	_keys[channel] = 1 if key else 0


func _update_channel(channel: int) -> void:
	for which in 2:
		_operators[channel * 2 + which].update(
			_f_numbers[channel], _blocks[channel], _note_select, CHIP_RATE
		)


## The waveform an operator uses: sine unless register 0x01 enabled the others.
func effective_waveform(op: GalaxyOplOperator) -> int:
	return op.waveform if _waveforms_enabled else 0


func _build_tables() -> void:
	_waves.resize(WAVE_SIZE * WAVEFORMS)
	var half := WAVE_SIZE / 2
	var quarter := WAVE_SIZE / 4
	for index in WAVE_SIZE:
		var sine := sin(TAU * index / WAVE_SIZE) * FULL_OUTPUT
		_waves[index] = sine
		_waves[WAVE_SIZE + index] = sine if index < half else 0.0
		_waves[WAVE_SIZE * 2 + index] = absf(sine)
		_waves[WAVE_SIZE * 3 + index] = absf(sine) if index % half < quarter else 0.0
	_gains.resize(GAIN_SIZE)
	for index in GAIN_SIZE:
		var silent := index >= int(GalaxyOplOperator.SILENT)
		var gain := pow(10.0, -index * GalaxyOplOperator.STEP_DB / AMPLITUDE_DB)
		_gains[index] = 0.0 if silent else gain
