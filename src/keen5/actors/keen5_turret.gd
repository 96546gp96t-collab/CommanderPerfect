class_name Keen5Turret
extends Keen5Creature
## A laser turret of Keen 5 (Omni `ck_obj.c` CK_TurretSpawn,
## CK_TurretShoot; facts and numbers only; docs/keen5/research.md §7): an
## object you never see (the gun is part of the tiles) that fires every 120
## tics while it is awake, from its tile's corner, up, right, down or left
## (sound "enemy_shoot"). The laser ([Keen5Shot]) flies 64 units a tic, four
## pictures of 8 tics; it kills Keen, passes stunner shots, stops at a wall
## (sound "enemy_shot_hit", two pictures of 10 tics) and lives only near the
## screen. Nothing harms the turret.

## (Omni CK_ACT_turret*, CK_ACT_turretShot*.)
const ROWS: PackedStringArray = [
	"wait - - step -- 120 0 0 - - - fire",
	"fire - - step p- 1 0 0 fire - - wait",
]
const LASER_ROWS: PackedStringArray = [
	"fly_1 LASER1 LASER1 step+ -- 8 0 0 glide shot shot fly_2",
	"fly_2 LASER2 LASER2 step+ -- 8 0 0 glide shot shot fly_3",
	"fly_3 LASER3 LASER3 step+ -- 8 0 0 glide shot shot fly_4",
	"fly_4 LASER4 LASER4 step+ -- 8 0 0 glide shot shot fly_1",
	"hit_1 LASERHIT1 LASERHIT1 step -- 10 0 0 - - - hit_2",
	"hit_2 LASERHIT2 LASERHIT2 step -- 10 0 0 - - - -",
]
const PRIORITY := 0
## The laser's speed (units a tic) by the turret's aim: up, right, down,
## left (Omni).
const LASER_SPEEDS: Array[Vector2i] = [
	Vector2i(0, -64), Vector2i(64, 0), Vector2i(0, 64), Vector2i(-64, 0)
]

## 0 up, 1 right, 2 down, 3 left (Omni user1).
var aim := 0


## A turret at [param cell] aiming [param towards] (info 45-48, 49-52,
## 53-56: up, right, down, left). Its box is its tile's corner, so it
## wakes and sleeps by that tile (Omni).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, towards: int, sprites: Dictionary[StringName, int]
) -> Keen5Turret:
	var turret := Keen5Turret.new()
	turret.aim = towards
	turret.priority = PRIORITY
	turret.hidden = true
	turret.direction = Vector2i.ZERO
	turret.place(world, cell, Vector2i.ZERO, ROWS, sprites, &"wait")
	var corner := turret.position
	turret.box.left = corner.x
	turret.box.right = corner.x
	turret.box.top = corner.y
	turret.box.bottom = corner.y
	turret.box.middle = corner.x
	turret.box.tile_left = cell.x
	turret.box.tile_right = cell.x
	turret.box.tile_top = cell.y
	turret.box.tile_bottom = cell.y
	turret.box.tile_middle = cell.x
	return turret


## Think: a laser leaves the turret (Omni CK_TurretShoot).
func _think_fire() -> void:
	var laser := Keen5Shot.launch(
		world, position, LASER_SPEEDS[aim], LASER_ROWS, sprites, &"fly_1", false
	)
	laser.priority = PRIORITY
	world.play_sound(&"enemy_shoot")
