class_name Keen5Spirogrip
extends Keen5Creature
## The Spirogrip of Keen 5 (Omni `ck5_obj3.c`, facts and numbers only;
## docs/keen5/research.md §7): it clings to a floor, wall or ceiling for
## 150 tics, lets go (64 tics at 16 units a tic away from it), and spins,
## eight pictures of 8 tics. At each picture that points straight up,
## right, down or left, with a chance of 21 in 256 (sound "spiro_fly"), it
## flies that way at 48 units a tic to the next wall (sound "spiro_slam")
## and clings there. Touching it kills Keen; a shot is absorbed.

## (Omni CK5_ACT_Spirogrip*.)
const ROWS: PackedStringArray = [
	"cling_down SPIROGRABD SPIROGRABD step -- 150 0 0 - deadly - let_go_down",
	"let_go_down SPIROGRABD SPIROGRABD slide -- 64 0 -16 - deadly - spin_6",
	"cling_left SPIROGRABL SPIROGRABL step -- 150 0 0 - deadly - let_go_left",
	"let_go_left SPIROGRABL SPIROGRABL slide -- 64 16 0 - deadly - spin_8",
	"cling_right SPIROGRABR SPIROGRABR step -- 150 0 0 - deadly - let_go_right",
	"let_go_right SPIROGRABR SPIROGRABR slide -- 64 -16 0 - deadly - spin_4",
	"cling_up SPIROGRABU SPIROGRABU step -- 150 0 0 - deadly - let_go_up",
	"let_go_up SPIROGRABU SPIROGRABU slide -- 64 0 16 - deadly - spin_2",
	"spin_8 SPIROSPINUL SPIROSPINUL step -- 8 0 0 - deadly - spin_1",
	"spin_1 SPIROSPINU SPIROSPINU step -- 8 0 0 spin deadly - spin_2",
	"spin_2 SPIROSPINUR SPIROSPINUR step -- 8 0 0 - deadly - spin_3",
	"spin_3 SPIROSPINR SPIROSPINR step -- 8 0 0 spin deadly - spin_4",
	"spin_4 SPIROSPINDR SPIROSPINDR step -- 8 0 0 - deadly - spin_5",
	"spin_5 SPIROSPIND SPIROSPIND step -- 8 0 0 spin deadly - spin_6",
	"spin_6 SPIROSPINDL SPIROSPINDL step -- 8 0 0 - deadly - spin_7",
	"spin_7 SPIROSPINL SPIROSPINL step -- 8 0 0 spin deadly - spin_8",
	"fly_down SPIROGRABD SPIROGRABD slide -- 0 0 48 - deadly fly cling_down",
	"fly_left SPIROGRABL SPIROGRABL slide -- 0 -48 0 - deadly fly cling_left",
	"fly_right SPIROGRABR SPIROGRABR slide -- 0 48 0 - deadly fly cling_right",
	"fly_up SPIROGRABU SPIROGRABU slide -- 0 0 -48 - deadly fly cling_up",
]
const RISE := Vector2i(0, -0x100)
const PRIORITY := 0
## Above this random number it spins on (Omni).
const FLY_CHANCE := 20
## The straight pictures and where each flies (Omni).
const FLIGHTS: Dictionary[StringName, StringName] = {
	&"spin_1": &"fly_up",
	&"spin_3": &"fly_right",
	&"spin_5": &"fly_down",
	&"spin_7": &"fly_left",
}


## A Spirogrip at [param cell] (info 16, 17, 18), clinging to the floor.
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen5Spirogrip:
	var spirogrip := Keen5Spirogrip.new()
	spirogrip.priority = PRIORITY
	spirogrip.direction = Vector2i(1, 1)
	spirogrip.place(world, cell, RISE, ROWS, sprites, &"cling_down")
	return spirogrip


## Think at a straight picture: now and then it flies off that way (Omni
## CK5_SpirogripSpin).
func _think_spin() -> void:
	if world.random() > FLY_CHANCE:
		return
	world.play_sound(&"spiro_fly")
	if FLIGHTS.has(action.name):
		_continue_as(FLIGHTS[action.name])


## React while flying: any side of a tile, and it clings there (Omni
## CK5_SpirogripFlyDraw).
func _react_fly() -> void:
	if top_hit != 0 or right_hit != 0 or bottom_hit != 0 or left_hit != 0:
		set_action(action.next)
		world.play_sound(&"spiro_slam")
