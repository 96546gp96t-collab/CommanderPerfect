class_name Keen4Mine
extends GalaxyPlatform
## A mine of Keen 4's Well of Wishes (info 69-72: up, right, down, left;
## Omni `ck4_obj3.c`, CK4_SpawnMine and CK4_MineCol, facts and numbers only;
## docs/keen4/research.md §7): it moves like a platform ([GalaxyPlatform]:
## 12 units a tic, turning at turn points), always awake, behind everything.
## Touching Keen it explodes (two pictures of 30 tics, then it is gone) and
## kills him; Keen cannot ride it.

## (Omni CK4_ACT_Mine0, CK4_ACT_MineExplode0-1.)
const ROWS: PackedStringArray = [
	"move MINE MINE think -- 0 0 0 axis mine - -",
	"explode_1 MINE_BOOM_1 MINE_BOOM_1 step -- 30 0 0 - - - explode_2",
	"explode_2 MINE_BOOM_2 MINE_BOOM_2 step -- 30 0 0 - - - -",
]


## A mine at [param cell] moving towards [param heading] (0 up, 1 right,
## 2 down, 3 left).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, heading: int, sprites: Dictionary[StringName, int]
) -> Keen4Mine:
	var mine := Keen4Mine.new()
	mine.place_moving(world, cell, heading, ROWS, sprites, &"move")
	return mine


## Keen cannot stand on a mine.
func touched_by_player(_player: GalaxyObject, _holding: bool) -> void:
	pass


## Contact: Keen sets it off (Omni CK4_MineCol).
func _contact_mine(other: GalaxyObject) -> void:
	if not is_player(other):
		return
	_become(&"explode_1")
	kill_player()
