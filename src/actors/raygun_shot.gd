class_name RaygunShot
extends Actor
## A raygun shot: flies straight sideways until it hits a wall, then shows a
## short "zap" or "zot" splash. Keen's shots hit enemies; enemy shots (from
## the tank robots, later) hit Keen.

const SPRITE_KEEN_SHOT := 108
const SPRITE_ENEMY_SHOT := 109
const SPRITE_ZAP := 110
const SPRITE_ZOT := 111
## Ticks the splash stays visible. An estimate, still to be compared with the
## original.
const SPLASH_TICKS := 10
## The splash is 16x16 and the shot 16x8, so the splash moves up to stay
## centered.
const SPLASH_OFFSET := Vector2(0, -4)

## 1 for right, -1 for left.
var direction := 1
var from_keen := true
var is_splashing := false
var _splash_timer := 0


static func create(start: Vector2, flying_direction: int, fired_by_keen := true) -> RaygunShot:
	var shot := RaygunShot.new()
	shot.position = start
	shot.direction = flying_direction
	shot.from_keen = fired_by_keen
	return shot


func step(session: LevelSession) -> void:
	if is_splashing:
		_splash_timer -= 1
		if _splash_timer <= 0:
			removed = true
		return
	var distance := direction * KeenPhysics.SHOT_SPEED
	var moved := session.collision.sweep_x(hitbox(), distance)
	position.x += moved
	if moved != distance:
		splash()


## Stops the shot where it is and shows the splash.
func splash() -> void:
	if is_splashing:
		return
	is_splashing = true
	_splash_timer = SPLASH_TICKS
	position += SPLASH_OFFSET


## Whether the shot can still hit something.
func is_flying() -> bool:
	return not is_splashing and not removed


func sprite_index() -> int:
	if is_splashing:
		# The original picks one of the two at random; the cell decides here,
		# so that the game stays repeatable.
		var cell := floori(position.x / EgaGraphics.TILE_SIZE)
		return SPRITE_ZAP if posmod(cell, 2) == 0 else SPRITE_ZOT
	return SPRITE_KEEN_SHOT if from_keen else SPRITE_ENEMY_SHOT


func hitbox() -> Rect2:
	return Rect2(position, KeenPhysics.SHOT_SIZE)
