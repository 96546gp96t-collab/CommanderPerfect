class_name Keen2Platform
extends Keen2Carrier
## The moving platform of Keen 2 (info value 6): it floats sideways,
## starting to the right; at a wall or the edge of the map it waits a moment
## and goes back. Keen can ride on it ([Keen2Carrier]). It is always active,
## also out of sight, and it swallows every shot without harm.

const SPRITE_FIRST := 126
const FRAMES := 2
## The collision box inside the sprite. estimate: to be read from the sprite
## table of EGAHEAD.CK2.
const BODY_BOX := Rect2(0, 0, 32, 8)  # estimate
## The level places it this far above the top of its cell.
const RAISE := 4.0

const SPEED := 23 * Keen2Enemy.SUBPIXEL  # estimate
const WAIT_TICKS := 51  # estimate
const FRAME_TICKS := 16  # estimate

var _wait := 0


## A platform for the info value at the cell whose top left is
## [param cell_start].
static func create(cell_start: Vector2) -> Keen2Platform:
	var platform := Keen2Platform.new()
	platform.position = cell_start + Vector2(0, -RAISE)
	platform.body_box = BODY_BOX
	platform.falls = false
	platform.facing = 1
	platform.is_active = true
	return platform


func sprite_index() -> int:
	return SPRITE_FIRST + (_timer / FRAME_TICKS) % FRAMES


func stops_shots() -> bool:
	return true


func hit_by_shot(_session: LevelSession) -> void:
	pass


func _think(session: LevelSession) -> void:
	_timer += 1
	if _wait > 0:
		_wait -= 1
		return
	if not _walk(session, SPEED):
		facing = -facing
		_wait = WAIT_TICKS
