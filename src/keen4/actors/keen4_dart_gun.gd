class_name Keen4DartGun
extends GalaxyCreature
## A dart gun of Keen 4 (Omni `ck4_obj3.c`, facts and numbers only;
## docs/keen4/research.md §7): an object you never see (the gun is part of
## the tiles) that shoots a poison dart every 150 tics while it is awake
## (near the view). The dart ([GalaxyEnemyShot]) flies 64 a tic in the
## gun's direction (up, right, down or left), two frames of 6 tics, kills
## Keen and is gone at the first wall or off the screen. Nothing harms the
## gun.

## (Omni CK4_ACT_DartGun0, CK4_ACT_Dart*.) The gun's sprite only gives it a
## box; the dart rows go to [GalaxyEnemyShot].
const ROWS: PackedStringArray = [
	"gun - - step -- 150 0 0 shoot - - gun",
]
const DART_ROWS: PackedStringArray = [
	"side_1 DART_L_1 DART_R_1 slide -- 6 64 0 - lethal fly side_2",
	"side_2 DART_L_2 DART_R_2 slide -- 6 64 0 - lethal fly side_1",
	"up_1 DART_UP_1 DART_UP_1 slide -- 6 0 64 - lethal fly up_2",
	"up_2 DART_UP_2 DART_UP_2 slide -- 6 0 64 - lethal fly up_1",
	"down_1 DART_DOWN_1 DART_DOWN_1 slide -- 6 0 64 - lethal fly down_2",
	"down_2 DART_DOWN_2 DART_DOWN_2 slide -- 6 0 64 - lethal fly down_1",
]
## By the gun's direction (0 up, 1 right, 2 down, 3 left, as the info
## values): where it sits in its tile, its sprite (for the box), the dart's
## heading and first action (Omni).
const OFFSETS: Array[Vector2i] = [
	Vector2i(0x90, -0x30), Vector2i(0x80, 0x50), Vector2i(0x90, 0), Vector2i(-0x30, 0x70)
]
const BOX_SPRITES: Array[StringName] = [&"DART_UP_1", &"DART_R_1", &"DART_DOWN_1", &"DART_L_1"]
const HEADINGS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const DART_ACTIONS: Array[StringName] = [&"up_1", &"side_1", &"down_1", &"side_1"]

## 0 up, 1 right, 2 down, 3 left.
var aim := 0


## A gun at [param cell] shooting in direction [param towards] (info 53-56,
## 79-82, 83-86: up, right, down, left).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, towards: int, sprites: Dictionary[StringName, int]
) -> Keen4DartGun:
	var gun := Keen4DartGun.new()
	gun.aim = towards
	gun.clip = Clip.NONE
	gun.hidden = true
	gun.priority = 0
	gun.direction = Vector2i.ZERO
	gun.sprite = sprites.get(BOX_SPRITES[towards], NO_SPRITE)
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	gun.enter(world, at + OFFSETS[towards], ROWS, sprites, &"gun")
	return gun


## Think: a dart (Omni CK4_DartGun).
func _think_shoot() -> void:
	var dart := GalaxyEnemyShot.fire(
		world, position, HEADINGS[aim], DART_ROWS, sprites, DART_ACTIONS[aim]
	)
	dart.priority = 0
	world.play_sound(&"dart_shoot")
