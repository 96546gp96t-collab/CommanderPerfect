extends "res://tests/test_case.gd"
## Tests for the split screen when two play: one screen while the players
## are close, two halves when they are far apart, without a jump in
## between, and cameras that stay inside the level.

const VIEW_SIZE := Vector2(426, 200)


func test_close_players_share_one_screen() -> void:
	var split := _split_screen()
	var middle := Vector2(1000, 500)
	split.reset(middle)
	_follow(split, [middle - Vector2(50, 0), middle + Vector2(50, 0)], 60)
	assert_true(not split.is_split(), "one screen")
	assert_true(split.centers[0].is_equal_approx(middle), "looking between them")
	assert_equal(split.line_strength(), 0.0, "no line")


func test_far_players_split_the_screen() -> void:
	var split := _split_screen()
	var first := Vector2(1000, 500)
	var second := first + Vector2(600, 0)
	split.reset(first)
	_follow(split, [first, second], 120)
	assert_true(split.is_split(), "two halves")
	assert_true(split.normal.is_equal_approx(Vector2.RIGHT), "player 2 on the right")
	var reach := VIEW_SIZE.x / 2.0 * SplitScreen.PLAYER_REACH
	# Player 2's camera trails him by the dead zone, as with one player.
	var focus := split.focus
	assert_true(split.centers[0].is_equal_approx(focus[0] + Vector2(reach, 0)), "player 1 left")
	assert_true(split.centers[1].is_equal_approx(focus[1] - Vector2(reach, 0)), "player 2 right")
	var margin := VIEW_SIZE.x / 2.0 * SplitScreen.DEAD_ZONE.x
	assert_true(is_equal_approx(focus[1].x, second.x - margin), "dead zone")
	assert_equal(split.line_strength(), 1.0, "line")


func test_screen_splits_without_a_jump() -> void:
	var split := _split_screen()
	var first := Vector2(1000, 500)
	var reach := split.reach(Vector2.DOWN)
	var just_together := split.targets_for(first, first + Vector2(0, 2 * reach - 0.01))
	var just_apart := split.targets_for(first, first + Vector2(0, 2 * reach + 0.01))
	assert_true(just_together[0].distance_to(just_apart[0]) < 0.1, "player 1's camera")
	assert_true(just_together[1].distance_to(just_apart[1]) < 0.1, "player 2's camera")
	assert_true(just_together[0] == just_together[1], "one screen just before")


func test_cameras_stay_inside_the_level() -> void:
	var split := _split_screen()
	split.center_range = Rect2(200, 100, 800, 300)
	_follow(split, [Vector2(0, 0), Vector2(1500, 0)], 120)
	assert_equal(split.centers[0], Vector2(200, 100), "top left")
	assert_equal(split.centers[1], Vector2(1000, 100), "top right")


func test_near_the_edge_one_screen_lasts_longer() -> void:
	var split := _split_screen()
	split.center_range = Rect2(213, 100, 2000, 0)
	var first := Vector2(30, 100)
	var reach := split.reach(Vector2.RIGHT)
	# The shared view is against the left edge: player 2 may go up to the
	# reach to the right of its middle.
	split.reset(Vector2(213, 100))
	_follow(split, [first, Vector2(213 + reach - 1, 100)], 60)
	assert_true(split.shared and not split.is_split(), "both on one screen")
	_follow(split, [first, Vector2(213 + reach + 30, 100)], 60)
	assert_true(not split.shared and split.is_split(), "split when player 2 goes further")
	_follow(split, [first, Vector2(213 + reach - 1, 100)], 1)
	assert_true(not split.shared, "not back at once")
	# Walking back, the camera trails player 2 by the dead zone.
	var dead_zone := VIEW_SIZE.x / 2.0 * SplitScreen.DEAD_ZONE.x
	var further_in := 213 + reach - SplitScreen.JOIN_DISTANCE - dead_zone - 2
	_follow(split, [first, Vector2(further_in, 100)], 60)
	assert_true(split.shared, "one screen again further in")


func test_narrow_level_keeps_one_screen() -> void:
	var split := _split_screen()
	split.center_range = Rect2(213, 100, 0, 800)
	_follow(split, [Vector2(20, 300), Vector2(400, 300)], 120)
	assert_true(not split.is_split(), "the whole width is on the screen")


func test_dead_player_keeps_his_camera() -> void:
	var split := _split_screen()
	var start := Vector2(1000, 500)
	split.reset(start)
	var moved: Array[Vector2] = [start + Vector2(0, 500), start]
	split.update(moved, [false, true] as Array[bool], 1.0)
	assert_equal(split.focus[0], start, "stays where he died")


func test_small_moves_stay_in_the_dead_zone() -> void:
	var split := _split_screen()
	var start := Vector2(1000, 500)
	var margin := VIEW_SIZE / 2.0 * SplitScreen.DEAD_ZONE
	split.reset(start)
	_follow(split, [start + Vector2(margin.x - 1, 0), start], 1)
	assert_equal(split.focus[0], start, "camera stays")
	_follow(split, [start + Vector2(margin.x + 5, 0), start], 1)
	assert_true(split.focus[0].is_equal_approx(start + Vector2(5, 0)), "follows beyond it")


func _split_screen() -> SplitScreen:
	var split := SplitScreen.new()
	split.view_size = VIEW_SIZE
	return split


## Lets [param split] follow players standing at [param positions] for
## [param seconds] seconds.
func _follow(split: SplitScreen, positions: Array, seconds: int) -> void:
	var typed: Array[Vector2] = [positions[0], positions[1]]
	for second in seconds:
		split.update(typed, [true, true] as Array[bool], 1.0)
