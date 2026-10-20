class_name GalaxyPaddleWarView
extends RefCounted
## Draws Paddle War ([GalaxyPaddleWar]) on the control panel's 320 × 200
## picture as the original does (Omni `ck_us_2.c`: CK_PaddleWar,
## USL_DrawPaddleWarScore, USL_PlayPaddleWar; facts only, checked against
## Keen 4 v1.0 pixel for pixel):
##   - the wrist watch, the PADDLE WAR title picture at (130, 48) (on whole
##     bytes: 128), a line over the field at y 60 and under it at y 143;
##   - "KEEN:" and Keen's score at (80, 52), "COMP:" at (182, 52) and the
##     computer's score at x 217, each side on a cleared bar;
##   - the picture is kept and changed as the original changes the screen:
##     every frame the ball's old place is cleared (6 × 5) and the ball
##     drawn, then each paddle's old place (16 × 3, from 3 pixels left of
##     it) and the paddle drawn. So a ball passing a paddle's row near the
##     paddle is wiped by that paddle's bar, as in the original.
## Sprites go on even columns: the original keeps 4 shifted copies of each
## (2 pixels apart); an odd ball column takes the second ball sprite,
## which is the first one a pixel further right.

const TITLE_AT := Vector2i(130, 48)
const BYTE := 8
const FIELD_TOP_Y := 60
const FIELD_BOTTOM_Y := 143
const LINE_LEFT := 77
const LINE_RIGHT := 231
## The scores: the label and the number after it, on a bar of this width
## (Omni USL_DrawPaddleWarScore).
const SCORE_Y := 52
const KEEN_SCORE_AT := Vector2i(80, SCORE_Y)
const COMPUTER_SCORE_AT := Vector2i(182, SCORE_Y)
const KEEN_SCORE_WIDTH := 42
const COMPUTER_SCORE_WIDTH := 50
const SCORE_HEIGHT := 6
const KEEN_LABEL := "KEEN:"
const COMPUTER_LABEL := "COMP:"
## Keen's score follows its label; the computer's starts at x 217 (seen
## in v1.0: 6 pixels after its label, whatever the score).
const COMPUTER_NUMBER_X := 217
## The bars that clear the ball and a paddle before they are drawn again.
const BALL_BAR := Vector2i(6, 5)
const PADDLE_BAR := Vector2i(16, 3)
const PADDLE_BAR_LEFT := 3
## Where the original's first "old" places lie (Omni).
const FIRST_OLD_X := 78
const FIRST_OLD_BALL_Y := 62
const BACKGROUND := GalaxyMenuView.BACKGROUND
const BRIGHT := GalaxyMenuView.BRIGHT

var _graphics: GalaxyGraphics
var _cards: GalaxyMenuCards
var _font: GalaxyFont
var _image: Image
var _old_ball := Vector2i(FIRST_OLD_X, FIRST_OLD_BALL_Y)
var _old_computer_x := FIRST_OLD_X
var _old_keen_x := FIRST_OLD_X
var _shown_scores := Vector2i(-1, -1)
var _ball_was_visible := false


static func create(graphics: GalaxyGraphics, cards: GalaxyMenuCards) -> GalaxyPaddleWarView:
	var view := GalaxyPaddleWarView.new()
	view._graphics = graphics
	view._cards = cards
	view._font = graphics.font(cards.font)
	return view


## The card as a new game shows it (Omni CK_PaddleWar).
func start(game: GalaxyPaddleWar) -> Image:
	_image = Image.create_empty(
		GalaxyWindow.SCREEN_SIZE.x, GalaxyWindow.SCREEN_SIZE.y, false, Image.FORMAT_RGBA8
	)
	_image.fill(Color.BLACK)
	_picture(_graphics.picture(_cards.watch), Vector2i.ZERO)
	_picture(
		_graphics.picture(_cards.paddle_war_picture), Vector2i(TITLE_AT.x / BYTE * BYTE, TITLE_AT.y)
	)
	_bar(Rect2i(LINE_LEFT, FIELD_TOP_Y, LINE_RIGHT - LINE_LEFT + 1, 1), BRIGHT)
	_bar(Rect2i(LINE_LEFT, FIELD_BOTTOM_Y, LINE_RIGHT - LINE_LEFT + 1, 1), BRIGHT)
	_old_ball = Vector2i(FIRST_OLD_X, FIRST_OLD_BALL_Y)
	_old_computer_x = FIRST_OLD_X
	_old_keen_x = FIRST_OLD_X
	_shown_scores = Vector2i(-1, -1)
	_ball_was_visible = false
	return update(game)


## The picture after the tics just run.
func update(game: GalaxyPaddleWar) -> Image:
	if _image == null:
		return start(game)
	if Vector2i(game.keen_score, game.computer_score) != _shown_scores:
		_scores(game)
	if _ball_was_visible and not game.ball_visible:
		# A new round wipes the ball (Omni: when it starts).
		_bar(Rect2i(_old_ball, BALL_BAR), BACKGROUND)
	_ball_was_visible = game.ball_visible
	if game.ball_visible:
		_bar(Rect2i(_old_ball, BALL_BAR), BACKGROUND)
		_old_ball = Vector2i(game.ball_x, game.ball_y)
		var ball := _cards.ball_sprites[game.ball_x & 1]
		_sprite(ball, Vector2i(game.ball_x, game.ball_y))
	_old_computer_x = _paddle(_old_computer_x, game.computer_x, GalaxyPaddleWar.COMPUTER_Y)
	_old_keen_x = _paddle(_old_keen_x, game.keen_x, GalaxyPaddleWar.KEEN_Y)
	return _image


## The picture at the end, with the last score (for the dialog over it).
func finish(game: GalaxyPaddleWar) -> Image:
	if _image == null:
		return start(game)
	if Vector2i(game.keen_score, game.computer_score) != _shown_scores:
		_scores(game)
	return _image


func _paddle(old_x: int, x: int, y: int) -> int:
	_bar(Rect2i(Vector2i(old_x - PADDLE_BAR_LEFT, y), PADDLE_BAR), BACKGROUND)
	_sprite(_cards.paddle_sprite, Vector2i(x, y))
	return x


func _scores(game: GalaxyPaddleWar) -> void:
	_shown_scores = Vector2i(game.keen_score, game.computer_score)
	var keen_number_x := KEEN_SCORE_AT.x + _font.text_width(KEEN_LABEL)
	_score(KEEN_LABEL, game.keen_score, KEEN_SCORE_AT, KEEN_SCORE_WIDTH, keen_number_x)
	_score(
		COMPUTER_LABEL,
		game.computer_score,
		COMPUTER_SCORE_AT,
		COMPUTER_SCORE_WIDTH,
		COMPUTER_NUMBER_X
	)


func _score(label: String, score: int, at: Vector2i, width: int, number_x: int) -> void:
	_bar(Rect2i(at, Vector2i(width, SCORE_HEIGHT)), BACKGROUND)
	_text(label, at, BRIGHT)
	_text(str(score), Vector2i(number_x, at.y), BRIGHT)


## A sprite on its shift's column (Omni VH_DrawSprite: no origin).
func _sprite(index: int, at: Vector2i) -> void:
	var picture := _graphics.sprite(index)
	if picture == null:
		return
	var shifts := BYTE
	if index < _graphics.sprite_infos.size() and _graphics.sprite_infos[index].shifts > 0:
		shifts = _graphics.sprite_infos[index].shifts
	var step := BYTE / shifts
	_picture(picture, Vector2i(at.x / step * step, at.y))


func _bar(rect: Rect2i, color: int) -> void:
	_image.fill_rect(rect, EgaPalette.color(color))


func _text(text: String, at: Vector2i, color: int) -> void:
	var picture := _font.render(text, EgaPalette.color(color))
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)


func _picture(picture: Image, at: Vector2i) -> void:
	if picture == null:
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), at)
