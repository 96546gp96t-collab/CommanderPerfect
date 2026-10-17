class_name Keen2GuardRobot
extends Keen2Enemy
## The Guard robot of Keen 2 (info value 5). It hovers (it never falls),
## floats sideways, starting to the right, and turns only at walls: there it
## looks around for a moment and then goes the other way.
##
## Now and then it fires a volley of [constant VOLLEY_SHOTS] shots the way
## it faces: it stops for a moment, fires them one by one while it floats
## on, and stops again after the last one. It holds a shot back while it
## touches a wall. Looking around ends a volley. It is invincible and stops
## Keen's shots; touching it is deadly.

enum Mode { HOVERING, LOOKING }

## GUARDLEFT1-4 and GUARDRIGHT1-4 in EGAHEAD.CK2 (Commander Genius has
## them the other way round).
const SPRITE_HOVER_LEFT := 112
const SPRITE_HOVER_RIGHT := 116
const HOVER_FRAMES := 4
const SPRITE_LOOK := 120
const LOOK_FRAMES := 2
## The collision box inside the sprite, from the sprite table of
## EGAHEAD.CK2.
const BODY_BOX := Rect2(0, 0, 16, 24)

const SPEED := 31 * Keen2Enemy.SUBPIXEL  # estimate
const HOVER_FRAME_TICKS := 7  # estimate
const LOOK_FRAME_TICKS := 5  # estimate
const LOOK_TICKS := 26  # estimate
## Ticks until the first volley; after that a random wait in the range.
const FIRST_VOLLEY_TICKS := 200  # estimate
const MIN_VOLLEY_WAIT := 31  # estimate
const MAX_VOLLEY_WAIT := 199  # estimate
const VOLLEY_SHOTS := 4  # estimate
const SHOT_INTERVAL := 13  # estimate
## It stands still this long before and after a volley.
const PAUSE_TICKS := 25  # estimate
## The shot leaves this far below the top of the sprite, this far in front.
const SHOT_HEIGHT := 5.0  # estimate
const SHOT_GAP := 4.0  # estimate

var mode := Mode.HOVERING
var _until_volley := FIRST_VOLLEY_TICKS
var _shots_left := 0
var _until_shot := 0
var _pause := 0


static func create(start: Vector2) -> Keen2GuardRobot:
	var robot := Keen2GuardRobot.new()
	robot.position = start
	robot.body_box = BODY_BOX
	robot.falls = false
	robot.facing = 1
	return robot


func sprite_index() -> int:
	if mode == Mode.LOOKING:
		return SPRITE_LOOK + (_timer / LOOK_FRAME_TICKS) % LOOK_FRAMES
	var hover_sprite := SPRITE_HOVER_RIGHT if facing > 0 else SPRITE_HOVER_LEFT
	return hover_sprite + (_timer / HOVER_FRAME_TICKS) % HOVER_FRAMES


func stops_shots() -> bool:
	return true


func hit_by_shot(_session: LevelSession) -> void:
	pass


func _think(session: LevelSession) -> void:
	_timer += 1
	if mode == Mode.LOOKING:
		if _timer >= LOOK_TICKS:
			_shots_left = 0
			_until_volley = session.rng.randi_range(MIN_VOLLEY_WAIT, MAX_VOLLEY_WAIT)
			_set_mode(Mode.HOVERING)
		return
	if _pause > 0:
		_pause -= 1
		return
	if _shots_left > 0:
		_fire_volley(session)
	elif _until_volley > 0:
		_until_volley -= 1
	else:
		_shots_left = VOLLEY_SHOTS
		_until_shot = 0
		_until_volley = session.rng.randi_range(MIN_VOLLEY_WAIT, MAX_VOLLEY_WAIT)
		_pause = PAUSE_TICKS
		return
	if not _walk(session, SPEED):
		facing = -facing
		_set_mode(Mode.LOOKING)


## The next shot of the volley, when it is time and no wall is in the way.
func _fire_volley(session: LevelSession) -> void:
	if _until_shot > 0:
		_until_shot -= 1
		return
	if _is_blocked(session, -1) or _is_blocked(session, 1):
		return
	_fire_shot(session, _shot_start(SHOT_HEIGHT, SHOT_GAP), Sound.Id.TANK_FIRE)
	_until_shot = SHOT_INTERVAL - 1
	_shots_left -= 1
	if _shots_left == 0:
		_pause = PAUSE_TICKS


func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_timer = 0
