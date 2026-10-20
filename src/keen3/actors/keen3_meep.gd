class_name Keen3Meep
extends Keen3Enemy
## The Meep of Keen 3 (info value 4), as Chocolate Keen has it. It starts
## [constant DROP] pixels below the top of its cell, walking toward Keen.
##   WALKING  walks; turns round at a wall. Every tick a chance of 1 to
##            sing, and it also sings whenever it is not on the ground
##            after a step: a bug of the original, kept, so at a ledge it
##            stops in the air, sings, then drops a little and sings again
##   SINGING  stands still (also in the air) with its singing frame; after
##            [constant WAVE_TICKS] MEEP and a sound wave ([Keen3SoundWave])
##            from its front, after [constant SING_TICKS] it walks on the
##            same way
## Touching it pushes Keen aside. One shot from Keen kills it; the enemies'
## shots do not.

enum Mode { WALKING, SINGING }

const SPRITE_WALK_RIGHT := 118
const SPRITE_WALK_LEFT := 120
const WALK_FRAMES := 2
const SPRITE_SING_RIGHT := 122
const SPRITE_SING_LEFT := 123
const SPRITE_DYING := 124
## The collision box: MEEPR1's box (2, 2, 13, 23) in EGAHEAD.CK3.
const BODY_BOX := Rect2(2, 2, 12, 22)
## It starts this far below the top of its cell (Choco).
const DROP := 8.0

const HEALTH := 1  # (Choco)
## 65 (Choco).
const WALK_SPEED := 19.7 * Keen2Enemy.SUBPIXEL
const SING_CHANCE := 1  # (Choco)
## 60 and 80 clock ticks (Choco).
const WAVE_TICKS := 24.7
const SING_TICKS := 33.0
## The wave starts at its left side or this far right of it, this far
## below its top (Choco).
const WAVE_RIGHT_OFFSET := 16.0
const WAVE_DROP := 4.0

var mode := Mode.WALKING
var _sang := false


## A Meep for the cell whose top left is [param cell_start], setting off
## toward [param direction] (1 right, -1 left).
static func spawned(cell_start: Vector2, direction: int) -> Keen3Meep:
	var meep := Keen3Meep.new()
	meep.position = cell_start + Vector2(0, DROP)
	meep.body_box = BODY_BOX
	meep.health = HEALTH
	meep.facing = direction
	meep.first_dying_sprite = SPRITE_DYING
	return meep


func death_sound() -> Sound.Id:
	return Sound.Id.VORTICON_SCREAM


func touch_keen(_session: LevelSession, keen: KeenBody) -> void:
	_push_out(keen)


## Stops where it is (also in the air) to sing a wave the way it faces.
func start_singing() -> void:
	mode = Mode.SINGING
	_mode_ticks = 0
	_sang = false


func _living_sprite() -> int:
	if mode == Mode.SINGING:
		return SPRITE_SING_RIGHT if facing > 0 else SPRITE_SING_LEFT
	var first := SPRITE_WALK_RIGHT if facing > 0 else SPRITE_WALK_LEFT
	return first + frame_after(_age, WALK_FRAME_TICKS, WALK_FRAMES)


func _think(session: LevelSession) -> void:
	if mode == Mode.SINGING:
		_sing(session)
		return
	var sings := chance(session, SING_CHANCE)
	_fall(session)
	if not _walk(session, WALK_SPEED):
		facing = -facing
	if sings or not on_ground:
		start_singing()


func _sing(session: LevelSession) -> void:
	if not _sang and _mode_ticks >= WAVE_TICKS:
		_sang = true
		var offset := Vector2(WAVE_RIGHT_OFFSET if facing > 0 else 0.0, WAVE_DROP)
		session.add_actor(Keen3SoundWave.sent(position + offset, facing))
		var keen_3 := session as Keen3LevelSession
		if keen_3 != null:
			keen_3.play_keen3_sound(Keen3Sounds.MEEP)
	if _mode_ticks > SING_TICKS:
		mode = Mode.WALKING
		_mode_ticks = 0
