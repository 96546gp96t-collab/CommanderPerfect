class_name Keen3Spark
extends Actor
## A spark of Mortimer's Mangling Machine (info value 12, sprites 114-117),
## as Chocolate Keen has it: it stays in its cell and flickers. Keen's shot
## splashes on it and destroys it ([method Keen3Machine.hit]); touching it
## does nothing to Keen.

const FIRST_SPRITE := 114
const FRAMES := 4
## 8 clock ticks (Choco).
const FRAME_TICKS := 3.3
## SPARK1's box (2, 2, 13, 13) in EGAHEAD.CK3.
const BOX := Rect2(2, 2, 12, 12)

var _age := 0.0


## A spark in the cell whose top left is [param cell_start].
static func placed(cell_start: Vector2) -> Keen3Spark:
	var spark := Keen3Spark.new()
	spark.position = cell_start
	return spark


func step(_session: LevelSession) -> void:
	_age += 1.0


func sprite_index() -> int:
	return FIRST_SPRITE + floori(_age / FRAME_TICKS) % FRAMES


func hitbox() -> Rect2:
	return Rect2(position + BOX.position, BOX.size)
