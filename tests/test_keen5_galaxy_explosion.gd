extends "res://tests/test_case.gd"
## Checks Keen 5's game over, the exploding galaxy ([Keen5GalaxyExplosion],
## milestone E7): the stages and their tics, the palette fades
## ([GalaxyEgaFade]), entries 7 and 8 flashing by the table's two rows,
## the 4000 stars moving and stopping at the edges, a key skipping to
## GAMEOVER. Hand-made pictures and stars; one test reads the player's
## files when they are there. All numbers were matched with the original's
## recorded frames (research.md, "Watched in E7").

const SIZE := Vector2i(320, 200)
const STAR_COUNT := 4000
const STAR_UNITS := 0x80
## Fades 4 + 4 steps of 6 tics, 18 flashes of 10, 60 star frames of 4,
## GAMEOVER 24 seconds.
const TOTAL_TICS := 24 + 24 + 180 + 240 + 1680
const LIGHT_GREY := 7
const DARK_GREY := 8


func test_the_stages_take_the_originals_tics() -> void:
	var scene := _scene(_stars([]))
	var stages: Array[int] = []
	var tics := 0
	while not scene.is_done() and tics < TOTAL_TICS * 2:
		if stages.is_empty() or stages[-1] != scene.stage:
			stages.append(scene.stage)
		scene.advance(1)
		tics += 1
	assert_equal(tics, TOTAL_TICS, "2148 tics without a key")
	assert_equal(stages.size(), Keen5GalaxyExplosion.Stage.DONE, "every stage in turn")


func test_the_fades_use_the_egas_palettes() -> void:
	var scene := _scene(_stars([]))
	var levels := PackedInt32Array()
	for step in 8:
		levels.append(scene.fade_level())
		scene.advance(Keen5GalaxyExplosion.FADE_STEP_TICS)
	assert_equal(levels, PackedInt32Array([3, 2, 1, 0, 0, 1, 2, 3]), "out, then the galaxy in")
	assert_true(scene.screen() != null, "the galaxy")
	assert_equal(GalaxyEgaFade.faded(15, 1), EgaPalette.color(LIGHT_GREY), "white dims to grey")
	assert_equal(GalaxyEgaFade.faded(DARK_GREY, 1), Color.BLACK, "dark colours are black")
	assert_equal(GalaxyEgaFade.faded(DARK_GREY, 2), EgaPalette.color(DARK_GREY), "then back")
	assert_equal(GalaxyEgaFade.faded(LIGHT_GREY, 2), Color.BLACK, "light grey is dark")


func test_entries_7_and_8_flash_by_their_rows() -> void:
	var scene := _scene(_stars([]))
	scene.advance(Keen5GalaxyExplosion.FADE_STEP_TICS * 8)
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.FLASH, "flashing")
	var seen: Array[Array] = []
	for step in Keen5GalaxyExplosion.FLASH_STEPS:
		var image := scene.screen()
		seen.append([image.get_pixel(0, 0) != Color.BLACK, image.get_pixel(1, 0) != Color.BLACK])
		scene.advance(Keen5GalaxyExplosion.FLASH_STEP_TICS)
	# Seen in the original: (7, 8) shown, step by step.
	var expected: Array[Array] = [
		[true, false],
		[true, false],
		[true, true],
		[true, true],
		[true, true],
		[true, false],
		[true, false],
		[false, false],
		[false, true],
		[true, true],
		[true, true],
		[true, false],
		[false, false],
		[false, false],
		[false, false],
		[false, false],
		[false, false],
		[false, false],
	]
	assert_equal(seen, expected, "entry 7 by the second row, 8 by the first")
	assert_equal(Keen5GalaxyExplosion.shown_color(0xF), EgaPalette.color(LIGHT_GREY), "0x0F")
	assert_equal(Keen5GalaxyExplosion.shown_color(0x8), Color.BLACK, "0x08")
	assert_equal(Keen5GalaxyExplosion.shown_color(0x1F), Color.WHITE, "0x1F")


func test_stars_move_and_stop_at_the_edges() -> void:
	# x, dx, y, dy (pixels × 128): a star moving right, one leaving at the
	# left (it wraps round below 0), one landing on the right edge.
	var stars := _stars([[10, 1, 20, 2], [1, -2, 50, 0], [318, 1, 70, 0]])
	var scene := _scene(stars)
	scene.advance(Keen5GalaxyExplosion.FADE_STEP_TICS * 8)
	scene.advance(Keen5GalaxyExplosion.FLASH_STEPS * Keen5GalaxyExplosion.FLASH_STEP_TICS)
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.STARS, "the stars")
	var first := scene.screen()
	assert_equal(first.get_pixel(11, 22), Color.WHITE, "one step on at once")
	scene.advance(Keen5GalaxyExplosion.STAR_FRAME_TICS)
	var second := scene.screen()
	assert_equal(second.get_pixel(12, 24), Color.WHITE, "a step a frame")
	assert_equal(second.get_pixel(0, 71), Color.WHITE, "on the right edge: the next row's left")
	assert_true(second.get_pixel(1, 50) == Color.BLACK, "the one off the left is gone")


func test_a_key_skips_to_game_over_and_ends_it() -> void:
	var scene := _scene(_stars([]))
	assert_true(not scene.press(), "not during the fades")
	scene.advance(Keen5GalaxyExplosion.FADE_STEP_TICS * 8 + 1)
	assert_true(scene.press(), "a key while it flashes")
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.GAME_OVER, "GAMEOVER")
	assert_equal(
		scene.screen().get_pixelv(Keen5GalaxyExplosion.GAME_OVER_AT), Color.RED, "at 32, 80"
	)
	assert_true(scene.press() and scene.is_done(), "a key ends it")


func test_the_players_galaxy_has_4000_stars() -> void:
	var files := Keen5Files.locate()
	if files == null:
		return
	var data := Keen5Episode.load_data(files)
	var chunk := data.graphics.misc(Keen5Episode.GALAXY_MISC)
	assert_equal(chunk.size(), STAR_COUNT * 8, "four arrays of 4000 words")
	var scene := Keen5GalaxyExplosion.from_data(data)
	assert_equal(scene._stars_x.size(), STAR_COUNT, "4000 stars")
	var count := data.graphics.ranges.picture_count
	var picture := data.graphics.picture(count - Keen5Episode.MILKY_WAY_FROM_END)
	assert_equal(picture.get_size(), SIZE, "the Milky Way over the whole screen")


## A scene with a galaxy whose first pixels are entries 7 and 8, a red
## GAMEOVER and [param stars].
func _scene(stars: PackedByteArray) -> Keen5GalaxyExplosion:
	var galaxy := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	galaxy.fill(Color.BLACK)
	galaxy.set_pixel(0, 0, EgaPalette.color(LIGHT_GREY))
	galaxy.set_pixel(1, 0, EgaPalette.color(DARK_GREY))
	var game_over := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	game_over.fill(Color.RED)
	return Keen5GalaxyExplosion.create(galaxy, game_over, stars)


## The stars' chunk: 4000 of each array; [param given] are the first ones
## as [x, dx, y, dy] in pixels × 128, the rest stand far beyond the screen.
static func _stars(given: Array) -> PackedByteArray:
	var chunk := PackedByteArray()
	chunk.resize(STAR_COUNT * 8)
	for star in STAR_COUNT:
		var values := [0xFFFF, 0, 0xFFFF, 0]
		if star < given.size():
			values = [
				given[star][0] * STAR_UNITS,
				given[star][1] * STAR_UNITS,
				given[star][2] * STAR_UNITS,
				given[star][3] * STAR_UNITS,
			]
		for array in 4:
			var at: int = (array * STAR_COUNT + star) * 2
			if array % 2 == 0:
				chunk.encode_u16(at, values[array] & 0xFFFF)
			else:
				chunk.encode_s16(at, values[array])
	return chunk
