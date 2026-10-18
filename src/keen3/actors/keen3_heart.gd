class_name Keen3Heart
extends Actor
## The heart of Mortimer's Mangling Machine (info value 13, sprites 146 and
## 147 in turn), as Chocolate Keen has it. Keen's shot splashes on it and
## destroys it, which ends the machine ([method Keen3Machine.hit]); touching
## it does nothing to Keen. Tile 611 on both sides stops the shots until the
## sixth spark is gone.

const FIRST_SPRITE := 146
const FRAMES := 2
## 24 clock ticks (Choco).
const FRAME_TICKS := 9.9
## HEART1's box (0, 0, 15, 15) in EGAHEAD.CK3.
const BOX := Rect2(0, 0, 16, 16)

var _age := 0.0


## The heart in the cell whose top left is [param cell_start].
static func placed(cell_start: Vector2) -> Keen3Heart:
	var heart := Keen3Heart.new()
	heart.position = cell_start
	return heart


func step(_session: LevelSession) -> void:
	_age += 1.0


func sprite_index() -> int:
	return FIRST_SPRITE + floori(_age / FRAME_TICKS) % FRAMES


func hitbox() -> Rect2:
	return Rect2(position + BOX.position, BOX.size)
