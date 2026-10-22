class_name GalaxyClip
extends RefCounted
## Moves a [GalaxyObject] by its [member GalaxyObject.step] and keeps it out
## of the solid tiles, by the rules of the original (Omni `ck_phys.c`, facts
## and numbers only; docs/keen4/research.md §4). The foreground tiles' sides
## come from TILEINFO ([GalaxyTileInfo]): top, right, bottom, left, each
## 0 (open), 1 (solid), 2-7 (a slope), 8-15 (deadly, slope value & 7) or
## 17 (a pole hole).
##
## Normal clipping ([method update_normal]):
##   - the move is clamped so nothing crosses a tile in one frame (±239
##     units sideways, −239 … +255 down);
##   - an object that sticks to the ground is pushed down by its sideways
##     move + 16 (145 on a platform) and stays where it was when no floor
##     catches it;
##   - floors and ceilings are looked for only under the **middle column**
##     of the box; on a slope the object rests on the slope's height at
##     that pixel ([method slope_height]); it is lifted at most as far as
##     it moved (plus 16 units), so it never pops through a floor;
##   - the player also checks the floor and ceiling at the leading corner
##     of his box, so he lands on the edge of a flat tile;
##   - walls: the left and right columns of the box over its rows (without
##     the bottom row on a slope, the top row under a sloped ceiling) push
##     it out by whole tiles.
## Simple clipping ([method update_simple_box]): a fixed box that is moved
## back along x, then y, until it is inside no solid tile.

## The height of each slope per pixel column, in units from the top of the
## tile (Omni ck_physSlopeHeight): every row of the original's table is a
## straight line, start + step × column (column 0-15), by slope value: 0
## unused, 1 flat, 2/3 gently down to the right (upper / lower half), 4
## steeply down, 5/6 gently up (lower / upper half), 7 steeply up.
const SLOPE_START: PackedInt32Array = [256, 0, 0, 128, 0, 120, 248, 240]
const SLOPE_STEP: PackedInt32Array = [0, 0, 8, 8, 16, -8, -8, -16]
## The slope value of a side: deadly floors (8-15) slope like value & 7.
const SLOPE_MASK := 7
const FLAT := 1
const LAST_COLUMN := 15
## The largest move in one frame (Omni).
const MAX_SIDEWAYS := 239
const MAX_UP := 239
const MAX_DOWN := 255
## The same for a simple box, also downwards.
const MAX_SIMPLE := 239
## How far a sticking object is pushed down besides its sideways move,
## and on a platform (Omni).
const GROUND_PUSH := 16
const PLATFORM_PUSH := 145
## A floor or ceiling found under the middle may lift or lower the object
## this much more than it moved (Omni).
const CLIP_SLACK := 16
const TILE := GalaxyUnits.PER_TILE

var map: GalaxyMap
var tile_info: GalaxyTileInfo


static func create(level_map: GalaxyMap, info: GalaxyTileInfo) -> GalaxyClip:
	var clip := GalaxyClip.new()
	clip.map = level_map
	clip.tile_info = info
	return clip


## The foreground tile at ([param x], [param y]); 0 outside the map.
func tile_at(x: int, y: int) -> int:
	return map.tile(GalaxyMap.Layer.FOREGROUND, x, y)


func top_of(tile: int) -> int:
	return tile_info.fore(GalaxyTileInfo.Fore.TOP, tile)


func bottom_of(tile: int) -> int:
	return tile_info.fore(GalaxyTileInfo.Fore.BOTTOM, tile)


func left_of(tile: int) -> int:
	return tile_info.fore(GalaxyTileInfo.Fore.LEFT, tile)


func right_of(tile: int) -> int:
	return tile_info.fore(GalaxyTileInfo.Fore.RIGHT, tile)


## Whether [param tile] is solid on any side.
func is_solid(tile: int) -> bool:
	return top_of(tile) != 0 or bottom_of(tile) != 0 or left_of(tile) != 0 or right_of(tile) != 0


## Moves [param object] by its step with normal clipping (Omni
## CK_PhysUpdateNormalObj); see the class description.
func update_normal(object: GalaxyObject) -> void:
	var start := object.position
	var sticks := object.action != null and object.action.stick_to_ground
	var off_platform := false
	if sticks:
		if object.top_hit == GalaxyObject.ON_PLATFORM:
			object.step.y = PLATFORM_PUSH
		else:
			object.step.y = absi(object.step.x) + GROUND_PUSH
			off_platform = true
	object.step.x = clampi(object.step.x, -MAX_SIDEWAYS, MAX_SIDEWAYS)
	object.step.y = clampi(object.step.y, -MAX_UP, MAX_DOWN)
	object.position += object.step
	object.needs_react = true
	if object.sprite == GalaxyObject.NO_SPRITE:
		return
	var old := object.box.copy()
	object.reset_box()
	object.top_hit = 0
	object.bottom_hit = 0
	object.left_hit = 0
	object.right_hit = 0
	if object.clip != GalaxyObject.Clip.NONE:
		var delta := _delta(old, object.box)
		_clip_vertical(object, old, delta)
		if object.clips_like_keen:
			if object.top_hit == 0 and delta.bottom > 0:
				_land_on_corner(object, delta)
			if object.bottom_hit == 0 and delta.top < 0:
				_bump_corner(object, delta)
		_clip_walls(object)
	if object.top_hit == 0 and off_platform:
		# No floor caught it: it stays on its row (it does not walk off).
		object.position = Vector2i(start.x + object.step.x, start.y)
		object.reset_box()
	object.moved += object.position - start


## Moves [param object] by its step, clipped but without the clamp and the
## ground rules, and without forgetting what it hit before (Omni
## CK_PhysUpdateSimpleObj: riding and being pushed).
func update_simple(object: GalaxyObject) -> void:
	var start := object.position
	object.position += object.step
	object.needs_react = true
	if object.sprite == GalaxyObject.NO_SPRITE:
		return
	var old := object.box.copy()
	object.reset_box()
	if object.clip != GalaxyObject.Clip.NONE:
		_clip_vertical(object, old, _delta(old, object.box))
		_clip_walls(object)
	object.moved += object.position - start


## Moves an object with a fixed box ([member GalaxyObject.simple_box_size])
## so that the box is in no solid tile: back along x first, then along y
## (Omni CK_PhysFullClipToWalls).
func update_simple_box(object: GalaxyObject) -> void:
	var start := object.position
	object.step = object.step.clamp(
		-Vector2i(MAX_SIMPLE, MAX_SIMPLE), Vector2i(MAX_SIMPLE, MAX_SIMPLE)
	)
	object.position += object.step
	object.needs_react = true
	var simple := object.box
	simple.left = object.position.x
	simple.top = object.position.y
	simple.right = object.position.x + object.simple_box_size.x
	simple.bottom = object.position.y + object.simple_box_size.y
	_retile(simple)
	object.top_hit = 0
	object.bottom_hit = 0
	object.left_hit = 0
	object.right_hit = 0
	if is_stuck(object):
		_move_x(object, -object.step.x)
		if not is_stuck(object):
			_hit_side(object)
		else:
			if object.step.y > 0:
				object.top_hit = FLAT
			else:
				object.bottom_hit = FLAT
			_move_x(object, object.step.x)
			_move_y(object, -object.step.y)
			if is_stuck(object):
				_move_x(object, -object.step.x)
				_hit_side(object)
	object.moved += object.position - start
	# The box follows the sprite again; its tiles stay those of the simple
	# box (Omni).
	var info := object.world.sprite_info(object.sprite)
	if info != null:
		simple.left = object.position.x + info.box_left
		simple.right = object.position.x + info.box_right
		simple.top = object.position.y + info.box_top
		simple.bottom = object.position.y + info.box_bottom
		simple.middle = (simple.right - simple.left) / 2 + simple.left


## Whether any tile under [param object]'s box is solid on any side.
func is_stuck(object: GalaxyObject) -> bool:
	var box := object.box
	for y in range(box.tile_top, box.tile_bottom + 1):
		for x in range(box.tile_left, box.tile_right + 1):
			if is_solid(tile_at(x, y)):
				return true
	return false


## The height of [param side]'s slope at pixel [param column] of a tile.
static func slope_height(side: int, column: int) -> int:
	var slope := side & SLOPE_MASK
	return SLOPE_START[slope] + SLOPE_STEP[slope] * column


## Floors under the middle column (searched downwards from the row above
## where the box ended before), then ceilings (upwards).
func _clip_vertical(object: GalaxyObject, old: GalaxyObject.Box, delta: GalaxyObject.Box) -> void:
	var box := object.box
	var column := GalaxyUnits.to_pixel(box.middle) & LAST_COLUMN
	var lowest := -absi(delta.middle) - delta.bottom - CLIP_SLACK
	var row := old.tile_bottom - 1
	while row <= box.tile_bottom:
		var top := top_of(tile_at(box.tile_middle, row))
		if top != 0:
			var lift := slope_height(top, column) - (box.bottom - row * TILE) - 1
			if lift < 0 and lift >= lowest:
				object.top_hit = top
				_move_y(object, lift)
				return
		row += 1
	var highest := absi(delta.middle) - delta.top + CLIP_SLACK
	row = old.tile_top + 1
	while row >= box.tile_top:
		var bottom := bottom_of(tile_at(box.tile_middle, row))
		if bottom != 0:
			var drop := -slope_height(bottom, column) - (box.top - (row + 1) * TILE)
			var total := object.step.y + drop
			if drop > 0 and drop <= highest and total < TILE and total > -TILE:
				object.bottom_hit = bottom
				_move_y(object, drop)
		row -= 1


## Walls at the box's left and right columns, over its rows.
func _clip_walls(object: GalaxyObject) -> void:
	var box := object.box
	var first := box.tile_top
	var last := box.tile_bottom
	if object.top_hit > FLAT:
		last -= 1
	if object.bottom_hit > FLAT:
		first += 1
	for y in range(first, last + 1):
		object.right_hit = right_of(tile_at(box.tile_left, y))
		if object.right_hit != 0:
			_move_x(object, (box.tile_left + 1) * TILE - box.left)
			return
	for y in range(first, last + 1):
		object.left_hit = left_of(tile_at(box.tile_right, y))
		if object.left_hit != 0:
			_move_x(object, box.tile_right * TILE - 1 - box.right)
			return


## The player lands on a flat tile under the leading corner of his box
## when nothing blocks it, and moves so far that his middle is above it
## (Omni CK_PhysKeenClipDown).
func _land_on_corner(object: GalaxyObject, delta: GalaxyObject.Box) -> void:
	var box := object.box
	var right := object.direction.x == 1
	var column := box.tile_right if right else box.tile_left
	var row := box.tile_bottom
	if _blocks(column, row - 2, right) or _blocks(column, row - 1, right):
		return
	if top_of(tile_at(column, row - 1)) != 0 or top_of(tile_at(column, row)) != FLAT:
		return
	# A flat top lies on the tile's first unit row.
	var lift := row * TILE - 1 - box.bottom
	if lift <= 0 and -delta.bottom <= lift:
		object.top_hit = FLAT
		_move_y(object, lift)
		_move_x(object, (box.right if right else box.left) - box.middle)


## The player bumps a ceiling above the leading corner of his box (Omni
## CK_PhysKeenClipUp).
func _bump_corner(object: GalaxyObject, delta: GalaxyObject.Box) -> void:
	var box := object.box
	var right := object.direction.x == 1
	var column := box.tile_right if right else box.tile_left
	var row := box.tile_top
	if _blocks(column, row + 2, right) or _blocks(column, row + 3, right):
		return
	if bottom_of(tile_at(column, row + 1)) != 0:
		return
	var ceiling := bottom_of(tile_at(column, row))
	if ceiling == 0:
		return
	var edge := 0 if right else LAST_COLUMN
	var drop := (row + 1) * TILE - slope_height(ceiling, edge) - box.top
	if drop >= 0 and -delta.top >= drop:
		object.bottom_hit = ceiling
		_move_y(object, drop)


## Whether the tile at ([param x], [param y]) is a wall for something
## moving right ([param right]) or left.
func _blocks(x: int, y: int, right: bool) -> bool:
	var tile := tile_at(x, y)
	return (left_of(tile) if right else right_of(tile)) != 0


## A side hit after being moved back along x: the wall is ahead.
func _hit_side(object: GalaxyObject) -> void:
	if object.step.x > 0:
		object.left_hit = FLAT
	else:
		object.right_hit = FLAT


## Moves along x; the middle column stays where it was (Omni: only Keen 6
## moves it).
static func _move_x(object: GalaxyObject, dx: int) -> void:
	object.position.x += dx
	object.box.left += dx
	object.box.right += dx
	object.box.tile_left = GalaxyUnits.to_tile(object.box.left)
	object.box.tile_right = GalaxyUnits.to_tile(object.box.right)


static func _move_y(object: GalaxyObject, dy: int) -> void:
	object.position.y += dy
	object.box.top += dy
	object.box.bottom += dy
	object.box.tile_top = GalaxyUnits.to_tile(object.box.top)
	object.box.tile_bottom = GalaxyUnits.to_tile(object.box.bottom)


## How far each edge moved from [param old] to [param new] (as a box).
static func _delta(old: GalaxyObject.Box, new: GalaxyObject.Box) -> GalaxyObject.Box:
	var delta := GalaxyObject.Box.new()
	delta.left = new.left - old.left
	delta.top = new.top - old.top
	delta.right = new.right - old.right
	delta.bottom = new.bottom - old.bottom
	delta.middle = new.middle - old.middle
	return delta


static func _retile(box: GalaxyObject.Box) -> void:
	box.tile_left = GalaxyUnits.to_tile(box.left)
	box.tile_right = GalaxyUnits.to_tile(box.right)
	box.tile_top = GalaxyUnits.to_tile(box.top)
	box.tile_bottom = GalaxyUnits.to_tile(box.bottom)
