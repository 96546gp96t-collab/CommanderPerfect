extends "res://tests/test_case.gd"
## Tests for the PC speaker sounds: reading SOUNDS.CK1, turning a sound into
## audio, the priority rule of the single speaker, and which events make a
## sound. Uses a small hand-made sound file; the real one is checked in
## test_keen1_data.gd.

const Fixtures := preload("res://tests/fixtures.gd")
const FIELD: PackedStringArray = [
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"##########...o......",
	"####################",
]
const START_CELL := Vector2i(2, 4)
const SETTLE_TICKS := 30


func test_sound_file_is_read() -> void:
	var file := SoundFile.parse(
		_sound_file({"KEENJUMPSND": [200, [100, 0, 50]], "GUNCLICK": [5, []]})
	)
	assert_true(file != null, "parsed")
	if file == null:
		return
	assert_equal(file.sounds.size(), 2, "two sounds")
	var jump: SoundFile.Entry = file.sounds["KEENJUMPSND"]
	assert_equal(jump.priority, 200, "priority")
	assert_equal(jump.divisors, PackedInt32Array([100, 0, 50]), "divisors")
	assert_true(file.sounds["GUNCLICK"].divisors.is_empty(), "an empty sound")


func test_sound_file_rejects_other_data() -> void:
	assert_true(SoundFile.parse(PackedByteArray([1, 2, 3])) == null, "too short")
	var data := _sound_file({"KEENJUMPSND": [200, [100]]})
	data.resize(data.size() - 2)
	assert_true(SoundFile.parse(data) == null, "missing end mark")


func test_synth_plays_each_step_for_its_time() -> void:
	var samples := SpeakerSynth.render_samples(PackedInt32Array([1000, 0]))
	var per_step := SpeakerSynth.MIX_RATE / SoundFile.STEPS_PER_SECOND
	assert_equal(
		samples.size(), ceili(2 * per_step) * SpeakerSynth.BYTES_PER_SAMPLE, "two steps long"
	)
	var loudest := 0
	for index in int(per_step):
		loudest = maxi(loudest, absi(samples.decode_s16(index * SpeakerSynth.BYTES_PER_SAMPLE)))
	assert_true(loudest > 1000, "the first step is a tone")
	var last := samples.size() - SpeakerSynth.BYTES_PER_SAMPLE
	assert_true(absi(samples.decode_s16(last)) < 10, "the second step is silent")


func test_synth_leaves_out_inaudible_tones() -> void:
	var samples := SpeakerSynth.render_samples(PackedInt32Array([1]))
	for index in samples.size() / SpeakerSynth.BYTES_PER_SAMPLE:
		assert_equal(samples.decode_s16(index * SpeakerSynth.BYTES_PER_SAMPLE), 0, "silent")


func test_only_equal_or_higher_priority_interrupts() -> void:
	assert_true(SoundPlayer.should_replace(false, 255, 1), "nothing playing")
	assert_true(SoundPlayer.should_replace(true, 100, 100), "same priority")
	assert_true(SoundPlayer.should_replace(true, 100, 200), "higher priority")
	assert_true(not SoundPlayer.should_replace(true, 200, 100), "lower priority waits")


func test_every_sound_has_a_file_name() -> void:
	for id: Sound.Id in Sound.Id.values():
		if id != Sound.Id.NONE:
			assert_true(Sound.FILE_NAMES.has(id), "name for %s" % Sound.Id.find_key(id))


func test_keen_jumps_and_lands_with_sound() -> void:
	var session := _session()
	var sounds := _record(session)
	_run(session, KeenInput.create(0, true), 4)
	_run(session, KeenInput.create(0), 120)
	assert_true(sounds.has(Sound.Id.KEEN_JUMP), "jump")
	assert_true(sounds.has(Sound.Id.KEEN_LAND), "landing")
	assert_true(sounds.find(Sound.Id.KEEN_JUMP) < sounds.find(Sound.Id.KEEN_LAND), "in order")


func test_walking_makes_footsteps_and_a_bump_at_a_wall() -> void:
	var session := _session()
	var sounds := _record(session)
	_run(session, KeenInput.create(1), 60)
	assert_true(sounds.has(Sound.Id.KEEN_WALK), "first foot")
	assert_true(sounds.has(Sound.Id.KEEN_WALK_2), "second foot")
	sounds.clear()
	_run(session, KeenInput.create(-1), 120)
	assert_true(sounds.has(Sound.Id.KEEN_BLOCKED), "walking into the wall")


func test_items_and_the_raygun_make_sounds() -> void:
	var session := _session()
	var sounds := _record(session)
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_true(sounds.has(Sound.Id.GUN_CLICK), "an empty raygun clicks")
	session.inventory.charges = 1
	_run(session, KeenInput.create(0), 30)
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_true(sounds.has(Sound.Id.KEEN_FIRE), "a shot")
	sounds.clear()
	session.keen.position = _pixels(Vector2i(13, 5))
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	assert_true(sounds.has(Sound.Id.GOT_BONUS), "the lollipop")


func test_dying_makes_a_sound() -> void:
	var session := _session()
	var sounds := _record(session)
	session.keen.kill()
	assert_equal(sounds, [Sound.Id.KEEN_DIES] as Array[Sound.Id], "dying")


func test_shooting_a_yorp_makes_it_scream() -> void:
	var session := _session()
	var yorp := Yorp.create(_pixels(Vector2i(7, 5)))
	session.add_actor(yorp)
	yorp.settle(session)
	var sounds := _record(session)
	session.inventory.charges = 1
	_run(session, KeenInput.create(1), 1)
	_run(session, KeenInput.create(1, false, false, true), 1)
	_run(session, KeenInput.create(0), 40)
	assert_true(yorp.is_dead, "the Yorp is hit")
	assert_true(sounds.has(Sound.Id.YORP_SCREAM), "scream")


## A session in [constant FIELD], with Keen standing on the ledge.
func _session() -> LevelSession:
	var session := (
		LevelSession
		. create(
			Fixtures.create_level(FIELD),
			Fixtures.create_properties(),
			Inventory.new(),
			_pixels(START_CELL),
		)
	)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## Top left of [param cell] of the field, in level pixels.
func _pixels(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell + Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)) * EgaGraphics.TILE_SIZE
	)


func _record(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## A sound file with [param sounds]: name -> [priority, divisors].
func _sound_file(sounds: Dictionary) -> PackedByteArray:
	var header_size := SoundFile.HEADER_SIZE + sounds.size() * SoundFile.ENTRY_SIZE
	var data := PackedByteArray()
	data.resize(header_size)
	data.encode_u16(SoundFile.COUNT_OFFSET, sounds.size())
	for index in SoundFile.SIGNATURE.length():
		data[index] = SoundFile.SIGNATURE.unicode_at(index)
	var body := PackedByteArray()
	var index := 0
	for name: String in sounds:
		var at := SoundFile.HEADER_SIZE + index * SoundFile.ENTRY_SIZE
		data.encode_u16(at, header_size + body.size())
		data[at + 2] = sounds[name][0]
		for letter in name.length():
			data[at + 4 + letter] = name.unicode_at(letter)
		for divisor: int in sounds[name][1]:
			body.append_array(_word(divisor))
		body.append_array(_word(SoundFile.END_MARK))
		index += 1
	data.append_array(body)
	return data


func _word(value: int) -> PackedByteArray:
	var bytes := PackedByteArray([0, 0])
	bytes.encode_u16(0, value)
	return bytes
