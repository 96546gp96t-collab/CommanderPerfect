class_name Keen5Shockshund
extends Keen5Creature
## The Shockshund of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it runs 128 units a step of 8 tics; every
## fourth step (32 tics) it faces Keen and then:
##   - with 16 in 256 it sits, two pictures of 8 tics, 16 times (256 tics);
##   - with Keen's bottom not level with its own it jumps (40 sideways, −40
##     up, gravity high) ...
##   - ... but with 128 in 256 it barks instead, which wins over the jump
##     (the original's order): two pictures of 8 tics and a shot
##     ([Keen5Shot], 60 sideways, sound "shockshund_bark") that a stunner
##     shot stops.
## At a wall it turns; at a ledge it jumps when it faces Keen, otherwise it
## turns (waiting a random 0-7 frames). Touching it kills Keen. It has 2 hit
## points: the first shot makes it flash white, the second stuns it.

## (Omni CK5_ACT_Shocksund*, CK5_ACT_BarkShot*.)
const ROWS: PackedStringArray = [
	"sit_1 PETSIT1 PETSIT1 step -s 8 0 0 - shockshund ground sit_2",
	"sit_2 PETSIT2 PETSIT2 step -s 8 0 0 sit shockshund ground sit_1",
	"bark_1 PETBARKL1 PETBARKR1 step -s 8 0 0 - shockshund ground bark_2",
	"bark_2 PETBARKL2 PETBARKR2 step -s 8 0 0 bark shockshund ground run_1",
	"run_1 PETRUNL1 PETRUNR1 step -s 8 128 0 - shockshund ground run_2",
	"run_2 PETRUNL2 PETRUNR2 step -s 8 128 0 - shockshund ground run_3",
	"run_3 PETRUNL3 PETRUNR3 step -s 8 128 0 - shockshund ground run_4",
	"run_4 PETRUNL4 PETRUNR4 step -s 8 128 0 search shockshund ground run_1",
	"jump PETJUMPL PETJUMPR think -- 8 128 0 fall shockshund jump run_2",
	"stunned PETSTUN PETSTUN think -- 0 0 0 fall - stunned -",
]
const SHOT_ROWS: PackedStringArray = [
	"fly_1 PETSPARK1 PETSPARK1 step+ -- 8 0 0 glide shot shot fly_2",
	"fly_2 PETSPARK2 PETSPARK2 step+ -- 8 0 0 glide shot shot fly_1",
	"hit_1 PETSPARKHIT1 PETSPARKHIT1 step -- 10 0 0 - - - hit_2",
	"hit_2 PETSPARKHIT2 PETSPARKHIT2 step -- 10 0 0 - - - -",
]
const RISE := Vector2i(0, -0x80)
const PRIORITY := 0
const HEALTH := 2
## Chances in 256 (Omni): sitting, barking.
const SIT_CHANCE := 0x10
const BARK_CHANCE := 0x80
## It sits this many rounds of two pictures (Omni).
const SIT_ROUNDS := 0x10
const JUMP_SPEED := Vector2i(40, -40)
## The bark: where it starts (facing right / left), its speed (Omni).
const SHOT_RIGHT := 0x70
const SHOT_LEFT := 0
const SHOT_DROP := 0x40
const SHOT_SPEED := 60

## Shots it can still take (Omni user2), rounds left to sit (Omni user1).
var health := HEALTH
var sit_rounds := 0


## A Shockshund at [param cell] (info 102, 103, 104), running right.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Shockshund:
	var dog := Keen5Shockshund.new()
	dog.priority = PRIORITY
	dog.direction = Vector2i(1, 1)
	dog.place(world, cell, RISE, ROWS, sprites, &"run_1")
	return dog


## Think every fourth step: it faces Keen, and sits, jumps or barks (Omni
## CK5_ShocksundSearch).
func _think_search() -> void:
	var keen := _keen()
	direction.x = -1 if position.x > keen.position.x else 1
	if world.random() < SIT_CHANCE:
		step.x = 0
		_continue_as(&"sit_1")
		sit_rounds = SIT_ROUNDS
		return
	if box.bottom != keen.box.bottom:
		_continue_as(&"jump")
		velocity = Vector2i(direction.x * JUMP_SPEED.x, JUMP_SPEED.y)
	if world.random() < BARK_CHANCE:
		step.x = 0
		_continue_as(&"bark_1")


## Think while sitting: after its rounds it runs on (Omni
## CK5_ShocksundStand).
func _think_sit() -> void:
	sit_rounds -= 1
	if sit_rounds == 0:
		_continue_as(&"run_1")


## Think: the bark's shot (Omni CK5_ShocksundShoot).
func _think_bark() -> void:
	var x := position.x + (SHOT_RIGHT if direction.x == 1 else SHOT_LEFT)
	var shot := Keen5Shot.launch(
		world,
		Vector2i(x, position.y + SHOT_DROP),
		Vector2i(direction.x * SHOT_SPEED, 0),
		SHOT_ROWS,
		sprites,
		&"fly_1"
	)
	if shot != null:
		shot.direction.x = direction.x
		shot.meets_stunner = true
		shot.hit_sound = &"bark_shot_die"
		world.play_sound(&"shockshund_bark")


## Contact: Keen dies; a shot costs a hit point and flashes it, the last one
## stuns it (Omni CK5_ShocksundCol).
func _contact_shockshund(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
	var shot := live_shot(other)
	if shot == null:
		return
	health -= 1
	if health != 0:
		_flash_hit(shot)
	else:
		velocity = Vector2i.ZERO
		stun(shot, &"stunned")


## React on the ground: walls turn it, at a ledge it jumps towards Keen or
## turns; it flashes (Omni CK5_ShocksundGroundTileCol).
func _react_ground() -> void:
	if direction.x == 1 and left_hit != 0:
		_turn_round(-1)
	elif direction.x == -1 and right_hit != 0:
		_turn_round(1)
	elif top_hit == 0:
		var keen := _keen()
		var facing_keen := (
			(direction.x == 1 and keen.position.x > position.x)
			or (direction.x == -1 and keen.position.x < position.x)
		)
		if facing_keen:
			_become(&"jump")
			velocity = Vector2i(direction.x * JUMP_SPEED.x, JUMP_SPEED.y)
		else:
			_turn_round(-direction.x)
	_show_flash()


## React in a jump: landing it runs on, after a random 0-7 frames; it
## flashes (Omni CK5_ShocksundJumpTileCol).
func _react_jump() -> void:
	if top_hit != 0:
		think_delay = world.random() / TURN_WAIT_DIVISOR
		_become(&"run_1")
	_show_flash()
