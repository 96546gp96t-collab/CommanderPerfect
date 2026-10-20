class_name Keen4Wormmouth
extends GalaxyCreature
## The Wormmouth of Keen 4 (Omni `ck4_obj2.c`, facts and numbers only;
## docs/keen4/research.md §7): a mound in the ground that slides 16 a tic
## towards Keen (turning at walls and ledges; nothing hurts it there). Far
## from Keen (more than 3 tiles sideways) it sometimes peeks out, looking
## left and right, and goes on his way. When he is within a tile above or
## below and close in front, it bites: only the bite kills, and only when
## Keen is in front of it. Peeking or biting, a shot stuns it for good.

## (Omni CK4_ACT_Wormmouth*.)
const ROWS: PackedStringArray = [
	"move WORMMOUTH_MOUND WORMMOUTH_MOUND slide ps 4 16 0 move - walk move",
	"peek_1 WORMMOUTH_PEEK_L_1 WORMMOUTH_PEEK_L_1 step -- 20 0 0 - shot - peek_2",
	"peek_2 WORMMOUTH_PEEK_L_2 WORMMOUTH_PEEK_L_2 step -- 8 0 0 - shot - peek_3",
	"peek_3 WORMMOUTH_PEEK_L_1 WORMMOUTH_PEEK_L_1 step -- 20 0 0 look_left shot - peek_4",
	"peek_4 WORMMOUTH_MOUND WORMMOUTH_MOUND step -- 8 0 0 - shot - peek_5",
	"peek_5 WORMMOUTH_PEEK_R_1 WORMMOUTH_PEEK_R_1 step -- 20 0 0 - shot - peek_6",
	"peek_6 WORMMOUTH_PEEK_R_2 WORMMOUTH_PEEK_R_2 step -- 8 0 0 - shot - peek_7",
	"peek_7 WORMMOUTH_PEEK_R_1 WORMMOUTH_PEEK_R_1 step -- 20 0 0 look_right shot - peek_8",
	"peek_8 WORMMOUTH_MOUND WORMMOUTH_MOUND step -- 8 0 0 go_to_player - - move",
	"bite_1 WORMMOUTH_BITE_L_1 WORMMOUTH_BITE_R_1 step -- 8 0 0 - bite - bite_2",
	"bite_2 WORMMOUTH_BITE_L_2 WORMMOUTH_BITE_R_2 step -- 8 0 0 - bite - bite_3",
	"bite_3 WORMMOUTH_BITE_L_3 WORMMOUTH_BITE_R_3 step -- 16 0 0 - bite - bite_4",
	"bite_4 WORMMOUTH_BITE_L_2 WORMMOUTH_BITE_R_2 step -- 8 0 0 - bite - bite_5",
	"bite_5 WORMMOUTH_BITE_L_1 WORMMOUTH_BITE_R_1 step -- 8 0 0 - bite - move",
	"stunned WORMMOUTH_STUN WORMMOUTH_STUN think -- 10 0 0 fall - stunned -",
]
## It lies this far below the info tile's corner (Omni).
const DROP := 0x8F
const PRIORITY := 0
## It peeks only when Keen is farther than this sideways, with this chance
## in 256 (Omni).
const PEEK_DISTANCE := 0x300
const PEEK_CHANCE := 6
## It bites when Keen's feet are within this of its own and he is ahead:
## right 128-384 units, left 128-512 (Omni).
const BITE_HEIGHT := 0x100
const BITE_RIGHT := Vector2i(0x80, 0x180)
const BITE_LEFT := Vector2i(-0x200, -0x80)
const STARS := Vector2i(0x40, -350)


## A Wormmouth at [param cell] (info 7, 51, 52).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> Keen4Wormmouth:
	var worm := Keen4Wormmouth.new()
	worm.priority = PRIORITY
	worm.direction = Vector2i(random_side(world), 1)
	worm.stars_offset = STARS
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y) + DROP)
	worm.enter(world, at, ROWS, sprites, &"move")
	return worm


## Think while moving: peek when Keen is far, bite when he is close in
## front (Omni CK4_WormmouthMove).
func _think_move() -> void:
	var keen := world.player()
	var dx := keen.position.x - position.x
	var dy := keen.box.bottom - box.bottom
	if absi(dx) > PEEK_DISTANCE and world.random() < PEEK_CHANCE:
		_continue_as(&"peek_1")
		return
	if absi(dy) > BITE_HEIGHT:
		return
	var ahead := BITE_RIGHT if direction.x == 1 else BITE_LEFT
	if dx > ahead.x and dx < ahead.y:
		world.play_sound(&"wormmouth_bite")
		_continue_as(&"bite_1")


## Think: Keen on the left: it goes left at once (Omni
## CK4_WormmouthLookLeft).
func _think_look_left() -> void:
	if world.player().position.x < position.x:
		direction.x = -1
		_continue_as(&"move")


func _think_look_right() -> void:
	if world.player().position.x > position.x:
		direction.x = 1
		_continue_as(&"move")


func _think_go_to_player() -> void:
	direction.x = 1 if world.player().position.x > position.x else -1


## Contact while peeking: a shot stuns it (Omni CK4_WormmouthCheckShot).
func _contact_shot(other: GalaxyObject) -> void:
	var shot := live_shot(other)
	if shot != null:
		stun(shot, &"stunned")


## Contact while biting: Keen in front of it dies (Omni CK4_WormmouthCol).
func _contact_bite(other: GalaxyObject) -> void:
	if is_player(other):
		var in_front := (
			(direction.x == 1 and position.x <= other.position.x)
			or (direction.x == -1 and position.x >= other.position.x)
		)
		if in_front:
			kill_player()
			return
	_contact_shot(other)
