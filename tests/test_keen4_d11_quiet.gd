extends "res://tests/test_case.gd"
## Tests the "QUIET ADLIB/SOUNDBLASTER" choice of the Sound card (milestone
## D11): the carrier's level byte as the original writes it (Omni id_sd.c,
## all in bytes; facts only), how much quieter each Keen 4 sound gets, and
## that this is what v1.0 does: in js-dos the status window's sounds were
## 35.6 dB (status_down, level byte 0x80) and 12.7 dB (status_up, 0x00)
## quieter, against 36.75 and 12.75 dB here. Also Keen 4's own setting is
## stored, and the player plays AdLib sounds (not PC ones, not the music)
## that much quieter. The real files are needed for the per-sound part, a
## running scene tree for the playing part; each is skipped without.

const SETTINGS_PATH := "user://test_keen4_d11_quiet/keen4.cfg"
## Level byte → quiet level byte (0x3F − (x >> 1) − (x >> 2), x = 0x3F − L,
## bytes).
const QUIET_LEVELS := {
	0x00: 0x11,
	0x03: 0x12,
	0x0D: 0x1A,
	0x0E: 0x1B,
	0x3F: 0x3F,
	0x80: 0xB1,
	0xC0: 0xE1,
}
const STATUS_DOWN := 34
const STATUS_UP := 35
## Heard in js-dos (v1.0): the peak loudness ratio, normal / quiet, in dB.
const HEARD_STATUS_DOWN_DB := 35.6
const HEARD_STATUS_UP_DB := 12.7
const HEARD_TOLERANCE_DB := 1.5
const SOUND_COUNT := 52
## The AdLib sounds follow the 52 PC sounds (files, 1.0).
const FIRST_ADLIB_CHUNK := 52
const DECIBEL_STEP := 0.75
const MAX_ATTENUATION_DB := 47.25

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files != null:
		_data = Keen4Episode.load_data(files)


func run_all() -> void:
	super.run_all()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH.get_base_dir()))


func test_the_quiet_level_byte() -> void:
	for level: int in QUIET_LEVELS:
		assert_equal(
			GalaxyAdlibSound.quiet_level(level), QUIET_LEVELS[level], "level 0x%02X" % level
		)


func test_the_scaling_bits_stay() -> void:
	# The top two bits (key scaling) come through the byte sums unchanged
	# for every level Keen 4 uses with them (0x80, 0xC0).
	for level in [0x80, 0xC0]:
		assert_equal(GalaxyAdlibSound.quiet_level(level) & 0xC0, level & 0xC0, "0x%02X" % level)


func test_quiet_is_never_louder() -> void:
	for level in range(0, 0x40):
		var quiet := GalaxyAdlibSound.quiet_level(level)
		assert_true(quiet >= level, "level %d: %d is not louder" % [level, quiet])


func test_each_keen_4_sound_gets_quieter() -> void:
	if _data == null:
		return
	for number in SOUND_COUNT:
		var sound := _adlib(number)
		if sound == null:
			continue
		var decibels := sound.quiet_decibels()
		assert_true(
			decibels >= 0.0 and decibels <= MAX_ATTENUATION_DB,
			"sound %d: %.2f dB within the chip's range" % [number, decibels]
		)
		assert_true(
			is_equal_approx(roundf(decibels / DECIBEL_STEP) * DECIBEL_STEP, decibels),
			"sound %d: whole 0.75 dB steps" % number
		)


func test_as_heard_in_the_original() -> void:
	if _data == null:
		return
	var down := _adlib(STATUS_DOWN).quiet_decibels()
	var up := _adlib(STATUS_UP).quiet_decibels()
	assert_equal(down, 36.75, "status_down: 49 steps")
	assert_equal(up, 12.75, "status_up: 17 steps")
	assert_true(absf(down - HEARD_STATUS_DOWN_DB) < HEARD_TOLERANCE_DB, "status_down as heard")
	assert_true(absf(up - HEARD_STATUS_UP_DB) < HEARD_TOLERANCE_DB, "status_up as heard")


func test_keen_4_keeps_the_setting() -> void:
	var settings := Keen4Settings.new()
	settings.path = SETTINGS_PATH
	assert_true(not settings.quiet_adlib, "off by default (Omni)")
	settings.quiet_adlib = true
	assert_true(settings.save(), "saved")
	assert_true(Keen4Settings.load_from(SETTINGS_PATH).quiet_adlib, "read back")
	settings.quiet_adlib = false
	settings.save()
	assert_true(not Keen4Settings.load_from(SETTINGS_PATH).quiet_adlib, "and off again")


func test_the_player_plays_adlib_sounds_quieter() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if _data == null or tree == null or not tree.root.is_inside_tree():
		return
	var audio := Keen4Audio.new()
	tree.root.add_child(audio)
	var cache := GalaxySoundCache.new("user://keen4/cache")
	var library := Keen4Sounds.library(_data.audio, cache)
	audio.use_library(library, Keen4Sounds.NUMBERS)
	library.start()
	library.wait()
	var player := audio._sound_player
	audio.set_mode(GalaxySoundPlayer.Mode.ADLIB)
	audio.quiet_adlib = true
	audio.play_number(STATUS_DOWN)
	assert_equal(player.volume_db, -36.75, "status_down quieter")
	audio.stop_sound()
	audio.play_number(STATUS_UP)
	assert_equal(player.volume_db, -12.75, "status_up quieter")
	audio.stop_sound()
	audio.quiet_adlib = false
	audio.play_number(STATUS_UP)
	assert_equal(player.volume_db, 0.0, "AdLib: full")
	audio.stop_sound()
	audio.quiet_adlib = true
	audio.set_mode(GalaxySoundPlayer.Mode.PC)
	audio.play_number(STATUS_UP)
	assert_equal(player.volume_db, 0.0, "the PC speaker is not made quieter")
	assert_equal(audio._music_player.volume_db, 0.0, "nor the music")
	audio.stop_sound()
	tree.root.remove_child(audio)
	audio.free()


func _adlib(number: int) -> GalaxyAdlibSound:
	return GalaxyAdlibSound.parse(_data.audio.chunk(FIRST_ADLIB_CHUNK + number))
