extends "res://tests/test_case.gd"
## Checks that the five demos of Keen 4 v1.0 play as in the original, with
## the player's own files (milestone D13; skipped without them or with
## another version, whose demos differ): each demo is played headless, as
## the title loop plays it, and at a few frames the sprites of Keen and of
## the creatures must be drawn where the original drew them. The numbers
## were measured in the original's recorded frames (js-dos, D8's
## recordings): every row was found there pixel for pixel, at the frame
## that equals ours. Since D13 whole 4:3 frames of all five demos equal the
## original's (research.md, "Watched in D13: demos"); these rows hold the
## three causes found: the creatures sleep until the view comes near, the
## shared step (a slug that leaves its slime does not step back, demo 3
## frame 25) and a door that puts the view on Keen at once (demo 0's stars
## and Bounder, demo 2's inchworms).

## Rows of "demo frame sprite x y": after logic frame [i]frame[/i] of the
## demo, a sprite (an object's or its stars) is drawn with its top left at
## (x, y) in the 320 × 200 view.
const SEEN: PackedStringArray = [
	"0 60 89 154 60",
	"0 246 6 160 96",
	"0 308 18 144 111",
	"0 308 40 2 111",
	"0 460 15 146 110",
	"0 460 42 116 111",
	"0 559 14 144 109",
	"0 559 191 88 117",
	"0 730 14 144 109",
	"0 730 371 54 118",
	"1 100 13 148 91",
	"1 300 325 70 97",
	"1 500 6 192 130",
	"1 500 41 148 132",
	"1 650 19 144 94",
	"1 650 42 236 47",
	"1 650 40 208 111",
	"2 200 10 192 111",
	"2 450 259 14 69",
	"2 640 6 152 128",
	"2 640 210 24 148",
	"2 640 212 192 148",
	"2 640 212 256 148",
	"2 690 209 114 152",
	"2 690 211 210 152",
	"2 690 211 274 152",
	"2 690 95 178 81",
	"2 690 95 162 55",
	"2 720 7 192 129",
	"2 720 346 106 128",
	"2 720 210 136 148",
	"2 720 212 208 148",
	"2 720 212 272 148",
	"3 25 6 26 109",
	"3 25 196 232 117",
	"3 25 53 112 113",
	"3 40 11 80 102",
	"3 40 42 208 107",
	"3 40 199 232 133",
	"3 160 40 164 111",
	"3 300 42 114 111",
	"3 300 42 214 111",
	"3 300 93 178 51",
	"3 300 92 194 63",
	"3 500 19 144 72",
	"3 500 199 302 79",
	"4 50 6 120 160",
	"4 50 331 240 185",
	"4 50 197 68 170",
	"4 50 264 192 175",
	"4 50 371 290 161",
	"4 120 20 244 98",
	"4 120 332 240 185",
	"4 120 192 24 170",
	"4 120 264 216 175",
	"4 120 372 146 130",
	"4 120 199 80 184",
	"4 200 14 230 160",
	"4 200 264 120 175",
	"4 200 370 106 130",
	"4 200 199 92 184",
	"4 260 14 16 160",
	"4 260 332 240 185",
	"4 260 192 176 170",
	"4 260 269 96 168",
	"4 260 367 62 146",
	"4 260 199 124 184",
]
const DEMOS := 5
## The user's version, whose demos were recorded.
const RECORDED_VERSION := "1.0"
## Demo 3 plays map 15, where a skypest waits just below the first view.
const DEMO_3_MAP := 15

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)
	if _data.executable.version != RECORDED_VERSION:
		skip("the demos were measured in Keen 4 v1.0")


func test_every_demo_draws_what_the_original_drew() -> void:
	var missing: PackedStringArray = []
	for demo in DEMOS:
		missing.append_array(_missing_in(demo))
	assert_equal(missing, PackedStringArray(), "rows not drawn as in the original")


func test_creatures_sleep_until_the_view_comes_near() -> void:
	var map := _data.maps.load_map(DEMO_3_MAP)
	var inventory := Keen4Inventory.new_game()
	var session := Keen4LevelSession.start(_data, map, inventory)
	var awake := 0
	for object in session.world.objects:
		if object.activity not in [GalaxyObject.Activity.ALWAYS, GalaxyObject.Activity.INACTIVE]:
			awake += 1
	assert_equal(awake, 0, "only the ever-awake ones (Keen, platforms) are awake before a frame")


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
	for frame in last + 1:
		var tics := clock.run_frame()
		session.run_frame(firing.convert(recorded.controls_at(frame), tics), tics, clock.tic)
		if not wanted.has(frame):
			continue
		var drawn := _drawn(session)
		for sprite in wanted[frame]:
			if not drawn.has(sprite):
				missing.append("%d %d %s" % [demo, frame, sprite])
	return missing


## Demo [param demo]'s map as the title loop starts it: a new game on
## Normal, the random table from its start.
func _demo_session(demo: int) -> Keen4LevelSession:
	var recorded := GalaxyDemo.parse(_data.graphics.demo(demo))
	var inventory := Keen4Inventory.new_game()
	inventory.extra_lives_for_points = false
	var map := _data.maps.load_map(recorded.map_number)
	var session := Keen4LevelSession.start(
		_data, map, inventory, 0, GalaxyDifficulty.DEFAULT, recorded.map_number
	)
	session.world.random_index = 0
	return session


## Every sprite drawn now, objects' and their overlays', as "sprite x y"
## in the view's pixels.
func _drawn(session: Keen4LevelSession) -> PackedStringArray:
	var drawn: PackedStringArray = []
	var view := session.camera.view_pixels()
	for object in session.world.objects:
		if not GalaxyWorld.is_awake(object) or object.hidden:
			continue
		drawn.append(_as_drawn(object.sprite, object.position + object.draw_offset, view))
		for overlay in object.overlays:
			drawn.append(_as_drawn(overlay.sprite, object.position + overlay.offset, view))
	return drawn


func _as_drawn(sprite: int, at: Vector2i, view: Vector2i) -> String:
	if sprite < 0 or sprite >= _data.graphics.sprite_infos.size():
		return ""
	var pixel := GalaxyObjectLayer.pixel_of(_data.graphics.sprite_infos[sprite], at) - view
	return "%d %d %d" % [sprite, pixel.x, pixel.y]
