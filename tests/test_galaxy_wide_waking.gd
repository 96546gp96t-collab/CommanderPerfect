extends "res://tests/test_case.gd"
## Tests for waking in widescreen (D13.2): Galaxy objects wake up, fall
## asleep and count as on the screen around what a wider view shows
## ([member GalaxyCamera.wide_width], [member GalaxyCamera.shown]) with the
## original's margins around it, so nothing on the screen sleeps; with the
## original's view everything stays as it was. Made-up levels; the last
## test plays Keen 4's level 1 from its frames with the player's files
## (skipped without them).

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
## A level wide enough that the view is nowhere near its ends.
const LEVEL_WIDTH := 80
## The view's first tile across, and what the original's view counts as
## its end (20 tiles on).
const VIEW_FIRST := 20
const VIEW_END := 40
## A 16:9 view with the pixel aspect corrected: 426 pixels, centred on the
## original's 320 (53 more on each side): tiles 16-43.
const WIDE := 426
const WIDE_FIRST := 16
const WIDE_END := 43
## A tile the 4:3 view does not wake (beyond its end and the margin of 1)
## that the wide view shows.
const RIGHT_OF_VIEW := 43
const LEFT_OF_VIEW := 17
const LEVEL_NUMBER := 1
const FRAMES := 400
const RANDOM_START := 41


## An object that only stands there.
class Still:
	extends GalaxyObject

	func _think_still() -> void:
		pass


const ROWS: PackedStringArray = ["still - - think -- 0 0 0 still - - still"]


func test_the_original_view_counts_20_by_13_tiles() -> void:
	var camera := _camera()
	assert_equal(camera.view_tiles(), Rect2i(VIEW_FIRST, 2, 20, 13), "as before")


func test_a_wide_view_adds_what_it_shows() -> void:
	var camera := _camera()
	camera.wide_width = WIDE
	var tiles := camera.view_tiles()
	assert_equal(tiles.position.x, WIDE_FIRST, "3 more tiles on the left")
	assert_equal(tiles.end.x, WIDE_END, "3 more on the right")
	assert_equal(tiles.position.y, 2, "the same rows")
	assert_equal(tiles.end.y, 15, "the original's 13")


func test_a_half_of_the_split_screen_adds_what_it_shows() -> void:
	var camera := _camera()
	camera.shown = Rect2i(50 * 16, 3 * 16, WIDE, 200)
	var tiles := camera.view_tiles()
	assert_equal(tiles.position.x, VIEW_FIRST, "the original's view")
	assert_equal(tiles.end.x, (50 * 16 + WIDE) >> 4, "up to the half's right edge")


func test_in_4_3_an_object_beside_the_view_sleeps() -> void:
	var world := _world()
	var right := _still(world, RIGHT_OF_VIEW)
	var left := _still(world, LEFT_OF_VIEW)
	_frames(world, 1)
	assert_equal(right.activity, GalaxyObject.Activity.INACTIVE, "right: asleep, as the original")
	assert_equal(left.activity, GalaxyObject.Activity.INACTIVE, "left: asleep")


func test_in_widescreen_an_object_on_the_screen_is_awake_and_drawn() -> void:
	var world := _world()
	world.camera.wide_width = WIDE
	var right := _still(world, RIGHT_OF_VIEW)
	var left := _still(world, LEFT_OF_VIEW)
	var far := _still(world, LEVEL_WIDTH - 10)
	_frames(world, 1)
	assert_true(GalaxyWorld.is_awake(right), "right of the 4:3 view, on the wide screen: awake")
	assert_true(GalaxyWorld.is_awake(left), "left of it: awake")
	assert_true(world.on_screen(right), "and on the screen")
	assert_equal(far.activity, GalaxyObject.Activity.INACTIVE, "far away: still asleep")
	var layer := GalaxyObjectLayer.new()
	assert_true(_drawn(layer, world, right), "drawn")
	layer.free()


func test_widescreen_keeps_the_original_margins_for_sleeping() -> void:
	var world := _world()
	world.camera.wide_width = WIDE
	# Awake 4 tiles beyond the wide view's right edge, asleep at once one
	# tile further (the first frame of a level puts the far ones to sleep).
	var kept := _still(world, WIDE_END + GalaxyWorld.SLEEP_MARGIN)
	var gone := _still(world, WIDE_END + GalaxyWorld.SLEEP_MARGIN + 1)
	kept.activity = GalaxyObject.Activity.ACTIVE
	gone.activity = GalaxyObject.Activity.ACTIVE
	_frames(world, 1)
	assert_true(GalaxyWorld.is_awake(kept), "within the margin: awake")
	assert_equal(gone.activity, GalaxyObject.Activity.INACTIVE, "beyond it: asleep")


func test_a_level_played_wide_comes_back_from_its_frames() -> void:
	var files := Keen4Files.locate()
	if files == null:
		return
	var data := Keen4Episode.load_data(files)
	var played := _level(data)
	var frames := PackedByteArray()
	played.set_wide_width(WIDE)
	Keen4SavedGame.record_view_width(frames, WIDE)
	played.player.god_mode = true
	Keen4SavedGame.record_event(frames, Keen4SavedGame.Event.GOD_MODE_ON)
	var tic := 0
	for frame in FRAMES:
		if frame == FRAMES / 2:
			# F2 halfway: the original's view from here on.
			played.set_wide_width(0)
			Keen4SavedGame.record_view_width(frames, 0)
		var input := KeenInput.create(-1 if frame % 160 < 110 else 1, frame % 37 == 0)
		tic += GalaxyClock.NORMAL_TICS
		Keen4SavedGame.record_frame(frames, input, GalaxyClock.NORMAL_TICS)
		played.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
		played.take_conversation()
	var again := _level(data)
	assert_equal(Keen4SavedGame.replay(again, frames), tic, "replayed to the same tic")
	assert_equal(again.camera.wide_width, 0, "the last width")
	assert_equal(again.world.objects.size(), played.world.objects.size(), "the same objects")
	for index in mini(again.world.objects.size(), played.world.objects.size()):
		var one := played.world.objects[index]
		var two := again.world.objects[index]
		assert_equal(two.position, one.position, "object %d where it was" % index)
		assert_equal(two.activity, one.activity, "object %d awake as it was" % index)


func _level(data: GalaxyData) -> Keen4LevelSession:
	return Keen4LevelSession.start(
		data,
		data.maps.load_map(LEVEL_NUMBER),
		Keen4Inventory.new_game(),
		RANDOM_START,
		GalaxyDifficulty.DEFAULT,
		LEVEL_NUMBER
	)


## A camera over an empty level, its view's first tile at [constant
## VIEW_FIRST].
static func _camera() -> GalaxyCamera:
	var camera := GalaxyCamera.for_map(Vector2i(LEVEL_WIDTH + 4, 20))
	camera.reposition(Vector2i(VIEW_FIRST * TILE, 0))
	return camera


static func _world() -> GalaxyWorld:
	var rows := PackedStringArray()
	for row in 15:
		rows.append(".".repeat(LEVEL_WIDTH))
	rows.append("#".repeat(LEVEL_WIDTH))
	var world := GalaxyWorld.create(
		Fixtures.level(rows), Fixtures.tile_info(), Fixtures.sprite_infos()
	)
	world.camera = _camera()
	return world


## A sleeping object one tile wide at column [param column], row 6.
static func _still(world: GalaxyWorld, column: int) -> Still:
	var still := Still.new()
	still.clip = GalaxyObject.Clip.NONE
	still.sprite = 6
	still.position = Vector2i(column * TILE, 6 * TILE)
	world.add(still)
	still.action = GalaxyAction.table_from(ROWS, {})[&"still"]
	still.reset_box()
	still.activity = GalaxyObject.Activity.INACTIVE
	return still


static func _frames(world: GalaxyWorld, count: int) -> void:
	for frame in count:
		world.run_frame(GalaxyClock.NORMAL_TICS, world.tic + GalaxyClock.NORMAL_TICS)


## Whether [param layer] draws [param object] after a frame of [param world].
static func _drawn(layer: GalaxyObjectLayer, world: GalaxyWorld, object: GalaxyObject) -> bool:
	layer.show_objects(world.objects)
	return layer._shown.has(object) and layer._shown[object].node.visible
