extends "res://tests/test_case.gd"
## Tests for looking up and down in Galaxy's split screen ([GalaxySplitView],
## D13.2): split, each half moves as far as its Keen's own camera has moved
## for looking, but his Keen stays inside his half (from the view's edges
## and from the line); one shared view does not move for it. No files.

const VIEW := Vector2i(320, 200)
const LOOK_DOWN := 107.0
const LOOK_UP := -27.0
## A wide area without blocks.
const AREA := Rect2i(0, 0, 4000, 4000)
## Far apart side by side: split along a standing line.
const APART: Array[Vector2] = [Vector2(1000, 1000), Vector2(1600, 1000)]
## Close together: one shared view.
const TOGETHER: Array[Vector2] = [Vector2(1000, 1000), Vector2(1040, 1000)]
const ALIVE: Array[bool] = [true, true]


func test_camera_look_pixels_follow_the_feet_on_the_screen() -> void:
	var camera := GalaxyCamera.for_map(Vector2i(100, 100))
	assert_equal(camera.look_pixels(), 0, "resting")
	camera.feet_on_screen = GalaxyCamera.LOOK_HIGHEST
	assert_equal(camera.look_pixels(), 107, "looking down: the view 107 pixels lower")
	camera.feet_on_screen = GalaxyCamera.LOOK_LOWEST
	assert_equal(camera.look_pixels(), -27, "looking up: 27 pixels higher")


func test_side_by_side_a_look_down_keeps_keen_in_the_view() -> void:
	var view := GalaxySplitView.new()
	view.split.normal = Vector2.RIGHT
	var keen := Vector2(-80, 0)
	var limit := VIEW.y / 2.0 - GalaxySplitView.LOOK_MARGIN
	assert_equal(view.look_within_half(0, LOOK_DOWN, keen, Vector2(VIEW)), limit, "84 down")
	assert_equal(view.look_within_half(0, LOOK_UP, keen, Vector2(VIEW)), LOOK_UP, "27 up")
	assert_equal(view.look_within_half(1, LOOK_UP, -keen, Vector2(VIEW)), LOOK_UP, "player 2")


func test_above_and_below_the_line_keeps_each_keen_in_his_half() -> void:
	var view := GalaxySplitView.new()
	view.split.normal = Vector2.DOWN
	var size := Vector2(VIEW)
	# Player 1 in the top half, 50 pixels above the middle.
	var top := Vector2(0, -50)
	var down := view.look_within_half(0, LOOK_DOWN, top, size)
	assert_equal(down, 34.0, "down until he is 16 pixels below the top")
	var up := view.look_within_half(0, -40.0, top, size)
	assert_equal(up, -34.0, "up until he is 16 pixels above the line")
	# Player 2 in the bottom half, 50 pixels below the middle.
	var bottom := Vector2(0, 50)
	assert_equal(view.look_within_half(1, LOOK_DOWN, bottom, size), 34.0, "player 2 down")
	assert_equal(view.look_within_half(1, LOOK_UP, bottom, size), LOOK_UP, "player 2 up")


func test_a_split_screen_moves_only_the_looking_half() -> void:
	var plain := _settled(APART, [0.0, 0.0])
	var looking := _settled(APART, [LOOK_DOWN, 0.0])
	assert_true(plain.is_split(), "split")
	assert_equal(
		looking.views[0].position.y - plain.views[0].position.y,
		roundi(VIEW.y / 2.0 - GalaxySplitView.LOOK_MARGIN),
		"player 1's half moved down"
	)
	assert_equal(looking.views[1], plain.views[1], "player 2's half stayed")


func test_one_shared_view_does_not_move_for_a_look() -> void:
	var plain := _settled(TOGETHER, [0.0, 0.0])
	var looking := _settled(TOGETHER, [LOOK_DOWN, LOOK_UP])
	assert_true(not looking.is_split(), "shared")
	assert_equal(looking.views[0], plain.views[0], "the same view")


func test_without_looks_the_views_are_as_before() -> void:
	var plain := _settled(APART, [])
	var resting := _settled(APART, [0.0, 0.0])
	assert_equal(resting.views, plain.views, "no look, no change")


## A split view after a few seconds with the Keens at [param positions]
## looking [param looks].
func _settled(positions: Array[Vector2], looks: Array[float]) -> GalaxySplitView:
	var view := GalaxySplitView.new()
	var areas: Array[Rect2i] = [AREA, AREA]
	for frame in 300:
		view.update(positions, ALIVE, areas, VIEW, 1.0 / 60.0, false, [], looks)
	return view
