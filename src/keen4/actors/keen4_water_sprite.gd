class_name Keen4WaterSprite
extends GalaxyCreature
## A sprite of Keen 4's Well of Wishes (info 17, 23 from Normal, 24 on
## Hard; Omni `ck4_obj3.c`, CK4_SpawnSprite, CK4_SpritePatrol,
## CK4_SpriteAim, CK4_SpriteShoot, facts and numbers only;
## docs/keen4/research.md §7): it bobs up and down around its place (1 on
## odd tics, at most 8 a tic, turning 32 units from it); once Keen's box is
## level with its own it faces him and aims (40 tics); still level with
## him it shoots (40 tics, the shot leaves at the end, then 30 tics), then
## bobs again. The shot flies 64 a tic sideways (four pictures of 10 tics)
## and is gone at a wall or off the screen. Touching the sprite or its shot
## kills Keen; the stunner does nothing (there is none under water).

## (Omni CK4_ACT_Sprite0, SpriteAiming0, SpriteShooting0-1.)
const ROWS: PackedStringArray = [
	"patrol SPRITE_FACE SPRITE_FACE think -- 0 0 0 patrol lethal - patrol",
	"aim SPRITE_LOOK_L SPRITE_LOOK_R step -- 40 0 0 aim lethal - patrol",
	"shoot_1 SPRITE_SHOOT_L SPRITE_SHOOT_R step -- 40 0 0 shoot lethal - shoot_2",
	"shoot_2 SPRITE_SHOOT_L SPRITE_SHOOT_R step -- 30 0 0 - lethal - patrol",
]
## (Omni CK4_ACT_SpriteBullet0-3.)
const SHOT_ROWS: PackedStringArray = [
	"fly_1 SPRITE_FIRE_1 SPRITE_FIRE_1 slide -- 10 64 0 - lethal fly fly_2",
	"fly_2 SPRITE_FIRE_2 SPRITE_FIRE_2 slide -- 10 64 0 - lethal fly fly_3",
	"fly_3 SPRITE_FIRE_3 SPRITE_FIRE_3 slide -- 10 64 0 - lethal fly fly_4",
	"fly_4 SPRITE_FIRE_4 SPRITE_FIRE_4 slide -- 10 64 0 - lethal fly fly_1",
]
const PRIORITY := 0
## Bobbing (Omni): the speed-up, the top speed and how far from its place.
const BOB_ACCEL := 1
const BOB_MAX := 8
const BOB_REACH := 0x20
## The shot leaves this far below its position (Omni).
const SHOT_DROP := 0x80

## Its place (y, in units).
var home := 0


## A sprite at [param cell] (info 17, 23, 24).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4WaterSprite:
	var sprite_object := Keen4WaterSprite.new()
	sprite_object.priority = PRIORITY
	sprite_object.clip = Clip.NONE
	sprite_object.direction = Vector2i(1, 1)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	sprite_object.home = at.y
	sprite_object.enter(world, at, ROWS, sprites, &"patrol")
	return sprite_object


## Whether Keen's box is level with its own.
func sees_player() -> bool:
	var keen := world.player()
	return keen.box.top < box.bottom and keen.box.bottom > box.top


## Think: bobbing; Keen level with it: it turns to him and aims (Omni
## CK4_SpritePatrol).
func _think_patrol() -> void:
	Keen4Lindsey.bob(self, home, BOB_ACCEL, BOB_MAX, BOB_REACH)
	if sees_player():
		direction.x = -1 if world.player().position.x < position.x else 1
		_continue_as(&"aim")


## Think at the end of aiming: still level with Keen it shoots (Omni
## CK4_SpriteAim).
func _think_aim() -> void:
	if sees_player():
		_continue_as(&"shoot_1")


## Think: the shot (Omni CK4_SpriteShoot).
func _think_shoot() -> void:
	var at := position + Vector2i(0, SHOT_DROP)
	var shot := GalaxyEnemyShot.fire(
		world, at, Vector2i(direction.x, 0), SHOT_ROWS, sprites, &"fly_1"
	)
	shot.priority = PRIORITY
