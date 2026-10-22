class_name GalaxyOplOperator
extends RefCounted
## One of the 18 operators of the OPL2 (YM3812) chip that [GalaxyOpl]
## plays: its register settings, its envelope and its phase, and the
## numbers derived from them that the sample loop needs.
##
## Everything here follows the public YM3812 application manual: the
## frequency (F-number, block and the multiple), the total level in steps
## of 0.75 dB, the key-scale level in dB per octave, the four envelope
## rates with the key-scale rate, the sustain level in steps of 3 dB, and
## the attack and decay times of the manual's table. Attenuation is counted
## in envelope steps of 0.1875 dB (511 steps: silent), as the chip does.

enum Stage { ATTACK, DECAY, SUSTAIN, RELEASE, OFF }

## Attenuation in envelope steps: 0 is full volume, this is silence.
const SILENT := 511.0
## One envelope step is 0.1875 dB; the total level steps are 0.75 dB.
const STEP_DB := 0.1875
const TOTAL_LEVEL_STEPS := 4
## A sustain level step is 3 dB; the highest value (15) means 93 dB.
const SUSTAIN_LEVEL_STEPS := 16
const SUSTAIN_LEVEL_MAX := 15
const SUSTAIN_LEVEL_LAST := 31
## The multiples of the frequency (register 0x20, low four bits), doubled
## so that 0.5 is a whole number (manual: 1/2, 1, 2, ... 10, 10, 12, 12, 15, 15).
const MULTIPLES_TWICE: PackedInt32Array = [
	1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30
]
## The phase counts 2^20 per cycle; the waveform is looked up by its top 10 bits.
const PHASE_BITS := 20
const PHASE_MASK := (1 << PHASE_BITS) - 1
## Key-scale level at block 7, in dB, for the top four bits of the
## F-number (manual: the attenuation grows 3 dB per octave); each lower
## block takes 3 dB off, never below 0.
const KEY_SCALE_DB: PackedFloat32Array = [
	0.0,
	9.0,
	12.0,
	13.875,
	15.0,
	16.125,
	16.875,
	17.625,
	18.0,
	18.75,
	19.125,
	19.5,
	19.875,
	20.25,
	20.625,
	21.0
]
const KEY_SCALE_BLOCK_DB := 3.0
const TOP_BLOCK := 7
## The key-scale level setting (register 0x40, top two bits) as a factor
## of 3 dB per octave: none, 3, 1.5 and 6 dB per octave.
const KEY_SCALE_FACTORS: PackedFloat32Array = [0.0, 1.0, 0.5, 2.0]
## The manual's times at rate 1 (effective rate 4): the attack from
## silence to full volume, and a decay over 96 dB (511 steps). Every rate
## step halves them; the key-scale offset adds quarter steps.
const ATTACK_MS_RATE_1 := 2826.24
const DECAY_MS_RATE_1 := 39280.64
const DECAY_STEPS := 512.0
const MAX_RATE := 15
const MAX_EFFECTIVE_RATE := 63
## The chip's attack takes off an eighth of the attenuation (plus one
## step) per step, so (attenuation + 8) shrinks exponentially.
const ATTACK_OFFSET := 8.0
const MS_PER_SECOND := 1000.0

## Register 0x20: tremolo, vibrato, sustained envelope, key-scale rate, multiple.
var tremolo := false
var vibrato := false
var sustained := false
var key_scale_rate := false
var multiple := 0
## Register 0x40: key-scale level and total level.
var key_scale_level := 0
var total_level := 0
## Registers 0x60 and 0x80: attack, decay, sustain level, release.
var attack_rate := 0
var decay_rate := 0
var sustain_level := 0
var release_rate := 0
## Register 0xE0: the waveform (0-3).
var waveform := 0

var stage := Stage.OFF
var attenuation := SILENT
var phase := 0
## The last two outputs, for the modulator's feedback.
var last_output := 0.0
var previous_output := 0.0

## Derived for the sample loop by [method update].
var phase_step := 0
var base_attenuation := 0.0
var attack_factor := 0.0
var decay_step := 0.0
var release_step := 0.0
var sustain_attenuation := 0.0


## Works out the per-sample numbers for a channel at [param f_number] and
## [param block]; [param note_select] is register 0x08 bit 6.
func update(f_number: int, block: int, note_select: bool, chip_rate: float) -> void:
	phase_step = ((f_number << block) * MULTIPLES_TWICE[multiple]) >> 1
	var key_scale_db := KEY_SCALE_DB[f_number >> 6] - KEY_SCALE_BLOCK_DB * (TOP_BLOCK - block)
	key_scale_db = maxf(0.0, key_scale_db) * KEY_SCALE_FACTORS[key_scale_level]
	base_attenuation = total_level * TOTAL_LEVEL_STEPS + key_scale_db / STEP_DB
	var level := SUSTAIN_LEVEL_LAST if sustain_level == SUSTAIN_LEVEL_MAX else sustain_level
	sustain_attenuation = level * SUSTAIN_LEVEL_STEPS
	var offset := _rate_offset(f_number, block, note_select)
	attack_factor = _attack_factor(attack_rate, offset, chip_rate)
	decay_step = _decay_step(decay_rate, offset, chip_rate)
	release_step = _decay_step(release_rate, offset, chip_rate)


## The key goes down: the envelope attacks from where it is and the
## phase starts again at 0, as the chip does.
func key_on() -> void:
	stage = Stage.ATTACK
	phase = 0


func key_off() -> void:
	if stage != Stage.OFF:
		stage = Stage.RELEASE


## The key-scale rate offset: the block and the top F-number bit (bit 9,
## or bit 8 when note select is set), all four bits with the KSR bit set,
## the top two without it.
func _rate_offset(f_number: int, block: int, note_select: bool) -> int:
	var top_bit := (f_number >> 8) & 1 if note_select else f_number >> 9
	var offset := (block << 1) | top_bit
	return offset if key_scale_rate else offset >> 2


## The time the manual gives for rate [param rate] with key-scale offset
## [param offset], in samples; 0 for rate 0 (never).
static func _rate_samples(base_ms: float, rate: int, offset: int, chip_rate: float) -> float:
	if rate == 0:
		return 0.0
	var effective := mini(rate * 4 + offset, MAX_EFFECTIVE_RATE)
	var whole := effective >> 2
	var quarter := effective & 3
	var ms := base_ms * pow(2.0, 1 - whole) * 4.0 / (4 + quarter)
	return ms * chip_rate / MS_PER_SECOND


## How much of (attenuation + 8) the attack takes away per sample; 1.0 at
## rate 15 (at once), 0.0 at rate 0 (never).
static func _attack_factor(rate: int, offset: int, chip_rate: float) -> float:
	if rate == MAX_RATE:
		return 1.0
	var samples := _rate_samples(ATTACK_MS_RATE_1, rate, offset, chip_rate)
	if samples <= 0.0:
		return 0.0
	return 1.0 - exp(-log((SILENT + ATTACK_OFFSET) / ATTACK_OFFSET) / samples)


## Envelope steps per sample for a decay or release rate; 0 at rate 0.
static func _decay_step(rate: int, offset: int, chip_rate: float) -> float:
	var samples := _rate_samples(DECAY_MS_RATE_1, rate, offset, chip_rate)
	return DECAY_STEPS / samples if samples > 0.0 else 0.0
