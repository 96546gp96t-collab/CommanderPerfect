class_name Keen5RoboRed
extends Keen5Creature
## Robo Red of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it walks 64 units a step of 6 tics, turning
## at walls and ledges. On a step that ends with bit 0x40 of its x clear,
## with Keen's box beside its own (overlapping in height) and a chance of
## 16 in 256, it faces him and fires ten shots: it stands 40 tics, then each
## shot is a lurch 64 forward (4 tics) and a shot 6 tics later, with a
## recoil of 64 back. A shot ([Keen5Shot]) flies 60 sideways and 8 up or
## down, alternately; it kills Keen, and stops at walls (sound
## "enemy_shot_hit"). Touching Robo Red kills Keen. A stunner shot is
## absorbed and makes it fire at once, facing Keen; it cannot be stunned.

## (Omni CK5_ACT_Robo*, CK5_ACT_RoboShot*.)
const ROWS: PackedStringArray = [
	"walk ROBOREDL ROBOREDR step -s 6 64 0 look robo walk walk",
	"aim ROBOREDL ROBOREDR step ps 40 0 0 - deadly - lurch",
	"lurch ROBOREDL ROBOREDR step ps 4 64 0 - deadly - fire",
	"fire ROBOREDL ROBOREDR step -s 6 0 0 fire deadly - lurch",
]
const SHOT_ROWS: PackedStringArray = [
	"fly_1 ROBOSHOT1 ROBOSHOT1 step+ -- 8 0 0 glide shot shot fly_2",
	"fly_2 ROBOSHOT2 ROBOSHOT2 step+ -- 8 0 0 glide shot shot fly_1",
	"hit_1 ROBOSHOTHIT1 ROBOSHOTHIT1 step -- 10 0 0 - - - hit_2",
	"hit_2 ROBOSHOTHIT2 ROBOSHOTHIT2 step -- 10 0 0 - - - -",
]
const RISE := Vector2i(0, -0x400)
const PRIORITY := 0
## It looks for Keen only on steps with this bit of its x clear (Omni).
const LOOK_BIT := 0x40
const SHOOT_CHANCE := 0x10
const VOLLEY := 10
## The shot: where it starts (facing right / left) and how it flies; the
## recoil (Omni).
const SHOT_RIGHT := 0x380
const SHOT_LEFT := 0
const SHOT_DROP := 0x200
const SHOT_SPEED := Vector2i(60, 8)
const RECOIL := 0x40

## Shots left in the volley (Omni user1).
var shots := 0


## A Robo Red at [param cell] (info 13, 14, 15), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5RoboRed:
	var robo := Keen5RoboRed.new()
	robo.priority = PRIORITY
	robo.direction = Vector2i(random_side(world), 0)
	robo.place(world, cell, RISE, ROWS, sprites, &"walk")
	return robo


## Think after a step: Keen beside it may set off a volley (Omni
## CK5_RoboMove).
func _think_look() -> void:
	if position.x & LOOK_BIT != 0:
		return
	var keen := _keen()
	if keen.box.bottom <= box.top or keen.box.top >= box.bottom:
		return
	if world.random() < SHOOT_CHANCE:
		_face_keen()
		_continue_as(&"aim")


## Think: one shot of the volley; after the last it walks on (Omni
## CK5_RoboShoot).
func _think_fire() -> void:
	shots -= 1
	if shots == 0:
		_continue_as(&"walk")
	var x := position.x + (SHOT_RIGHT if direction.x == 1 else SHOT_LEFT)
	var up_down := -SHOT_SPEED.y if shots & 1 else SHOT_SPEED.y
	var speed := Vector2i(direction.x * SHOT_SPEED.x, up_down)
	var shot := Keen5Shot.launch(
		world, Vector2i(x, position.y + SHOT_DROP), speed, SHOT_ROWS, sprites, &"fly_1"
	)
	if shot != null:
		world.play_sound(&"enemy_shoot")
		step.x = -RECOIL * direction.x


## Contact: a stunner shot makes it fire back; Keen dies (Omni
## CK5_RoboCol).
func _contact_robo(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		shot.hit()
		_face_keen()
		_become(&"aim")
	elif is_player(other):
		kill_player(other)


func _face_keen() -> void:
	direction.x = -1 if position.x > _keen().position.x else 1
	shots = VOLLEY
