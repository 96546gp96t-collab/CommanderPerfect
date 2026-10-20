class_name Keen3GunShot
extends Keen3Shot
## The shot of a wall gun ([Keen3WallGun]), as Chocolate Keen has it: it
## flies straight at [constant Keen3Shot.SPEED], to the right (TANKSHOT,
## 103, 16x8) or down (VTANKSHOT, 104, 8x16), until a wall stops it
## (SHOTHIT and a splash). It flies through every sprite; on its way it
## kills Keen (also a stunned one; not while the ankh protects him), grunts
## and Foobs ([Keen3LevelSession] decides what it touches).

const SPRITE_DOWN := 104
## VTANKSHOT's box (0, 0, 7, 15) in EGAHEAD.CK3: the whole sprite.
const DOWN_SIZE := Vector2(8, 16)
## The 16x16 splash is centred on the 8x16 shot.
const DOWN_SPLASH_OFFSET := Vector2(-4, 0)

## Whether it flies down rather than right.
var downward := false


## A gun's shot from [param start] (top left of its sprite), down when
## [param flies_down], otherwise to the right.
static func fired_from(start: Vector2, flies_down: bool) -> Keen3GunShot:
	var shot := Keen3GunShot.new()
	shot.position = start
	shot.direction = 1
	shot.from_keen = false
	shot.downward = flies_down
	return shot


func step(session: LevelSession) -> void:
	if not downward or is_splashing:
		super.step(session)
		return
	var moved := session.collision.sweep_y(hitbox(), _speed())
	position.y += moved
	if moved != _speed():
		session.play_sound(Sound.Id.SHOT_HIT)
		splash()


func splash() -> void:
	if is_splashing:
		return
	super.splash()
	if downward:
		position += DOWN_SPLASH_OFFSET - RaygunShot.SPLASH_OFFSET


func hitbox() -> Rect2:
	if downward:
		return Rect2(position, DOWN_SIZE)
	return super.hitbox()


func _flying_sprite() -> int:
	return SPRITE_DOWN if downward else ENEMY_SHOT_SPRITE
