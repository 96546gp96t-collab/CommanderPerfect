class_name Keen5Sparky
extends Keen5Creature
## The Sparky of Keen 5 (Omni `ck5_obj2.c`, facts and numbers only;
## docs/keen5/research.md §7): it walks 128 units a step, four steps of 8
## tics (16 a tic). At the start of each walk cycle it may stop to search
## (64 in 256): it looks round, eight pictures of 6 tics, and at the fourth
## and the eighth it looks left and right; when Keen is that way, his
## bottom within a tile up or down from its own, it turns to him (sound
## "sparky_prepare_charge"), runs on the spot three times four pictures of
## 4 tics, and then charges at 32 units a tic (the walk sound on its second
## and fourth picture). At a wall or a ledge it steps back, turns round in
## three pictures of 8 tics and waits a random 0-7 frames. Touching it
## kills Keen; a shot stuns it for good.

## (Omni CK5_ACT_Sparky*.)
const ROWS: PackedStringArray = [
	"walk_1 SPARKYL1 SPARKYR1 step -s 8 128 0 wait sparky sparky walk_2",
	"walk_2 SPARKYL2 SPARKYR2 step -s 8 128 0 - sparky sparky walk_3",
	"walk_3 SPARKYL3 SPARKYR3 step -s 8 128 0 - sparky sparky walk_4",
	"walk_4 SPARKYL4 SPARKYR4 step -s 8 128 0 - sparky sparky walk_1",
	"search_1 SPARKYFACEL SPARKYFACEL step -s 6 0 0 - sparky - search_2",
	"search_2 SPARKYFACEF SPARKYFACEF step -s 6 0 0 - sparky - search_3",
	"search_3 SPARKYFACER SPARKYFACER step -s 6 0 0 - sparky - search_4",
	"search_4 SPARKYR1 SPARKYR1 step -s 6 0 0 look_left sparky sparky search_5",
	"search_5 SPARKYFACER SPARKYFACER step -s 6 0 0 - sparky - search_6",
	"search_6 SPARKYFACEF SPARKYFACER step -s 6 0 0 - sparky - search_7",
	"search_7 SPARKYFACEL SPARKYFACER step -s 6 0 0 - sparky - search_8",
	"search_8 SPARKYL1 SPARKYR1 step -s 6 0 0 look_right sparky sparky walk_2",
	"ready_1 SPARKYL1 SPARKYR1 step ps 4 0 0 - sparky sparky ready_2",
	"ready_2 SPARKYL2 SPARKYR2 step ps 4 0 0 - sparky sparky ready_3",
	"ready_3 SPARKYL3 SPARKYR3 step ps 4 0 0 - sparky sparky ready_4",
	"ready_4 SPARKYL4 SPARKYR4 step ps 4 0 0 ready sparky sparky ready_1",
	"charge_1 SPARKYL1 SPARKYR1 step ps 4 128 0 - sparky sparky charge_2",
	"charge_2 SPARKYL2 SPARKYR2 step ps 4 128 0 charge sparky sparky charge_3",
	"charge_3 SPARKYL3 SPARKYR3 step ps 4 128 0 - sparky sparky charge_4",
	"charge_4 SPARKYL4 SPARKYR4 step ps 4 128 0 charge sparky sparky charge_1",
	"turn_1 SPARKYFACER SPARKYFACEL step -s 8 0 0 - sparky - turn_2",
	"turn_2 SPARKYFACEF SPARKYFACEF step -s 8 0 0 - sparky - turn_3",
	"turn_3 SPARKYFACEL SPARKYFACER step -s 8 0 0 - sparky - walk_1",
	"stunned SPARKYSTUN SPARKYSTUN think -- 0 0 0 fall - stunned -",
]
const RISE := Vector2i(0, -0x100)
const PRIORITY := 0
const STARS := Vector2i(0x40, 0)
## The chance in 256 to search at the start of a walk cycle (Omni).
const SEARCH_CHANCE := 0x40
## Keen's bottom within this of its own, up or down: it sees him (Omni:
## unsigned, its bottom − his − 0x100 below 0x200).
const SIGHT_REACH := 0x100
const SIGHT_RANGE := 0x200
## It runs on the spot this many times before it charges (Omni).
const READY_ROUNDS := 3

## Rounds of running on the spot left (Omni user1).
var ready_rounds := 0


## A Sparky at [param cell] (info 4, 5, 6), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Sparky:
	var sparky := Keen5Sparky.new()
	sparky.priority = PRIORITY
	sparky.stars_offset = STARS
	sparky.direction = Vector2i(random_side(world), 1)
	sparky.place(world, cell, RISE, ROWS, sprites, &"walk_1")
	return sparky


## Think at the start of a walk cycle: now and then it stops to search
## (Omni CK5_SparkyWait).
func _think_wait() -> void:
	if world.random() < SEARCH_CHANCE:
		_continue_as(&"search_1")
		step.x = 0


## Think looking left: Keen there makes it charge left (Omni
## CK5_SparkySearchLeft).
func _think_look_left() -> void:
	if _sees_keen() and _keen().position.x < position.x:
		_get_ready(-1)


## Think looking right (Omni CK5_SparkySearchRight).
func _think_look_right() -> void:
	if _sees_keen() and _keen().position.x > position.x:
		_get_ready(1)


## Think after a round on the spot: the last one starts the charge (Omni
## CK5_SparkyPrepareCharge).
func _think_ready() -> void:
	ready_rounds -= 1
	if ready_rounds == 0:
		_continue_as(&"charge_1")


## Think while charging: the footstep (Omni CK5_SparkyCharge0/1).
func _think_charge() -> void:
	world.play_sound(&"keen_walk_1")


## Contact: Keen dies, a shot stuns it (Omni CK5_SparkyCol).
func _contact_sparky(other: GalaxyObject) -> void:
	if is_player(other):
		kill_player(other)
		return
	var shot := live_shot(other)
	if shot != null:
		stun(shot, &"stunned")


## React: a wall ahead or no floor turns it round (Omni CK5_SparkyTileCol).
func _react_sparky() -> void:
	if direction.x == 1 and left_hit != 0:
		_turn_to(-1)
	elif direction.x == -1 and right_hit != 0:
		_turn_to(1)
	elif top_hit == 0:
		_turn_to(-direction.x)


func _turn_to(facing: int) -> void:
	position.x -= moved.x
	direction.x = facing
	think_delay = world.random() / TURN_WAIT_DIVISOR
	set_action(actions[&"turn_1"])


func _sees_keen() -> bool:
	var below := _keen().box.bottom + SIGHT_REACH - box.bottom
	return below >= 0 and below < SIGHT_RANGE


func _get_ready(facing: int) -> void:
	direction.x = facing
	world.play_sound(&"sparky_prepare_charge")
	_continue_as(&"ready_1")
	ready_rounds = READY_ROUNDS
