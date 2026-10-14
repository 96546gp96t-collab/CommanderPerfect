class_name StoneChain
extends Enemy
## The chain in the last level that holds a big stone above the Vorticon
## commander. One shot breaks it: the stone ([constant STONE_SIZE] tiles,
## just below and around the chain) drops [constant DROP_ROWS] rows, one row
## every [constant DROP_TICKS] ticks, and crushes whatever is under it.
##
## The stone is part of the level's tiles, so dropping it moves those tiles
## down. The row it leaves behind is filled with the tiles that were above
## it.

const SPRITE := 114
## From the sprite table of EGAHEAD.CK1.
const BODY_BOX := Rect2(6, 0, 4, 16)
const STONE_SIZE := Vector2i(9, 2)
## The stone's left column, relative to the chain's cell.
const STONE_OFFSET := Vector2i(-4, 1)
const DROP_ROWS := 4
const DROP_TICKS := 6

var is_dropping := false
var _stone_cell := Vector2i.ZERO
var _rows_dropped := 0
var _timer := 0
var _sky := PackedInt32Array()


static func create(start: Vector2) -> StoneChain:
	var chain := StoneChain.new()
	chain.position = start
	chain.body_box = BODY_BOX
	chain.is_active = true
	chain.falls = false
	return chain


func sprite_index() -> int:
	return -1 if is_dropping else SPRITE


func stops_shots() -> bool:
	return not is_dropping


func touches_keen() -> bool:
	return false


func hit_by_shot(session: LevelSession) -> void:
	if is_dropping:
		return
	is_dropping = true
	var cell := Vector2i((position / EgaGraphics.TILE_SIZE).floor())
	_stone_cell = cell + STONE_OFFSET
	for x in STONE_SIZE.x:
		_sky.append(session.level.tile_at(_stone_cell + Vector2i(x, -1)))


## The stone's area in level pixels.
func stone_rect() -> Rect2:
	return Rect2(_stone_cell * EgaGraphics.TILE_SIZE, STONE_SIZE * EgaGraphics.TILE_SIZE)


func _think(session: LevelSession) -> void:
	if not is_dropping:
		return
	_timer += 1
	if _timer < DROP_TICKS:
		return
	_timer = 0
	_drop_one_row(session)
	session.crush(stone_rect())
	if _rows_dropped >= DROP_ROWS:
		removed = true
		session.play_sound(Sound.Id.SLAM)


func _drop_one_row(session: LevelSession) -> void:
	for x in STONE_SIZE.x:
		for y in range(STONE_SIZE.y, 0, -1):
			var cell := _stone_cell + Vector2i(x, y)
			session.set_tile(cell, session.level.tile_at(cell + Vector2i.UP))
		session.set_tile(_stone_cell + Vector2i(x, 0), _sky[x])
	_stone_cell.y += 1
	_rows_dropped += 1
