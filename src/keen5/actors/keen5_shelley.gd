class_name Keen5Shelley
extends Keen5Creature
## The Shelley of Keen 5 (Omni `ck5_obj2.c`, facts and numbers only;
## docs/keen5/research.md §7; the original gives it the Sparky's class
## number): it walks 128 units a step, four steps of 8 tics, turning at
## walls. At a ledge it waits up to 100 tics; when Keen is below it and
## between one and three tiles ahead (his middle from its middle), it dives
## off (16 sideways, −24 up, gravity high); otherwise it turns round. It
## explodes (sound "shelley_explode"):
##   - when a stunner shot or **an enemy shot** ([Keen5Shot]) touches it;
##   - when it lands from a dive;
##   - when Keen's middle is inside its box (otherwise it only pushes him
##     sideways).
## Exploding it shows its last picture for 8 tics and is gone, throwing two
## pieces ([Keen5Piece]: 32 sideways each way, −24 up, bouncing); where it
## was a blast shows four pictures of 20 tics. The blast and the pieces kill
## Keen; the Shelley itself never does.

## (Omni CK5_ACT_Shelly*, CK5_ACT_ShellyExplode*, CK5_ACT_ShellyBits*.)
const ROWS: PackedStringArray = [
	"walk_1 SHELLEYL1 SHELLEYR1 step -s 8 128 0 - shelley ground walk_2",
	"walk_2 SHELLEYL2 SHELLEYR2 step -s 8 128 0 - shelley ground walk_3",
	"walk_3 SHELLEYL3 SHELLEYR3 step -s 8 128 0 - shelley ground walk_4",
	"walk_4 SHELLEYL4 SHELLEYR4 step -s 8 128 0 - shelley ground walk_1",
	"wait SHELLEYL2 SHELLEYR2 step+ -s 100 0 0 wait shelley - give_up",
	"give_up SHELLEYL2 SHELLEYR2 step ps 1 0 0 turn shelley - walk_1",
	"dive_1 SHELLEYJUMPL SHELLEYJUMPR step+ -- 8 0 0 fall shelley air dive_2",
	"dive_2 SHELLEYFALLL SHELLEYFALLR think -- 8 0 0 fall shelley air -",
	"die_air SHELLEYFALLL SHELLEYFALLR step -- 8 0 0 pieces - air -",
	"die_ground SHELLEYL2 SHELLEYR2 step -- 8 0 0 pieces - air -",
	"blast_1 SHELLEYBOOM1 SHELLEYBOOM1 step -- 20 0 0 - deadly - blast_2",
	"blast_2 SHELLEYBOOM2 SHELLEYBOOM2 step -- 20 0 0 - deadly - blast_3",
	"blast_3 SHELLEYBOOM3 SHELLEYBOOM3 step -- 20 0 0 - deadly - blast_4",
	"blast_4 SHELLEYBOOM4 SHELLEYBOOM4 step -- 20 0 0 - deadly - -",
	"piece_1 SHELLEYPIECE1 SHELLEYPIECE1 think -- 8 0 0 fall piece shrapnel -",
	"piece_2 SHELLEYPIECE2 SHELLEYPIECE2 think -- 8 0 0 fall piece shrapnel -",
]
const PRIORITY := 0
## The dive: Keen's middle this far ahead of its own, more than the near
## and less than the far one; its speed (Omni).
const DIVE_NEAR := 0x100
const DIVE_FAR := 0x300
const DIVE_SPEED := Vector2i(16, -24)
## The two pieces and their speeds (Omni).
const PIECES: Array[StringName] = [&"piece_1", &"piece_2"]
const PIECE_SPEEDS: Array[Vector2i] = [Vector2i(32, -24), Vector2i(-32, -24)]


## A Shelley at [param cell] (info 74, 75, 76), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Shelley:
	var shelley := Keen5Shelley.new()
	shelley.priority = PRIORITY
	shelley.direction = Vector2i(random_side(world), 1)
	shelley.place(world, cell, Vector2i.ZERO, ROWS, sprites, &"walk_1")
	return shelley


## Think at a ledge: Keen below and ahead makes it dive (Omni
## CK5_ShellyWait).
func _think_wait() -> void:
	var keen := _keen()
	if keen.box.top < box.bottom:
		return
	var ahead := (keen.box.middle - box.middle) * direction.x
	if ahead > DIVE_NEAR and ahead < DIVE_FAR:
		velocity = Vector2i(DIVE_SPEED.x * direction.x, DIVE_SPEED.y)
		_continue_as(&"dive_1")
		step = Vector2i.ZERO


## Think after waiting in vain: it turns round (Omni CK5_ShellyStartJump).
func _think_turn() -> void:
	direction.x = -direction.x


## Think when it has exploded: its two pieces fly off (Omni
## CK5_SpawnShellyBits).
func _think_pieces() -> void:
	for index in PIECES.size():
		Keen5Piece.throw(world, position, PIECE_SPEEDS[index], ROWS, sprites, PIECES[index])


## Contact: Keen is pushed, and makes it explode when his middle is inside
## its box; a stunner shot or an enemy shot makes it explode (Omni
## CK5_ShellyCol).
func _contact_shelley(other: GalaxyObject) -> void:
	if is_player(other):
		_push_keen(other)
		var middle := other.box.middle
		if middle < box.left or middle > box.right:
			return
	elif live_shot(other) != null:
		live_shot(other).hit()
	elif other is Keen5Shot and (other as Keen5Shot).is_enemy_shot:
		world.remove(other)
	else:
		return
	_explode(&"die_air" if top_hit == 0 else &"die_ground")


## React on the ground: walls turn it, a ledge makes it wait (Omni
## CK5_ShellyGroundTileCol).
func _react_ground() -> void:
	if direction.x == 1 and left_hit != 0:
		position.x -= moved.x
		direction.x = -1
	elif direction.x == -1 and right_hit != 0:
		position.x -= moved.x
		direction.x = 1
	elif top_hit == 0:
		position.x -= moved.x
		_become(&"wait")


## React in the air: walls stop it sideways, landing makes it explode (Omni
## CK5_ShellyAirTileCol).
func _react_air() -> void:
	if right_hit != 0 or left_hit != 0:
		velocity.x = 0
	if top_hit != 0:
		_explode(&"die_air")


## It explodes: its sound, its dying picture, and a blast where it is.
func _explode(dying: StringName) -> void:
	world.play_sound(&"shelley_explode")
	_become(dying)
	var blast := Keen5Creature.new()
	blast.priority = PRIORITY
	blast.direction = Vector2i.ZERO
	blast.enter(world, position, ROWS, sprites, &"blast_1")
