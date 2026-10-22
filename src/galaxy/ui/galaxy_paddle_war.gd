class_name GalaxyPaddleWar
extends RefCounted
## The rules of Paddle War, the little paddle game on the control panel of
## a Galaxy episode (Omni `ck_us_2.c`, USL_PlayPaddleWar; facts only, and
## seen in Keen 4 v1.0): Keen's paddle at the bottom, the computer's at the
## top, a ball between them; first to [constant WINNING_SCORE] wins.
##   - one [method step] is one tic (70 a second); a frame runs the tics
##     since the last one, at most [constant MAX_TICS_PER_FRAME];
##   - Keen's paddle moves [constant PADDLE_SPEED] pixels a tic; the
##     computer's follows the ball one pixel on two tics of three, only
##     while the ball is in play;
##   - the ball is served [constant SERVE_TICS] tics after a point, from the
##     middle, towards the side that lost the point; it moves in quarter
##     pixels, bounces off the side walls, and off a paddle at an angle
##     that depends on where it hit; every [constant SPEEDUP_HITS] hits on
##     Keen's paddle it gets a quarter pixel faster (up to 3 pixels a tic);
##   - a ball past a paddle is a point for the other side.
## Drawn by [GalaxyPaddleWarView]; the sounds go out by [signal
## sound_played] with the names of the episode's sound table.

## A sound: paddle_keen, paddle_wall, paddle_computer,
## paddle_computer_scores or paddle_keen_scores.
signal sound_played(name: StringName)

const MAX_TICS_PER_FRAME := 4
## Positions are in quarter pixels.
const QUARTERS := 4
const PADDLE_SPEED := 2
## The computer moves on the tics whose count is not a multiple of this.
const COMPUTER_PAUSE_EVERY := 3
const SERVE_TICS := 70
const SPEEDUP_HITS := 10
## The ball stops speeding up at this many pixels a tic.
const TOP_SPEED := 3
const WINNING_SCORE := 21
## Where the paddles can go (their left edge) and where they start.
const LEFT := 78
const RIGHT := 219
const START_X := 148
## The paddles' rows and the half width the computer aims with.
const COMPUTER_Y := 66
const KEEN_Y := 135
const PADDLE_AIM := 6
## The ball: its side walls, the lines past which a point is scored, its
## serve (in quarter pixels) and its vertical speed then.
const WALL_LEFT := 78
const WALL_RIGHT := 228
const KEEN_MISSES_BELOW := 137
const COMPUTER_MISSES_ABOVE := 62
const SERVE_X := 612
const SERVE_Y := 396
const SERVE_SPEED_Y := 3
## The horizontal speed of a serve: 1 minus a random number below this.
const SERVE_DIRECTIONS := 3
## Where a paddle hits the ball: the ball's row range, and how far left and
## right of the paddle's edge it reaches.
const COMPUTER_HIT_TOP := 66
const KEEN_HIT_TOP := 132
const HIT_ROWS := 3
const HIT_REACH_LEFT := 5
const HIT_REACH_RIGHT := 11
## The angle after a hit: (ball x + this − paddle x) / 2 − [constant
## HIT_CENTRE].
const HIT_OFFSET := 5
const HIT_CENTRE := 4

## Keen's and the computer's paddle (left edge, pixels).
var keen_x := START_X
var computer_x := START_X
## The ball in pixels, and whether it is in play.
var ball_x := 0
var ball_y := 0
var ball_visible := false
## The ball in quarter pixels, and its speed in quarter pixels a tic.
var ball_real_x := 0
var ball_real_y := 0
var ball_speed_x := 0
var ball_speed_y := 0
var keen_score := 0
var computer_score := 0
## Tics until the ball is served.
var serve_tics := 0
var _random: Callable
var _new_round := true
var _keen_won_last := false
var _computer_counter := 0
var _hits_to_speedup := SPEEDUP_HITS
var _done := false


## A new game; [param random] gives the original's random numbers
## (0-255, US_RndT).
static func create(random: Callable) -> GalaxyPaddleWar:
	var game := GalaxyPaddleWar.new()
	game._random = random
	return game


## Whether someone reached [constant WINNING_SCORE].
func is_done() -> bool:
	return _done


func keen_won() -> bool:
	return keen_score >= WINNING_SCORE


## Runs [param tics] tics (at most [constant MAX_TICS_PER_FRAME]) with the
## same keys held.
func advance(tics: int, left: bool, right: bool) -> void:
	for _tic in mini(tics, MAX_TICS_PER_FRAME):
		if _done:
			return
		step(left, right)


## One tic.
func step(left: bool, right: bool) -> void:
	if _done:
		return
	_move_keen(left, right)
	if _new_round:
		ball_visible = false
		serve_tics = SERVE_TICS
		_hits_to_speedup = SPEEDUP_HITS
		_new_round = false
	if ball_visible:
		_move_computer()
	if not ball_visible:
		serve_tics -= 1
		if serve_tics > 0:
			return
		_serve()
	_move_ball()


func _move_keen(left: bool, right: bool) -> void:
	if left:
		if keen_x > LEFT:
			keen_x -= PADDLE_SPEED
	elif right and keen_x < RIGHT:
		keen_x += PADDLE_SPEED


## The computer follows the ball on two tics of three; it aims at the
## ball's column, an even one made odd now and then by chance (the
## original keeps that column as the ball's until the ball moves).
func _move_computer() -> void:
	var counter := _computer_counter
	_computer_counter += 1
	if counter % COMPUTER_PAUSE_EVERY == 0:
		return
	ball_x = ball_real_x / QUARTERS
	if ball_x & 1 == 0:
		ball_x += _next_random() & 1
	if computer_x + PADDLE_AIM < ball_x and computer_x < RIGHT:
		computer_x += 1
	elif computer_x + PADDLE_AIM > ball_x and computer_x > LEFT:
		computer_x -= 1


func _serve() -> void:
	ball_visible = true
	ball_speed_x = 1 - _next_random() % SERVE_DIRECTIONS
	ball_speed_y = -SERVE_SPEED_Y if _keen_won_last else SERVE_SPEED_Y
	ball_real_x = SERVE_X
	ball_real_y = SERVE_Y


func _move_ball() -> void:
	var next_x := (ball_real_x + ball_speed_x) / QUARTERS
	if next_x > WALL_RIGHT or next_x < WALL_LEFT:
		sound_played.emit(&"paddle_wall")
		ball_speed_x = -ball_speed_x
	ball_real_x += ball_speed_x
	var next_y := (ball_real_y + ball_speed_y) / QUARTERS
	if next_y > KEEN_MISSES_BELOW:
		_point(false)
	elif next_y < COMPUTER_MISSES_ABOVE:
		_point(true)
	if _done:
		return
	ball_real_y += ball_speed_y
	ball_x = ball_real_x / QUARTERS
	ball_y = ball_real_y / QUARTERS
	if not _new_round:
		_bounce()


func _point(for_keen: bool) -> void:
	_new_round = true
	_keen_won_last = for_keen
	if for_keen:
		keen_score += 1
		sound_played.emit(&"paddle_keen_scores")
	else:
		computer_score += 1
		sound_played.emit(&"paddle_computer_scores")
	_done = keen_score == WINNING_SCORE or computer_score == WINNING_SCORE


## Off a paddle: the angle by where the ball hit it; Keen's paddle speeds
## the ball up every [constant SPEEDUP_HITS] hits.
func _bounce() -> void:
	var paddle := -1
	if ball_speed_y < 0 and _hits(computer_x, COMPUTER_HIT_TOP):
		paddle = computer_x
		sound_played.emit(&"paddle_computer")
	elif ball_speed_y > 0 and _hits(keen_x, KEEN_HIT_TOP):
		if ball_speed_y / QUARTERS < TOP_SPEED:
			_hits_to_speedup -= 1
			if _hits_to_speedup == 0:
				ball_speed_y += 1
				_hits_to_speedup = SPEEDUP_HITS
		paddle = keen_x
		sound_played.emit(&"paddle_keen")
	if paddle < 0:
		return
	ball_speed_y = -ball_speed_y
	ball_speed_x = (ball_x + HIT_OFFSET - paddle) / 2 - HIT_CENTRE
	if ball_speed_x == 0:
		ball_speed_x = -1


func _hits(paddle: int, top: int) -> bool:
	return (
		ball_y >= top
		and ball_y < top + HIT_ROWS
		and paddle - HIT_REACH_LEFT <= ball_x
		and paddle + HIT_REACH_RIGHT > ball_x
	)


func _next_random() -> int:
	return int(_random.call())
