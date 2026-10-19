class_name Keen3Mom
extends Keen3Enemy
## The Vorticon mother of Keen 3 (info value 3), as Chocolate Keen has it:
##   WALKING   walks slowly toward Keen as she starts; she does not walk
##             off a ledge: once she has walked off, she is put back and
##             steps back the other way. Turns round at a wall. Every tick a
##             chance of 1 to spit.
##   SPITTING  she turns round and stands still with her spitting frame
##             (the new direction's); after [constant FIRE_TICKS] TANKFIRE
##             and a fireball ([Keen3Fireball]) that way, after
##             [constant SPIT_TICKS] she walks on in the new direction
## Touching her pushes Keen aside; it never kills him. Only Keen's shots
## hurt her, [constant HEALTH] of them; her own fireballs fly through her.

enum Mode { WALKING, SPITTING }

const SPRITE_WALK_LEFT := 85
const SPRITE_WALK_RIGHT := 87
const WALK_FRAMES := 2
const SPRITE_SPIT_LEFT := 89
const SPRITE_SPIT_RIGHT := 90
const SPRITE_DYING := 91
## The collision box: WOMANL1's box (2, 2, 21, 31) in EGAHEAD.CK3.
const BODY_BOX := Rect2(2, 2, 20, 30)

const HEALTH := 5  # (Choco)
## 50 (Choco).
const WALK_SPEED := 15.2 * Keen2Enemy.SUBPIXEL
const SPIT_CHANCE := 1  # (Choco)
## 30 and 50 clock ticks (Choco).
const FIRE_TICKS := 12.4
const SPIT_TICKS := 20.6
## The fireball starts at her left side, this far below her top (Choco).
const FIREBALL_DROP := 12.0

var mode := Mode.WALKING
var _fired := false


## A mother at [param start] that sets off toward [param direction] (1
## right, -1 left).
static func spawned(start: Vector2, direction: int) -> Keen3Mom:
	var mom := Keen3Mom.new()
	mom.position = start
	mom.body_box = BODY_BOX
	mom.health = HEALTH
	mom.facing = direction
	mom.first_dying_sprite = SPRITE_DYING
	return mom


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


func touch_keen(_session: LevelSession, keen: KeenBody) -> void:
	_push_out(keen)


## Turns round and stops to spit a fireball the new way.
func start_spitting() -> void:
	facing = -facing
	mode = Mode.SPITTING
	_mode_ticks = 0
	_fired = false


func _living_sprite() -> int:
	if mode == Mode.SPITTING:
		return SPRITE_SPIT_RIGHT if facing > 0 else SPRITE_SPIT_LEFT
	var first := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return first + frame_after(_age, WALK_FRAME_TICKS, WALK_FRAMES)


func _think(session: LevelSession) -> void:
	if mode == Mode.SPITTING:
		_spit(session)
		return
	if chance(session, SPIT_CHANCE):
		start_spitting()
		return
	_walk_on(session)


func _walk_on(session: LevelSession) -> void:
	var height := position.y
	_fall(session)
	var blocked := not _walk(session, WALK_SPEED)
	if _floor_gone(session):
		# Walked off a ledge: put back up, and two steps back the other way.
		position.y = height
		velocity.y = 0.0
		on_ground = true
		facing = -facing
		_walk(session, 2 * WALK_SPEED)
	elif blocked:
		facing = -facing


func _spit(session: LevelSession) -> void:
	if not _fired and _mode_ticks >= FIRE_TICKS:
		_fired = true
		var start := position + Vector2(0, FIREBALL_DROP)
		# First the spit, then (in a wall) the splash, which cuts it off (Choco).
		session.play_sound(Sound.Id.TANK_FIRE)
		session.add_actor(Keen3Fireball.spat(session, start, facing))
	if _mode_ticks > SPIT_TICKS:
		mode = Mode.WALKING
		_mode_ticks = 0
