class_name Keen3Messie
extends Actor
## Messie, the sea monster of Keen 3's world map, as Chocolate Keen has her
## (`episodes/episode3.c:CVort3_do_messie`, `game/worldmap.c`;
## docs/keen3/research.md §8). [Keen3MapSession] moves her every tick; the
## [ActorLayer] draws her.
##
## She swims along the cells with info 0x2000 (her path, a closed loop) and
## 0x2100 (weed), from cell to cell, 2 px per frame of the original on each
## axis of her direction (8 frames per cell). In a new game she starts at
## the first row whose middle column holds her path, heading left. Each
## time she reaches a cell she takes the first neighbour, column by column
## (x - 1, x, x + 1) and in each column row by row (y - 1, y, y + 1), that
## is path or weed and is neither her own cell nor the one she came from.
## Before swimming into weed she waits 122 frames (~5 s), already facing it.
## Without such a neighbour she stays where she is (the original's maps
## never get there).
##
## Keen gets on when his sprite's top left lies inside her picture (32x24,
## edges included) and the lock after his last ride is over; she then
## carries him ([member carrying]) and her pictures show him on her back.
## He gets off by pressing a direction (one of eight) toward a neighbour of
## her cell (the cell of her top left) that is a landing (0x2200); after
## that she cannot be mounted for 30 frames.

## Her pictures by the direction she swims in; 4 is "standing". Index:
## (dy + 1) * 3 + (dx + 1). Each has a second picture right after it.
const SPRITES: PackedInt32Array = [136, 136, 134, 130, 130, 132, 130, 132, 132]
## The same pictures with Keen on her back are this much further on.
const CARRYING_OFFSET := 8
## Her second picture shows every other two frames.
const FRAMES_PER_PICTURE := 2.0
const PICTURES := 2
const SIZE := Vector2(32, 24)
const CELL := EgaGraphics.TILE_SIZE
## Pixels per tick on each axis of her direction: 2 px per frame (Choco).
const SWIM_SPEED := 2.0 * Keen3MapInfo.FRAMES_PER_TICK
## How long she waits before a weed cell: 122 frames (Choco: 130 minus the
## 8 of the move).
const WEED_WAIT_FRAMES := 122.0
## How long after Keen gets off before he can get on again: 30 frames.
const CLIMB_LOCK_FRAMES := 30.0

## The cell she left last (her top left is its top left plus her progress).
var cell := Vector2i.ZERO
## The step to the next cell (each axis -1, 0 or 1); zero while she stands.
var direction := Vector2i.LEFT
## Whether Keen rides on her back.
var carrying := false
var _came_from := Vector2i.ZERO
var _travelled := 0.0
var _wait_ticks := 0.0
var _lock_ticks := 0.0
var _frames := 0.0


## Messie at her start on [param map], or null when the map has no path in
## its middle column.
static func from_map(map: LevelData) -> Keen3Messie:
	var column := map.width / 2
	for row in map.height:
		if map.info_at(Vector2i(column, row)) == Keen3MapInfo.PATH:
			return at_cell(Vector2i(column, row), Vector2i.LEFT)
	return null


## Messie in [param start_cell], about to swim [param heading].
static func at_cell(start_cell: Vector2i, heading: Vector2i) -> Keen3Messie:
	var messie := Keen3Messie.new()
	messie.cell = start_cell
	messie._came_from = start_cell
	messie.direction = heading
	messie.position = Vector2(start_cell * CELL)
	return messie


## Swims one tick on [param map].
func swim(map: LevelData) -> void:
	_frames += Keen3MapInfo.FRAMES_PER_TICK
	if not carrying and _lock_ticks > 0.0:
		_lock_ticks -= 1.0
	if _wait_ticks > 0.0:
		_wait_ticks -= 1.0
		return
	if direction == Vector2i.ZERO:
		return
	_travelled += SWIM_SPEED
	if _travelled >= CELL:
		_travelled -= CELL
		cell += direction
		_choose_next(map)
	position = Vector2(cell * CELL) + Vector2(direction) * _travelled


## Whether she is waiting before a weed cell.
func is_waiting() -> bool:
	return _wait_ticks > 0.0


## Whether Keen, with his sprite's top left at [param keen_at], gets on.
func can_carry(keen_at: Vector2) -> bool:
	if carrying or _lock_ticks > 0.0:
		return false
	var inside := keen_at - position
	return inside.x >= 0 and inside.y >= 0 and inside.x <= SIZE.x and inside.y <= SIZE.y


func take_on() -> void:
	carrying = true


## The landing that Keen gets off at when he presses [param toward] (each
## axis -1, 0 or 1), or (-1, -1) when there is none that way.
func landing_toward(map: LevelData, toward: Vector2i) -> Vector2i:
	if toward == Vector2i.ZERO:
		return Vector2i(-1, -1)
	var target := Vector2i((position / CELL).floor()) + toward
	if not _is_inside(map, target) or map.info_at(target) != Keen3MapInfo.LANDING:
		return Vector2i(-1, -1)
	return target


## Keen gets off toward [param toward]: returns the top left of his sprite,
## one cell from hers that way. She cannot be mounted for a while.
func put_off(toward: Vector2i) -> Vector2:
	carrying = false
	_lock_ticks = Keen3MapInfo.ticks_for_frames(CLIMB_LOCK_FRAMES)
	return position + Vector2(toward * CELL)


func sprite_index() -> int:
	var index := (direction.y + 1) * 3 + direction.x + 1
	var picture := int(_frames / FRAMES_PER_PICTURE) % PICTURES
	return SPRITES[index] + (CARRYING_OFFSET if carrying else 0) + picture


func hitbox() -> Rect2:
	return Rect2(position, SIZE)


## Takes the first neighbour of [member cell] that she can swim to, and
## waits first when it is weed.
func _choose_next(map: LevelData) -> void:
	var here := cell
	for x in range(here.x - 1, here.x + 2):
		for y in range(here.y - 1, here.y + 2):
			var next := Vector2i(x, y)
			if next == here or next == _came_from or not _is_inside(map, next):
				continue
			var info := map.info_at(next)
			if not Keen3MapInfo.is_water_path(info):
				continue
			direction = next - here
			_came_from = here
			if info == Keen3MapInfo.WEED:
				_wait_ticks = Keen3MapInfo.ticks_for_frames(WEED_WAIT_FRAMES)
				_travelled = 0.0
			return
	direction = Vector2i.ZERO
	_travelled = 0.0


static func _is_inside(map: LevelData, at: Vector2i) -> bool:
	return at.x >= 0 and at.y >= 0 and at.x < map.width and at.y < map.height
