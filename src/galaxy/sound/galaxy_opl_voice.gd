class_name GalaxyOplVoice
extends RefCounted
## The sample loop of one [GalaxyOpl] channel: the modulator and the
## carrier, each with its envelope and phase, feedback on the modulator,
## and the carrier's phase shifted by the modulator (FM) or both added
## (additive). This is the hot loop of the synthesiser, so it works on
## local copies of the operators' numbers and writes them back at the end.

const ATTACK := GalaxyOplOperator.Stage.ATTACK
const DECAY := GalaxyOplOperator.Stage.DECAY
const SUSTAIN := GalaxyOplOperator.Stage.SUSTAIN
const RELEASE := GalaxyOplOperator.Stage.RELEASE
const OFF := GalaxyOplOperator.Stage.OFF
const SILENT := GalaxyOplOperator.SILENT
const ATTACK_OFFSET := GalaxyOplOperator.ATTACK_OFFSET
const PHASE_MASK := GalaxyOplOperator.PHASE_MASK
const WAVE_SHIFT := GalaxyOpl.WAVE_SHIFT
const WAVE_MASK := GalaxyOpl.WAVE_MASK
const WAVE_SIZE := GalaxyOpl.WAVE_SIZE
const LAST_GAIN := GalaxyOpl.GAIN_SIZE - 1


## Adds [param count] samples of [param channel] of [param chip] to [param mix].
static func render(chip: GalaxyOpl, channel: int, mix: PackedFloat32Array, count: int) -> void:
	var settings := chip.channel_settings(channel)
	var waves: PackedFloat32Array = settings["waves"]
	var gains: PackedFloat32Array = settings["gains"]
	var additive: bool = settings["additive"]
	var feedback: int = settings["feedback"]
	var feedback_factor := 0.0
	if feedback > 0:
		feedback_factor = 1.0 / float(1 << (GalaxyOpl.FEEDBACK_SHIFT_BASE - feedback))
	var scale := GalaxyOpl.CHANNEL_SHARE / GalaxyOpl.FULL_OUTPUT
	var m := chip.operator(channel, 0)
	var c := chip.operator(channel, 1)
	var lfo := _needs_lfo(m) or _needs_lfo(c)
	var tremolo_steps: float = settings["tremolo_steps"]
	var vibrato_depth: float = settings["vibrato_depth"]
	var first_sample: int = settings["sample"]
	var tremolo_rate := GalaxyOpl.TREMOLO_HZ / GalaxyOpl.CHIP_RATE
	var vibrato_rate := GalaxyOpl.VIBRATO_HZ / GalaxyOpl.CHIP_RATE

	var m_stage := m.stage
	var m_env := m.attenuation
	var m_phase := m.phase
	var m_last := m.last_output
	var m_previous := m.previous_output
	var m_step := m.phase_step
	var m_base := m.base_attenuation
	var m_attack := m.attack_factor
	var m_decay := m.decay_step
	var m_release := m.release_step
	var m_sustain := m.sustain_attenuation
	var m_held := m.sustained
	var m_wave := chip.effective_waveform(m) * WAVE_SIZE
	var c_stage := c.stage
	var c_env := c.attenuation
	var c_phase := c.phase
	var c_step := c.phase_step
	var c_base := c.base_attenuation
	var c_attack := c.attack_factor
	var c_decay := c.decay_step
	var c_release := c.release_step
	var c_sustain := c.sustain_attenuation
	var c_held := c.sustained
	var c_wave := chip.effective_waveform(c) * WAVE_SIZE

	for index in count:
		# The modulator's envelope.
		if m_stage == ATTACK:
			m_env -= (m_env + ATTACK_OFFSET) * m_attack
			if m_env <= 0.0:
				m_env = 0.0
				m_stage = DECAY
		elif m_stage == DECAY:
			m_env += m_decay
			if m_env >= m_sustain:
				m_env = m_sustain
				m_stage = SUSTAIN if m_held else RELEASE
		elif m_stage == RELEASE:
			m_env += m_release
			if m_env >= SILENT:
				m_env = SILENT
				m_stage = OFF
		# The carrier's envelope.
		if c_stage == ATTACK:
			c_env -= (c_env + ATTACK_OFFSET) * c_attack
			if c_env <= 0.0:
				c_env = 0.0
				c_stage = DECAY
		elif c_stage == DECAY:
			c_env += c_decay
			if c_env >= c_sustain:
				c_env = c_sustain
				c_stage = SUSTAIN if c_held else RELEASE
		elif c_stage == RELEASE:
			c_env += c_release
			if c_env >= SILENT:
				c_env = SILENT
				c_stage = OFF

		var m_attenuation := m_env + m_base
		var c_attenuation := c_env + c_base
		if lfo:
			var t := float(first_sample + index)
			var tremolo := (1.0 - absf(fmod(t * tremolo_rate, 1.0) * 2.0 - 1.0)) * tremolo_steps
			var vibrato := (1.0 - absf(fmod(t * vibrato_rate, 1.0) * 4.0 - 2.0)) * vibrato_depth
			if m.tremolo:
				m_attenuation += tremolo
			if c.tremolo:
				c_attenuation += tremolo
			m_phase += int(m_step * vibrato) if m.vibrato else 0
			c_phase += int(c_step * vibrato) if c.vibrato else 0
		m_phase = (m_phase + m_step) & PHASE_MASK
		c_phase = (c_phase + c_step) & PHASE_MASK

		var shift := 0
		if feedback > 0:
			shift = int((m_last + m_previous) * feedback_factor)
		var m_out: float = (
			waves[m_wave + (((m_phase >> WAVE_SHIFT) + shift) & WAVE_MASK)]
			* gains[mini(int(m_attenuation), LAST_GAIN)]
		)
		m_previous = m_last
		m_last = m_out
		var c_index := c_phase >> WAVE_SHIFT
		if not additive:
			c_index += int(m_out)
		var out: float = (
			waves[c_wave + (c_index & WAVE_MASK)] * gains[mini(int(c_attenuation), LAST_GAIN)]
		)
		if additive:
			out += m_out
		mix[index] += out * scale

	m.stage = m_stage
	m.attenuation = m_env
	m.phase = m_phase
	m.last_output = m_last
	m.previous_output = m_previous
	c.stage = c_stage
	c.attenuation = c_env
	c.phase = c_phase


static func _needs_lfo(op: GalaxyOplOperator) -> bool:
	return op.tremolo or op.vibrato
