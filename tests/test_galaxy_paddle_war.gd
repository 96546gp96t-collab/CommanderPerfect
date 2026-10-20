extends "res://tests/test_case.gd"
## Tests the rules of Paddle War ([GalaxyPaddleWar], milestone D11) without
## game files, against Omnispeak's USL_PlayPaddleWar (facts only) and what
## the original (Keen 4 v1.0) does in js-dos: the serve 70 tics after a
## point from the middle towards the side that lost it, Keen's paddle 2
## pixels a tic between its edges, the computer's 1 pixel on two tics of
## three, the walls, the angle off a paddle and the speed-up every 10 hits
## on Keen's paddle (the points and the end: test_galaxy_paddle_points.gd).

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


func test_the_constants_are_the_originals() -> void:
	assert_equal(GalaxyPaddleWar.SERVE_TICS, SERVE_TICS, "serve delay")
	assert_equal(GalaxyPaddleWar.PADDLE_SPEED, 2, "Keen's paddle speed")
	assert_equal(GalaxyPaddleWar.SPEEDUP_HITS, HITS_PER_SPEEDUP, "hits per speed-up")
	assert_equal(GalaxyPaddleWar.WINNING_SCORE, WINNING_SCORE, "first to 21")
	assert_equal(GalaxyPaddleWar.MAX_TICS_PER_FRAME, MAX_TICS_PER_FRAME, "tics per frame")
	assert_equal(GalaxyPaddleWar.COMPUTER_Y, 66, "the computer's row")
	assert_equal(GalaxyPaddleWar.KEEN_Y, 135, "Keen's row")


func test_a_new_game() -> void:
	var game := _game([0])
	assert_equal([game.keen_x, game.computer_x], [START_X, START_X], "both paddles in the middle")
	assert_equal([game.keen_score, game.computer_score], [0, 0], "no points")
	assert_true(not game.ball_visible, "no ball yet")
	assert_true(not game.is_done(), "not over")


func test_the_serve_comes_after_70_tics() -> void:
	var game := _game([0])
	for _tic in SERVE_TICS - 1:
		game.step(false, false)
	assert_true(not game.ball_visible, "no ball after 69 tics")
	game.step(false, false)
	assert_true(game.ball_visible, "the ball on the 70th tic (seen: ~1 s)")
	assert_equal(game.ball_speed_y, SERVE_SPEED, "the first serve goes down to Keen")
	assert_equal(game.ball_y, (SERVE_Y + SERVE_SPEED) / 4, "it has moved once (row 99)")
	assert_equal(game.ball_y, SERVE_ROW, "row 99, as seen")


func test_the_serve_direction_is_random() -> void:
	# 1 − (random mod 3): +1, 0 or −1 quarter pixel a tic (all three seen).
	var expected := {0: 1, 1: 0, 2: -1, 3: 1, 4: 0, 255: 1}
	for value: int in expected:
		var game := _game([value])
		_serve(game)
		assert_equal(game.ball_speed_x, expected[value], "random %d" % value)
		assert_equal(
			game.ball_x, (SERVE_X + expected[value]) / 4, "served from the middle (%d)" % value
		)


func test_keen_moves_two_pixels_a_tic_between_the_edges() -> void:
	var game := _game([1])
	game.step(true, false)
	assert_equal(game.keen_x, START_X - 2, "left: 2 pixels")
	game.step(false, true)
	assert_equal(game.keen_x, START_X, "right: 2 pixels")
	game.step(true, true)
	assert_equal(game.keen_x, START_X - 2, "both held: left wins (Omni)")
	for _tic in 100:
		game.step(true, false)
	assert_equal(game.keen_x, LEFT_EDGE, "stops at the left edge")
	for _tic in 100:
		game.step(false, true)
	assert_equal(game.keen_x, KEEN_RIGHT_STOP, "stops at the right edge (Omni)")


func test_the_computer_waits_for_the_ball() -> void:
	var game := _game([1])
	for _tic in SERVE_TICS - 1:
		game.step(false, false)
	assert_equal(game.computer_x, START_X, "it does not move before the serve")


func test_the_computer_moves_on_two_tics_of_three() -> void:
	var game := _game([1, 1, 1])
	_serve(game)
	var start := game.computer_x
	# The ball far right, flying straight across (no wall, no paddle).
	game.ball_real_x = 220 * 4
	game.ball_real_y = 100 * 4
	game.ball_speed_x = 0
	game.ball_speed_y = 0
	var moves: Array[int] = []
	for _tic in 12:
		var before := game.computer_x
		game.step(false, false)
		moves.append(game.computer_x - before)
	var total := 0
	for move in moves:
		total += move
		assert_true(move == 0 or move == 1, "one pixel at a time: %s" % str(moves))
	assert_equal(total, 8, "8 pixels in 12 tics: %s" % str(moves))
	assert_true(game.computer_x > start, "towards the ball")
	assert_equal(moves.count(0), 4, "it rests one tic of three")


func test_the_computer_stops_at_the_ball_and_at_the_edges() -> void:
	var game := _game([1])
	_serve(game)
	game.ball_speed_x = 0
	game.ball_speed_y = 0
	game.ball_real_x = 141 * 4
	game.ball_real_y = 100 * 4
	for _tic in 60:
		game.step(false, false)
	# It aims its left edge + 6 at the ball's column (seen: ball 140, paddle
	# 134); an even column is made odd by chance, so it may rest one off.
	assert_equal(game.computer_x, 141 - 6, "the paddle's middle under the ball")
	game.ball_real_x = 230 * 4
	for _tic in 200:
		game.step(false, false)
	assert_equal(game.computer_x, COMPUTER_RIGHT_STOP, "stops at the right edge")
	game.ball_real_x = 60 * 4
	for _tic in 300:
		game.step(false, false)
	assert_equal(game.computer_x, LEFT_EDGE, "stops at the left edge")


func test_the_ball_bounces_off_the_walls() -> void:
	var game := _game([0])
	_serve(game)
	_sounds.clear()
	game.ball_real_x = WALL_RIGHT * 4 + 3
	game.ball_speed_x = 1
	game.step(false, false)
	assert_equal(game.ball_speed_x, -1, "off the right wall")
	assert_equal(_sounds, [&"paddle_wall"], "the wall sound")
	assert_true(game.ball_x <= WALL_RIGHT, "it stays inside")
	_sounds.clear()
	game.ball_real_x = WALL_LEFT * 4
	game.ball_speed_x = -2
	game.step(false, false)
	assert_equal(game.ball_speed_x, 2, "off the left wall")
	assert_equal(_sounds, [&"paddle_wall"], "the wall sound again")


func test_keens_paddle_sends_the_ball_back_at_an_angle() -> void:
	# Seen: ball 142, Keen 134 → +2 quarter pixels a tic, up at 3.
	var cases := {
		[142, 134]: 2,
		[137, 134]: -1,  # (8 / 2) − 4 = 0 becomes −1
		[129, 134]: -4,  # the far left of the reach: (0 / 2) − 4
		[144, 134]: 3,  # the far right: (15 / 2) − 4
	}
	for case: Array in cases:
		var game := _game([1])
		_serve(game)
		game.keen_x = case[1]
		_put_ball_above_keen(game, case[0])
		_sounds.clear()
		game.step(false, false)
		assert_equal(game.ball_speed_y, -SERVE_SPEED, "back up (%s)" % str(case))
		assert_equal(game.ball_speed_x, cases[case], "the angle (%s)" % str(case))
		assert_equal(_sounds, [&"paddle_keen"], "Keen's paddle sound (%s)" % str(case))


func test_the_ball_misses_beside_keens_paddle() -> void:
	for ball_x in [128, 145]:
		var game := _game([1])
		_serve(game)
		game.keen_x = 134
		_put_ball_above_keen(game, ball_x)
		game.step(false, false)
		assert_equal(game.ball_speed_y, SERVE_SPEED, "no bounce at %d" % ball_x)


func test_the_computers_paddle_sends_the_ball_back() -> void:
	# Seen: ball 184, computer 178 → +1 quarter pixel a tic.
	var game := _game([1])
	_serve(game)
	game.computer_x = 178
	game.ball_speed_y = -SERVE_SPEED
	game.ball_speed_x = 0
	game.ball_real_x = 184 * 4
	game.ball_real_y = (COMPUTER_HIT_ROW + 3) * 4 + 1
	_sounds.clear()
	game.step(false, false)
	assert_equal(game.ball_speed_y, SERVE_SPEED, "back down")
	assert_equal(game.ball_speed_x, 1, "the angle (seen)")
	assert_equal(_sounds, [&"paddle_computer"], "the computer's paddle sound")


func test_the_ball_speeds_up_every_10_hits_on_keens_paddle() -> void:
	var game := _game([1])
	_serve(game)
	var speeds: Array[int] = []
	for _hit in 100:
		var speed := absi(game.ball_speed_y)
		game.keen_x = 134
		_put_ball_above_keen(game, 140, speed)
		game.step(false, false)
		speeds.append(absi(game.ball_speed_y))
	assert_equal(speeds[8], SERVE_SPEED, "9 hits: still 3")
	assert_equal(speeds[9], SERVE_SPEED + 1, "the 10th hit: 4")
	assert_equal(speeds[19], SERVE_SPEED + 2, "20 hits: 5")
	assert_equal(speeds[88], TOP_SPEED - 1, "89 hits: 11")
	assert_equal(speeds[89], TOP_SPEED, "90 hits: 12 quarter pixels, 3 pixels a tic")
	assert_equal(speeds.max(), TOP_SPEED, "never more: %s" % str(speeds))
	assert_equal(speeds[99], TOP_SPEED, "it stays at the top")


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
