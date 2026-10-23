extends "res://tests/test_case.gd"
## Checks that the five demos of Keen 5 v1.4 play as in the original, with
## the player's own files (milestone E7; skipped without them or with
## another version, whose demos may differ): each demo is played headless,
## as the title loop plays it, and at a few frames the sprites of Keen and
## of the creatures must be drawn where the original drew them. The rows
## come from frames that equal the original's recorded frames pixel for
## pixel (js-dos, the title loop of the user's v1.4: research.md, "Watched
## in E7: the demos"). They hold the five causes found in E7: Keen landing
## on a platform also moves by the shared step's x (demo 2 frame 107), a
## platform turning sideways stops on the tile's edge (demo 2 frame 718),
## a spent mine piece is drawn once more (demo 4 frame 71) and Keen pushed
## sideways by an Ampton moves by the shared step's y (his pogo lands a
## frame early, demo 4 frame 246); the order of sprites of one priority
## (demo 4 frame 87) is checked in test_keen5_front.

## Rows of "demo frame sprite x y": after logic frame [i]frame[/i] of the
## demo, a sprite is drawn with its top left at (x, y) in the 320 × 200
## view.
const SEEN: PackedStringArray = [
	"0 100 21 192 88",
	"0 100 132 146 -14",
	"0 100 310 130 23",
	"0 100 93 162 61",
	"0 100 93 162 77",
	"0 100 93 178 81",
	"0 100 93 178 70",
	"0 100 93 194 73",
	"0 100 93 194 89",
	"0 300 12 172 74",
	"0 300 272 100 -19",
	"0 300 110 116 31",
	"0 300 110 132 31",
	"0 300 110 148 31",
	"0 300 110 116 47",
	"0 300 110 132 47",
	"0 300 110 148 47",
	"0 300 309 156 197",
	"0 300 93 164 74",
	"0 300 93 180 74",
	"0 300 93 180 61",
	"0 500 60 144 109",
	"0 500 313 216 33",
	"0 500 344 104 196",
	"0 500 93 168 62",
	"0 500 93 136 97",
	"0 700 64 152 103",
	"0 700 344 104 41",
	"0 840 37 158 113",
	"0 840 344 146 133",
	"1 200 18 144 111",
	"1 200 108 110 -19",
	"1 200 108 126 -19",
	"1 200 109 142 -19",
	"1 200 109 158 -19",
	"1 200 108 174 -19",
	"1 200 108 190 -19",
	"1 200 109 206 -19",
	"1 200 118 286 -19",
	"1 200 118 302 -19",
	"1 200 108 110 -3",
	"1 200 108 126 -3",
	"1 200 109 142 -3",
	"1 200 109 158 -3",
	"1 200 108 174 -3",
	"1 200 108 190 -3",
	"1 200 109 206 -3",
	"1 200 118 286 -3",
	"1 200 118 302 -3",
	"1 200 108 110 13",
	"1 200 108 126 13",
	"1 200 109 142 13",
	"1 200 109 158 13",
	"1 200 108 174 13",
	"1 200 108 190 13",
	"1 200 109 206 13",
	"1 200 322 134 67",
	"1 500 14 144 109",
	"1 500 269 72 13",
	"1 500 264 8 37",
	"1 800 14 144 128",
	"1 800 273 172 48",
	"1 800 265 52 16",
	"1 800 273 68 128",
	"1 1000 20 144 67",
	"1 1000 283 6 49",
	"1 1000 264 310 109",
	"1 1000 96 150 72",
	"1 1000 96 150 88",
	"1 1000 96 134 77",
	"1 1000 96 134 93",
	"2 107 14 152 89",
	"2 107 320 148 112",
	"2 107 320 100 104",
	"2 107 320 52 73",
	"2 110 37 152 108",
	"2 110 320 148 128",
	"2 110 320 100 134",
	"2 110 320 52 103",
	"2 300 21 144 62",
	"2 300 314 220 117",
	"2 300 270 20 29",
	"2 300 275 68 67",
	"2 300 314 156 117",
	"2 300 54 100 52",
	"2 718 7 192 87",
	"2 718 320 24 -6",
	"2 718 265 232 -10",
	"2 718 112 80 22",
	"2 718 115 16 87",
	"2 718 115 16 103",
	"2 718 115 16 119",
	"2 718 115 16 135",
	"2 718 115 16 151",
	"2 718 115 16 167",
	"2 718 115 16 183",
	"2 718 115 16 199",
	"2 721 8 192 105",
	"2 721 320 16 11",
	"2 721 266 210 7",
	"2 721 112 66 39",
	"2 721 115 2 104",
	"2 721 115 2 120",
	"2 721 115 2 136",
	"2 721 115 2 152",
	"2 721 115 2 168",
	"2 721 115 2 184",
	"2 1000 74 186 104",
	"2 1000 124 -22 31",
	"2 1000 275 106 114",
	"2 1000 113 26 140",
	"2 1370 6 162 144",
	"3 300 7 192 110",
	"3 300 270 292 -19",
	"3 300 275 228 95",
	"3 600 37 168 76",
	"3 600 344 202 0",
	"3 600 116 32 33",
	"3 600 344 112 38",
	"3 600 117 32 49",
	"3 600 344 240 58",
	"3 600 344 150 96",
	"3 865 36 224 75",
	"3 865 344 52 80",
	"3 865 117 272 177",
	"3 865 117 288 177",
	"3 865 116 272 193",
	"3 865 117 288 193",
	"3 1100 14 144 109",
	"3 1100 344 160 40",
	"3 1100 344 282 178",
	"3 1100 325 64 123",
	"3 1100 325 112 110",
	"3 1100 275 88 115",
	"3 1100 117 96 174",
	"3 1100 117 112 174",
	"3 1100 117 128 174",
	"3 1260 14 144 109",
	"3 1260 283 286 -34",
	"3 1260 325 248 153",
	"3 1260 325 296 144",
	"3 1260 275 272 163",
	"4 71 12 200 103",
	"4 71 283 108 108",
	"4 71 318 120 32",
	"4 71 311 224 168",
	"4 71 340 112 168",
	"4 71 342 176 182",
	"4 71 343 48 185",
	"4 120 8 280 162",
	"4 120 283 244 117",
	"4 120 315 160 112",
	"4 120 313 80 168",
	"4 246 89 300 165",
	"4 246 283 252 54",
	"4 246 318 188 52",
	"4 246 303 288 168",
	"4 247 89 300 157",
	"4 247 283 248 59",
	"4 247 318 180 58",
	"4 247 303 288 168",
	"4 400 7 18 161",
	"4 400 283 136 117",
	"4 400 316 240 104",
	"4 400 306 120 168",
	"4 600 17 0 160",
	"4 600 283 184 72",
	"4 600 316 40 104",
	"4 600 303 96 168",
]
const DEMOS := 5
## The user's version, whose demos were recorded.
const RECORDED_VERSION := "1.4"
const DEMO_MAPS: PackedInt32Array = [1, 3, 10, 11, 15]
const DEMO_FRAMES: PackedInt32Array = [842, 1024, 1381, 1267, 703]

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()
	if _data.executable.version != RECORDED_VERSION:
		skip("the demos were measured in Keen 5 v1.4")


func test_the_demos_are_their_maps_and_lengths() -> void:
	var maps := PackedInt32Array()
	var frames := PackedInt32Array()
	for demo in DEMOS:
		var recorded := GalaxyDemo.parse(_data.graphics.demo(demo))
		maps.append(recorded.map_number)
		frames.append(recorded.frame_count())
	assert_equal(maps, DEMO_MAPS, "maps 1, 3, 10, 11 and the high scores' 15")
	assert_equal(frames, DEMO_FRAMES, "their logic frames")


func test_every_demo_plays_to_its_end_as_the_original() -> void:
	for demo in DEMOS:
		var session := _demo_session(demo)
		var recorded := GalaxyDemo.parse(_data.graphics.demo(demo))
		var played := _play(session, recorded, recorded.frame_count())
		assert_equal(played, recorded.frame_count(), "demo %d: Keen lives to its end" % demo)


func test_every_demo_draws_what_the_original_drew() -> void:
	var missing: PackedStringArray = []
	for demo in DEMOS:
		missing.append_array(_missing_in(demo))
	assert_equal(missing, PackedStringArray(), "rows not drawn as in the original")


## Plays [param frames] frames of [param recorded] in [param session];
## returns how many were played before Keen left the level.
func _play(session: Keen5LevelSession, recorded: GalaxyDemo, frames: int) -> int:
	var clock := GalaxyClock.new()
	clock.start_level()
	clock.tics_per_frame = GalaxyClock.DEMO_TICS
	var firing := GalaxyTwoButtonFiring.new()
	for frame in frames:
		if not session.is_playing():
			return frame
		var tics := clock.run_frame()
		session.run_frame(firing.convert(recorded.controls_at(frame), tics), tics, clock.tic)
	return frames


## The rows of [param demo] that its play does not draw.
func _missing_in(demo: int) -> PackedStringArray:
	var wanted: Dictionary[int, PackedStringArray] = {}
	var last := -1
	for row in SEEN:
		var parts := row.split(" ")
		if int(parts[0]) != demo:
			continue
		var frame := int(parts[1])
		if not wanted.has(frame):
			wanted[frame] = PackedStringArray()
		wanted[frame].append(" ".join(parts.slice(2)))
		last = maxi(last, frame)
	var missing: PackedStringArray = []
	var session := _demo_session(demo)
	var recorded := GalaxyDemo.parse(_data.graphics.demo(demo))
	var clock := GalaxyClock.new()
	clock.start_level()
	clock.tics_per_frame = GalaxyClock.DEMO_TICS
	var firing := GalaxyTwoButtonFiring.new()
	for frame in range(1, last + 1):
		var tics := clock.run_frame()
		session.run_frame(firing.convert(recorded.controls_at(frame - 1), tics), tics, clock.tic)
		if not wanted.has(frame):
			continue
		var drawn := _drawn(session)
		for sprite in wanted[frame]:
			if not drawn.has(sprite):
				missing.append("%d %d %s" % [demo, frame, sprite])
	return missing


## Demo [param demo]'s map as the title loop starts it: a new game on
## Normal, the random table from its start.
func _demo_session(demo: int) -> Keen5LevelSession:
	var recorded := GalaxyDemo.parse(_data.graphics.demo(demo))
	var inventory := Keen5Inventory.new_game()
	inventory.extra_lives_for_points = false
	var map := _data.maps.load_map(recorded.map_number)
	var session := Keen5LevelSession.start_level(
		_data, _rules, map, inventory, 0, GalaxyDifficulty.DEFAULT, recorded.map_number
	)
	session.world.random_index = 0
	return session


## Every sprite drawn now, as "sprite x y" in the view's pixels.
func _drawn(session: Keen5LevelSession) -> PackedStringArray:
	var drawn: PackedStringArray = []
	var view := session.camera.view_pixels()
	for object in session.world.objects:
		if not GalaxyWorld.is_awake(object) or object.hidden or object.sprite < 0:
			continue
		var info := _data.graphics.sprite_infos[object.sprite]
		var pixel := GalaxyObjectLayer.pixel_of(info, object.position + object.draw_offset) - view
		drawn.append("%d %d %d" % [object.sprite, pixel.x, pixel.y])
	return drawn
