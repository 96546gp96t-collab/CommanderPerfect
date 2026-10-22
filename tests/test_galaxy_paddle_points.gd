extends "res://tests/test_case.gd"
## Tests the points and the end of Paddle War ([GalaxyPaddleWar], milestone
## D11) without game files, against Omnispeak's USL_PlayPaddleWar (facts
## only) and what the original (Keen 4 v1.0) does in js-dos: a point for
## either side and the next serve towards the side that lost it, the
## speed-up counted again each round, the end at 21 (nothing moves after
## it), at most 4 tics a frame, the same random numbers playing the same
## game, the ball staying in the field, and the sounds' numbers.

const SERVE_TICS := 70
const START_X := 148
const LEFT_EDGE := 78
## Keen's paddle stops at the first even step past 219 (Omni: "if x < 219,
## x += 2" from 148).
const KEEN_RIGHT_STOP := 220
const COMPUTER_RIGHT_STOP := 219
## The serve in quarter pixels: the middle of the field (seen: 152-153, 99).
const SERVE_X := 612
const SERVE_Y := 396
const SERVE_ROW := 99
## Quarter pixels a tic: the serve's vertical speed and the top speed.
const SERVE_SPEED := 3
const TOP_SPEED := 12
const HITS_PER_SPEEDUP := 10
const WINNING_SCORE := 21
const MAX_TICS_PER_FRAME := 4
## Rows where a paddle hits (the ball's top row), and the scoring lines.
const KEEN_HIT_ROW := 132
const COMPUTER_HIT_ROW := 66
const KEEN_MISS_ROW := 137
const COMPUTER_MISS_ROW := 62
const WALL_RIGHT := 228
const WALL_LEFT := 78
## Sounds (Keen 4: 47-51).
const SOUND_NUMBERS := {
	&"paddle_keen": 47,
	&"paddle_wall": 48,
	&"paddle_computer": 49,
	&"paddle_computer_scores": 50,
	&"paddle_keen_scores": 51,
}

var _sounds: Array[StringName] = []


func test_a_point_for_the_computer() -> void:
	var game := _game([1, 1, 1, 1])
	_serve(game)
	game.keen_x = LEFT_EDGE
	game.ball_speed_x = 0
	_sounds.clear()
	var tics := 0
	while game.computer_score == 0 and tics < 200:
		game.step(false, false)
		tics += 1
	assert_equal(game.computer_score, 1, "the computer scores")
	assert_equal(game.keen_score, 0, "Keen does not")
	assert_true(_sounds.has(&"paddle_computer_scores"), "its sound: %s" % str(_sounds))
	assert_equal(game.ball_y, KEEN_MISS_ROW + 1, "the ball's last place: row 138 (seen)")
	# The next serve: 70 tics later, towards Keen again.
	for _tic in SERVE_TICS - 1:
		game.step(false, false)
		assert_true(not game.ball_visible, "no ball while waiting")
	game.step(false, false)
	assert_true(game.ball_visible, "served after 70 tics")
	assert_equal(game.ball_speed_y, SERVE_SPEED, "towards Keen, who lost the point")


func test_a_point_for_keen() -> void:
	var game := _game([1, 1, 1, 1])
	_serve(game)
	game.computer_x = LEFT_EDGE
	game.ball_speed_y = -SERVE_SPEED
	game.ball_speed_x = 0
	game.ball_real_x = 220 * 4
	_sounds.clear()
	var tics := 0
	while game.keen_score == 0 and tics < 200:
		game.step(false, false)
		tics += 1
	assert_equal(game.keen_score, 1, "Keen scores")
	assert_true(_sounds.has(&"paddle_keen_scores"), "his sound: %s" % str(_sounds))
	assert_equal(game.ball_y, COMPUTER_MISS_ROW - 1, "the ball's last place: row 61 (Omni)")
	for _tic in SERVE_TICS:
		game.step(false, false)
	assert_equal(game.ball_speed_y, -SERVE_SPEED, "the next serve goes to the computer")


func test_the_speed_up_counts_again_after_a_point() -> void:
	var game := _game([1, 1, 1, 1, 1])
	_serve(game)
	for _hit in 9:
		game.keen_x = 134
		_put_ball_above_keen(game, 140, SERVE_SPEED)
		game.step(false, false)
	assert_equal(absi(game.ball_speed_y), SERVE_SPEED, "9 hits")
	# The computer misses: a new round.
	game.computer_x = LEFT_EDGE
	game.ball_real_x = 220 * 4
	game.ball_speed_x = 0
	while game.keen_score == 0:
		game.step(false, false)
	for _tic in SERVE_TICS:
		game.step(false, false)
	assert_true(game.ball_visible, "served")
	game.ball_speed_y = SERVE_SPEED
	game.keen_x = 134
	_put_ball_above_keen(game, 140, SERVE_SPEED)
	game.step(false, false)
	assert_equal(
		absi(game.ball_speed_y), SERVE_SPEED, "the 10th hit of the game but the 1st of the round"
	)


func test_first_to_21_wins() -> void:
	var game := _game([1])
	_play_points(game, false, WINNING_SCORE - 1)
	assert_equal(game.computer_score, WINNING_SCORE - 1, "20 points")
	assert_true(not game.is_done(), "not over at 20")
	_play_points(game, false, 1)
	assert_equal(game.computer_score, WINNING_SCORE, "21")
	assert_true(game.is_done(), "over at 21")
	assert_true(not game.keen_won(), "the computer won (seen: You lost!)")
	var frozen := [game.ball_x, game.ball_y, game.keen_x, game.computer_score]
	game.step(true, false)
	game.advance(4, true, false)
	assert_equal(
		[game.ball_x, game.ball_y, game.keen_x, game.computer_score],
		frozen,
		"nothing moves after the end"
	)


func test_keen_can_win() -> void:
	var game := _game([1])
	_play_points(game, true, WINNING_SCORE)
	assert_true(game.is_done(), "over")
	assert_true(game.keen_won(), "Keen won")
	assert_equal(game.keen_score, WINNING_SCORE, "21 for Keen")


func test_at_most_4_tics_a_frame() -> void:
	var game := _game([1])
	game.advance(10, true, false)
	assert_equal(game.keen_x, START_X - 2 * MAX_TICS_PER_FRAME, "4 tics of moving, not 10")
	assert_equal(game.serve_tics, SERVE_TICS - MAX_TICS_PER_FRAME, "4 tics of waiting")
	game.advance(0, true, false)
	assert_equal(game.keen_x, START_X - 2 * MAX_TICS_PER_FRAME, "no tics, no move")


func test_the_same_numbers_play_the_same_game() -> void:
	var a := _game([7, 200, 13, 99, 42, 5, 128, 64])
	var b := _game([7, 200, 13, 99, 42, 5, 128, 64])
	for tic in 3000:
		var left := (tic / 37) % 3 == 0
		var right := (tic / 37) % 3 == 1
		a.step(left, right)
		b.step(left, right)
	assert_equal(
		[a.ball_x, a.ball_y, a.keen_x, a.computer_x, a.keen_score, a.computer_score],
		[b.ball_x, b.ball_y, b.keen_x, b.computer_x, b.keen_score, b.computer_score],
		"deterministic"
	)
	assert_true(a.keen_score + a.computer_score > 0, "points were played")


func test_the_ball_stays_in_the_field() -> void:
	var game := _game([3, 77, 150, 21, 8, 250, 1, 99])
	for tic in 40000:
		game.step((tic / 50) % 2 == 0, (tic / 50) % 2 == 1)
		if game.is_done():
			break
		if game.ball_visible:
			assert_true(
				game.ball_x >= WALL_LEFT and game.ball_x <= WALL_RIGHT,
				"x %d inside the walls" % game.ball_x
			)
			assert_true(
				game.ball_y >= COMPUTER_MISS_ROW - 1 and game.ball_y <= KEEN_MISS_ROW + 1,
				"y %d inside the lines (one row past one when a point is made)" % game.ball_y
			)
		if not failures.is_empty():
			return
	assert_true(game.is_done(), "a whole game ends")


func test_the_sounds_have_keen_4_numbers() -> void:
	for name: StringName in SOUND_NUMBERS:
		assert_equal(Keen4Sounds.NUMBERS.get(name, -1), SOUND_NUMBERS[name], "%s" % name)


## A game whose random numbers come from [param values], round and round
## (each game its own count).
func _game(values: Array[int]) -> GalaxyPaddleWar:
	_sounds.clear()
	var count: Array[int] = [0]
	var next := func() -> int:
		var value := values[count[0] % values.size()]
		count[0] += 1
		return value
	var game := GalaxyPaddleWar.create(next)
	game.sound_played.connect(_sounds.append)
	return game


func _serve(game: GalaxyPaddleWar) -> void:
	for _tic in SERVE_TICS:
		game.step(false, false)


## The ball one step above Keen's row, falling at [param speed], at column
## [param column].
func _put_ball_above_keen(game: GalaxyPaddleWar, column: int, speed := SERVE_SPEED) -> void:
	game.ball_speed_y = speed
	game.ball_speed_x = 0
	game.ball_real_x = column * 4
	game.ball_real_y = KEEN_HIT_ROW * 4 - speed


## Plays [param count] points for Keen ([param for_keen]) or the computer.
func _play_points(game: GalaxyPaddleWar, for_keen: bool, count: int) -> void:
	for _point in count:
		var before := game.keen_score if for_keen else game.computer_score
		var tics := 0
		while not game.ball_visible and tics < 100:
			game.step(false, false)
			tics += 1
		while tics < 1000:
			if for_keen:
				game.computer_x = LEFT_EDGE
				game.ball_real_x = 220 * 4
			else:
				game.keen_x = LEFT_EDGE
				game.ball_real_x = 220 * 4
			game.ball_speed_x = 0
			var speed := absi(game.ball_speed_y)
			game.ball_speed_y = -speed if for_keen else speed
			game.step(false, false)
			tics += 1
			var now := game.keen_score if for_keen else game.computer_score
			if now > before or game.is_done():
				break
