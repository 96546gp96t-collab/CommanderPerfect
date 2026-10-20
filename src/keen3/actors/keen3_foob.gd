class_name Keen3Foob
extends Keen3Enemy
## The Foob of Keen 3 (info value 6), as Chocolate Keen has it:
##   WALKING  walks slowly toward Keen as it starts; turns round at a wall,
##            walks off ledges. While it is on the screen, a chance of 2
##            every tick to get scared (YORPSCREAM)
##   SCARED   stands and yells (97-98) for [constant SCARED_TICKS]
##   FLEEING  runs away from Keen, fast; at a wall it stops, facing the
##            wall, and keeps running on the spot
## A Foob that wakes up again while it flees walks again, away from Keen.
## Touching Keen kills the Foob, not Keen; Keen's shots and the enemies'
## shots kill it too (not the Meep's waves). It dies with YORPSCREAM through
## three frames.

enum Mode { WALKING, SCARED, FLEEING }

const SPRITE_WALK_LEFT := 93
const SPRITE_WALK_RIGHT := 95
const WALK_FRAMES := 2
const SPRITE_YELL := 97
const YELL_FRAMES := 2
const SPRITE_DYING := 99
const DYING_FRAMES := 3
## FOOBL1's box (0, 0, 15, 15) in EGAHEAD.CK3: the whole sprite.
const BODY_BOX := Rect2(0, 0, 16, 16)

const HEALTH := 1  # (Choco)
## 50 and 250 (Choco).
const WALK_SPEED := 15.2 * Keen2Enemy.SUBPIXEL
const FLEE_SPEED := 76 * Keen2Enemy.SUBPIXEL
const SCARE_CHANCE := 2  # (Choco)
## 24 clock ticks of yelling; its frames change every 10 (Choco).
const SCARED_TICKS := 9.9
const YELL_FRAME_TICKS := 4.1

var mode := Mode.WALKING
var speed := WALK_SPEED


## A Foob at [param start] that sets off toward [param direction] (1 right,
## -1 left).
static func spawned(start: Vector2, direction: int) -> Keen3Foob:
	var foob := Keen3Foob.new()
	foob.position = start
	foob.body_box = BODY_BOX
	foob.health = HEALTH
	foob.facing = direction
	foob.first_dying_sprite = SPRITE_DYING
	foob.dying_frames = DYING_FRAMES
	return foob


func hurt_by_enemy_shots() -> bool:
	return true


func death_sound() -> Sound.Id:
	return Sound.Id.YORP_SCREAM


## Keen runs into it: the Foob dies, Keen does nothing.
func touch_keen(_session: LevelSession, _keen: KeenBody) -> void:
	die()


## It sees Keen: it yells (YORPSCREAM) and will flee.
func scare(session: LevelSession) -> void:
	mode = Mode.SCARED
	_mode_ticks = 0
	session.play_sound(Sound.Id.YORP_SCREAM)


func _living_sprite() -> int:
	if mode == Mode.SCARED:
		return SPRITE_YELL + frame_after(_age, YELL_FRAME_TICKS, YELL_FRAMES)
	var first := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	var frame_ticks := FAST_FRAME_TICKS if mode == Mode.FLEEING else SLOW_FRAME_TICKS
	return first + frame_after(_age, frame_ticks, WALK_FRAMES)


func _wake(session: LevelSession) -> void:
	if mode != Mode.FLEEING:
		return
	mode = Mode.WALKING
	speed = WALK_SPEED
	facing = -toward(position.x, session.nearest_keen(hitbox().get_center()).position.x)


func _think(session: LevelSession) -> void:
	match mode:
		Mode.WALKING:
			_walk_on(session)
		Mode.SCARED:
			if _mode_ticks > SCARED_TICKS:
				_flee(session)
		Mode.FLEEING:
			_fall(session)
			if not _walk(session, speed):
				speed = 0.0


func _walk_on(session: LevelSession) -> void:
	var keen_3 := session as Keen3LevelSession
	if keen_3.is_on_screen(position) and chance(session, SCARE_CHANCE):
		scare(session)
		return
	_fall(session)
	if not _walk(session, WALK_SPEED):
		facing = -facing


func _flee(session: LevelSession) -> void:
	mode = Mode.FLEEING
	speed = FLEE_SPEED
	facing = -toward(position.x, session.nearest_keen(hitbox().get_center()).position.x)
