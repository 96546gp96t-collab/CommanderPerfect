class_name Keen5Korath
extends Keen5Creature
## The Korath of Keen 5 (Omni `ck5_obj3.c`, `ck_keen.c`; facts and numbers
## only; docs/keen5/research.md §7; all 25 live on map 13): it walks 128
## units a step of 8 tics, turning at walls and ledges; at each step, with
## 10 in 256, it stops and faces a random way for 30 tics. It never hurts
## Keen: it pushes him sideways out of its way, and touching him on a pole
## or a ledge knocks him off. A shot stuns it for good.

## (Omni CK5_ACT_Korath*.)
const ROWS: PackedStringArray = [
	"walk_1 KORATHWALKL1 KORATHWALKR1 step -s 8 128 0 walk korath walk walk_2",
	"walk_2 KORATHWALKL2 KORATHWALKR2 step -s 8 128 0 walk korath walk walk_3",
	"walk_3 KORATHWALKL3 KORATHWALKR3 step -s 8 128 0 walk korath walk walk_4",
	"walk_4 KORATHWALKL4 KORATHWALKR4 step -s 8 128 0 walk korath walk walk_1",
	"wait KORATHWAIT KORATHWAIT step -s 30 0 0 - korath walk walk_1",
	"stunned KORATHSTUN KORATHSTUN think -- 0 0 0 fall - stunned -",
]
const RISE := Vector2i(0, -0x80)
const PRIORITY := 0
const STARS := Vector2i(0, -0x80)
const WAIT_CHANCE := 10


## A Korath at [param cell] (info 124), facing a random way.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Korath:
	var korath := Keen5Korath.new()
	korath.priority = PRIORITY
	korath.stars_offset = STARS
	korath.direction = Vector2i(random_side(world), 1)
	korath.place(world, cell, RISE, ROWS, sprites, &"walk_1")
	return korath


## Keen on a pole or a ledge falls off when it touches him (Omni
## CK_KeenSpecialColFunc).
func touched_by_player(player: GalaxyObject, holding: bool) -> void:
	_knock_off(player, holding)


## Think at each step: now and then it waits, facing a random way (Omni
## CK5_KorathWalk).
func _think_walk() -> void:
	if world.random() < WAIT_CHANCE:
		step.x = 0
		direction.x = random_side(world)
		_continue_as(&"wait")


## Contact: Keen (unless dying) is pushed sideways; a shot stuns it (Omni
## CK5_KorathColFunc).
func _contact_korath(other: GalaxyObject) -> void:
	if is_player(other):
		if other.action != null and not other.action.contact.is_empty():
			_push_keen(other)
		return
	var shot := live_shot(other)
	if shot != null:
		stun(shot, &"stunned")
