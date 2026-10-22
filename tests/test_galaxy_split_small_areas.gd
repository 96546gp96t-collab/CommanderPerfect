extends "res://tests/test_case.gd"
## Tests for Galaxy's split screen in small areas ([GalaxySplitView],
## D13.2): while one Keen is in an area shut in by scroll blocks that is
## smaller than the view, the screen splits along a standing line through
## the middle and his area is in the middle of his own half (before, it was
## in the middle of the whole screen, partly in the other player's half,
## and his own half showed black). Both outside again, the line turns back
## to the one at right angles between the Keens; the turn glides. Two Keens
## close together in one area still share one view. No files.

## A widescreen view.
const VIEW := Vector2i(426, 200)
const FRAME := 1.0 / 60.0
const SETTLE_FRAMES := 300
## A wide area without blocks.
const OUTSIDE := Rect2i(0, 0, 6000, 4000)
## A small house: narrower than half the view, lower than the view.
const HOUSE := Rect2i(2000, 1000, 160, 176)
## A room wider than half the view, narrower than the whole.
const ROOM := Rect2i(2000, 1000, 300, 208)
## A wide corridor lower than the view.
const CORRIDOR := Rect2i(2000, 1000, 1200, 144)
## Border Village's house: a strip as wide as the level, 13 tiles high.
const STRIP := Rect2i(32, 368, 1728, 208)
const IN_STRIP := Vector2(450, 480)
## Border Village's start: 288 high, room enough for a slanting line.
const ROOMY := Rect2i(32, 64, 1728, 288)
## 1.2 views wide: not small.
const WIDE_ENOUGH := Rect2i(0, 0, 512, 256)
const IN_HOUSE := Vector2(2080, 1150)
const IN_ROOM := Vector2(2030, 1150)
const IN_CORRIDOR := Vector2(2600, 1080)
## Right of the house, outside.
const RIGHT_OF_HOUSE := Vector2(2700, 1150)
## Left of the house, outside.
const LEFT_OF_HOUSE := Vector2(1400, 1150)
## Far apart on a slant: a slanting line.
const SLANT: Array[Vector2] = [Vector2(1000, 1000), Vector2(1500, 1300)]
const ALIVE: Array[bool] = [true, true]
## Pixels a view may move in one frame of a turn (it glides).
const MOST_STEP := 30.0
## Radians the line may turn in one frame.
const MOST_TURN := 0.3
const NEAR := 1.0


func test_a_keen_in_a_small_house_gets_a_standing_line() -> void:
	var view := _settled([IN_HOUSE, RIGHT_OF_HOUSE], [HOUSE, OUTSIDE])
	assert_true(view.is_split(), "split")
	assert_equal(view.straight, 1.0, "the line stands")
	assert_equal(view.line_normal, Vector2.RIGHT, "player 2 right: he is further right")
	assert_equal(view.left_player, 0, "player 1 left")


func test_the_house_is_in_the_middle_of_his_own_half() -> void:
	var view := _settled([IN_HOUSE, RIGHT_OF_HOUSE], [HOUSE, OUTSIDE])
	var on_screen := _area_middle_on_screen(view, 0, HOUSE)
	_assert_near(on_screen.x, VIEW.x / 4.0, NEAR, "the middle of the left half, not of the screen")
	_assert_near(on_screen.y, VIEW.y / 2.0, NEAR, "lower than the view: in the middle")


func test_the_player_further_left_gets_the_left_half() -> void:
	var view := _settled([LEFT_OF_HOUSE, IN_HOUSE], [OUTSIDE, HOUSE])
	assert_equal(view.left_player, 0, "player 1 is further left")
	var swapped := _settled([IN_HOUSE, LEFT_OF_HOUSE], [HOUSE, OUTSIDE])
	assert_equal(swapped.left_player, 1, "player 2 is further left")
	assert_equal(swapped.line_normal, Vector2.LEFT, "player 2's half is on the left")
	var on_screen := _area_middle_on_screen(swapped, 0, HOUSE)
	_assert_near(on_screen.x, VIEW.x * 3.0 / 4.0, NEAR, "player 1's house in the right half")


func test_the_sides_stay_while_the_line_stands() -> void:
	var view := _settled([IN_HOUSE, RIGHT_OF_HOUSE], [HOUSE, OUTSIDE])
	var positions: Array[Vector2] = [IN_HOUSE, LEFT_OF_HOUSE]
	var areas: Array[Rect2i] = [HOUSE, OUTSIDE]
	for frame in SETTLE_FRAMES:
		view.update(positions, ALIVE, areas, VIEW, FRAME)
	assert_equal(view.left_player, 0, "player 2 walked to the left: no swap")
	assert_equal(view.line_normal, Vector2.RIGHT, "the halves stay")


func test_a_room_wider_than_the_half_fills_his_half() -> void:
	var view := _settled([IN_ROOM, RIGHT_OF_HOUSE], [ROOM, OUTSIDE])
	assert_equal(view.straight, 1.0, "narrower than the view: the line stands")
	var left := view.views[0].position.x
	assert_true(left >= ROOM.position.x - NEAR, "his half starts inside the room")
	assert_true(left + VIEW.x / 2.0 <= ROOM.end.x + NEAR, "and ends inside it")


func test_a_low_corridor_gets_a_standing_line_too() -> void:
	var view := _settled([IN_CORRIDOR, RIGHT_OF_HOUSE + Vector2(1000, 0)], [CORRIDOR, OUTSIDE])
	assert_equal(view.straight, 1.0, "lower than the view")
	var on_screen := _area_middle_on_screen(view, 0, CORRIDOR)
	_assert_near(on_screen.y, VIEW.y / 2.0, NEAR, "centred in height")


func test_a_strip_a_little_higher_than_the_view_is_small() -> void:
	var size := Vector2(VIEW)
	assert_true(GalaxySplitView.is_small(STRIP, size), "208 high: the view cannot move")
	assert_true(not GalaxySplitView.is_small(ROOMY, size), "288 high: room enough")
	assert_true(not GalaxySplitView.is_small(WIDE_ENOUGH, size), "1.2 views: room enough")
	assert_true(GalaxySplitView.is_small(Rect2i(0, 0, 511, 400), size), "narrower than 1.2")
	assert_true(not GalaxySplitView.is_small(Rect2i(), size), "no area")
	var view := _settled([IN_STRIP, IN_STRIP + Vector2(300, -200)], [STRIP, OUTSIDE])
	assert_equal(view.straight, 1.0, "the line stands")
	var keen := IN_STRIP - Vector2(view.views[0].position)
	_assert_near(keen.x, VIEW.x / 4.0, NEAR, "his Keen in the middle of his half")


func test_both_outside_keep_the_slanting_line() -> void:
	var view := _settled(SLANT, [OUTSIDE, OUTSIDE])
	assert_true(view.is_split(), "split")
	assert_equal(view.straight, 0.0, "no small area: the line does not stand")
	assert_equal(view.line_normal, view.split.normal, "the line of SplitScreen")
	assert_true(absf(view.line_normal.y) > 0.1, "slanting")


func test_a_small_area_in_a_slanting_split_is_in_his_half() -> void:
	var anchor := Vector2(-80, -40)
	var center := GalaxySplitView.centre_small_axes(Vector2(500, 500), HOUSE, Vector2(VIEW), anchor)
	var middle := Vector2(HOUSE.get_center())
	_assert_near(middle.x - center.x, anchor.x, NEAR, "narrower: at his half's middle")
	_assert_near(middle.y - center.y, anchor.y, NEAR, "lower: at his half's middle too")


func test_the_turn_glides_both_ways() -> void:
	var view := _settled(SLANT, [OUTSIDE, OUTSIDE])
	var house := Rect2i(Vector2i(SLANT[0]) - Vector2i(80, 88), HOUSE.size)
	var areas: Array[Rect2i] = [house, OUTSIDE]
	_assert_glides(view, areas, "turning to stand")
	assert_equal(view.straight, 1.0, "stands at last")
	assert_equal(view.line_normal, Vector2.RIGHT, "a standing line")
	var outside: Array[Rect2i] = [OUTSIDE, OUTSIDE]
	_assert_glides(view, outside, "turning back")
	assert_equal(view.straight, 0.0, "back")
	assert_equal(view.line_normal, view.split.normal, "the slanting line again")


func test_one_shared_view_in_a_small_house_stays_shared() -> void:
	var together: Array[Vector2] = [IN_HOUSE, IN_HOUSE + Vector2(20, 0)]
	var view := _settled(together, [HOUSE, HOUSE])
	assert_true(not view.is_split(), "one view")
	assert_equal(view.straight, 0.0, "no line")
	var on_screen := _area_middle_on_screen(view, 0, HOUSE)
	_assert_near(on_screen.x, VIEW.x / 2.0, NEAR, "the house in the middle, as alone")
	assert_equal(view.views[0], view.views[1], "the same view")


## Turns until settled with the Keens where they are, in [param areas],
## and checks that no frame jumps.
func _assert_glides(view: GalaxySplitView, areas: Array[Rect2i], what: String) -> void:
	var biggest_step := 0.0
	var biggest_turn := 0.0
	for frame in SETTLE_FRAMES:
		var before: Array[Rect2i] = view.views.duplicate()
		var normal := view.line_normal
		view.update(SLANT, ALIVE, areas, VIEW, FRAME)
		biggest_turn = maxf(biggest_turn, absf(normal.angle_to(view.line_normal)))
		for player in GalaxySplitView.PLAYERS:
			var step := Vector2(view.views[player].position - before[player].position).length()
			biggest_step = maxf(biggest_step, step)
	assert_true(biggest_step < MOST_STEP, "%s: the views glide (%s)" % [what, biggest_step])
	assert_true(biggest_turn < MOST_TURN, "%s: the line turns gently (%s)" % [what, biggest_turn])


## A split view after a few seconds with the Keens at [param positions] in
## [param areas].
func _settled(positions: Array[Vector2], areas: Array[Rect2i]) -> GalaxySplitView:
	var view := GalaxySplitView.new()
	for frame in SETTLE_FRAMES:
		view.update(positions, ALIVE, areas, VIEW, FRAME)
	return view


## Where the middle of [param area] is on [param player]'s view.
func _area_middle_on_screen(view: GalaxySplitView, player: int, area: Rect2i) -> Vector2:
	return Vector2(area.get_center() - view.views[player].position)


func _assert_near(actual: float, expected: float, margin: float, description: String) -> void:
	assert_true(
		absf(actual - expected) <= margin, "%s (%s, not %s)" % [description, actual, expected]
	)
