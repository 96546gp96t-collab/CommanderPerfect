class_name GalaxyCamera
extends RefCounted
## Where the view of a Galaxy level is, by the original's rules, in global
## units (16 per pixel, 256 per tile). Only numbers: the view's camera node
## is put where [method view_rect] says.
##
## The original's view is 20 × 13 tiles (320 × 208 pixels, of which the top
## 200 are shown). It never shows the 2-tile border of the map, nor
## anything beyond a **scroll block**: a column of the map that the view
## never scrolls over (Keen 4: info 26), or a row (info 25). The map's
## border is four such blocks: columns 1 and width − 2, rows 1 and
## height − 2 (Omni `id_rf.c:RF_NewMap`).
##   - [method reposition] (Omni RF_RepositionLimit) puts the view at a
##     place, inside the map's edges, then moves it off the first block it
##     covers: to its right (below it) when the block is in the left (top)
##     half of the view, otherwise to its left (above it).
##   - [method smooth_scroll] (Omni RFL_SmoothScrollLimit) moves the view;
##     when its leading edge reaches a block it stops on the tile edge.
##   - [method centre_on] (Omni `ck_play.c:CK_CentreCamera`) puts Keen 152
##     pixels from the left and his feet 140 from the top (on the world
##     map his position 80 from the top).
##   - [method follow] (Omni CK_NormalCamera) keeps Keen between 144 and
##     192 pixels from the left and his feet between 33 and 167 pixels
##     from the top, settles his feet back to 140 while he stands, and
##     lets him look up and down 1 pixel per tic. It moves at most 255
##     units per frame.
## A wider view than the original's (widescreen) is centred on the
## original's view and kept inside the area between the blocks around it
## ([method wide_view_left], [method area_pixels]); what it would show
## beyond them is covered (docs/keen4/gameplay.md).


## What [method follow] needs to know about Keen after a logic frame.
class Target:
	extends RefCounted
	## His x and the bottom of his hit box, in units.
	var x := 0
	var feet := 0
	## How far he moved down in this frame, in units.
	var moved_down := 0
	## Standing on something, not clipped, or hanging on a ledge: the view
	## settles his feet back to their resting place.
	var grounded := true
	## Pulling himself up a ledge: the view does not settle.
	var pulling := false
	## -1 looking up, 1 looking down, 0 neither.
	var look := 0
	## The tics of this frame.
	var tics := GalaxyClock.NORMAL_TICS


const UNITS_PER_PIXEL := 16
const UNITS_PER_TILE := 256
const TILE_PIXELS := 16
## The original's view in tiles (Omni RF_SCREEN_WIDTH_TILES, ..._HEIGHT_).
const VIEW_TILES := Vector2i(20, 13)
## The view in pixels; the original shows the top 200 of its 208 rows.
const VIEW_PIXELS := Vector2i(320, 200)
## The map's border the view never shows, in tiles.
const BORDER_TILES := 2
## Keen's x is kept between these pixels of the view (Omni).
const KEEN_LEFT := 144
const KEEN_RIGHT := 192
## Keen's feet are kept above 168 and below 32 pixels (Omni): so between
## 33 and 167.
const FEET_TOP := 32
const FEET_BOTTOM := 168
## Where his feet rest while he stands (Omni).
const FEET_REST := 140
## Looking up and down moves his feet to at most 167 / at least 33 (Omni).
const LOOK_LOWEST := 167
const LOOK_HIGHEST := 33
## Where [method centre_on] puts Keen (Omni CK_CentreCamera).
const CENTRE_X := 152
const MAP_CENTRE_Y := 80
## The view moves at most this many units per frame (Omni).
const MAX_STEP := 255
## The world-map camera (Omni CK_MapCamera): the box stays between these
## pixels from the top; its right edge counts 16 units more.
const MAP_TOP := 80
const MAP_BOTTOM := 112
const MAP_RIGHT_SLACK := 16
## Settling his feet: an eighth of the distance a tic, at most 48 units,
## at least 16 (or what is left) per frame (Omni).
const SETTLE_DIVISOR := 8
const SETTLE_MAX := 48
const SETTLE_MIN := 16

## The top left of the view, in units.
var scroll := Vector2i.ZERO
## The pixel row of the view where Keen's feet should be (Omni screenYpx).
var feet_on_screen := FEET_REST
## The columns and rows the view never scrolls over, the map's border
## included.
var column_blocks := PackedInt32Array()
var row_blocks := PackedInt32Array()
var _map_size := Vector2i.ZERO
var _min := Vector2i.ZERO
var _max := Vector2i.ZERO


## The camera for a map of [param map_size] tiles with blocks on
## [param columns] and [param rows] (besides the border).
static func for_map(
	map_size: Vector2i, columns := PackedInt32Array(), rows := PackedInt32Array()
) -> GalaxyCamera:
	var camera := GalaxyCamera.new()
	camera._map_size = map_size
	camera._min = Vector2i(BORDER_TILES, BORDER_TILES) * UNITS_PER_TILE
	camera._max = (map_size - VIEW_TILES - Vector2i(BORDER_TILES, BORDER_TILES)) * UNITS_PER_TILE
	camera.column_blocks = PackedInt32Array([1, map_size.x - BORDER_TILES])
	camera.column_blocks.append_array(columns)
	camera.row_blocks = PackedInt32Array([1, map_size.y - BORDER_TILES])
	camera.row_blocks.append_array(rows)
	return camera


## The cells of [param map] whose info value is [param value], as columns
## ([param as_columns]) or rows: the scroll blocks the episode's info
## values place.
static func blocks_in(map: GalaxyMap, value: int, as_columns: bool) -> PackedInt32Array:
	var blocks := PackedInt32Array()
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == value:
				blocks.append(x if as_columns else y)
	return blocks


## Puts the view's top left at [param at] (units), inside the map's edges
## and off the scroll blocks (Omni RF_RepositionLimit).
func reposition(at: Vector2i) -> void:
	scroll = at.clamp(_min, _max)
	scroll.x = _off_blocks(scroll.x, column_blocks, VIEW_TILES.x)
	scroll.y = _off_blocks(scroll.y, row_blocks, VIEW_TILES.y)


## Moves the view by [param delta] units; its leading edge stops on a
## scroll block (Omni RFL_SmoothScrollLimit).
func smooth_scroll(delta: Vector2i) -> void:
	var old_tile := Vector2i(scroll.x >> 8, scroll.y >> 8)
	scroll += delta
	scroll.x = _stop_at_blocks(scroll.x, delta.x, column_blocks, VIEW_TILES.x)
	scroll.y = _stop_at_blocks(scroll.y, delta.y, row_blocks, VIEW_TILES.y)
	# A move of more than one tile redraws the view: put again (Omni
	# RF_SmoothScroll).
	var moved := (Vector2i(scroll.x >> 8, scroll.y >> 8) - old_tile).abs()
	if moved.x > 1 or moved.y > 1:
		reposition(scroll)


## Puts the view on Keen at [param x] with his feet (the bottom of his hit
## box) at [param feet] (Omni CK_CentreCamera); on the world map
## ([param world_map]) on his position [param y] instead.
func centre_on(x: int, feet: int, world_map := false, y := 0) -> void:
	feet_on_screen = FEET_REST
	var left := maxi(x - CENTRE_X * UNITS_PER_PIXEL, 0)
	var top := 0
	if world_map:
		top = maxi(y - MAP_CENTRE_Y * UNITS_PER_PIXEL, 0)
	else:
		top = maxi(feet - FEET_REST * UNITS_PER_PIXEL, 0)
	reposition(Vector2i(left, top))


## Moves the view after a logic frame, with Keen at [param target] (Omni
## CK_NormalCamera; leaving the level and falling out of it are Keen's).
func follow(target: Target) -> void:
	var delta := Vector2i(_follow_x(target.x), _look(target))
	if target.grounded:
		if not target.pulling:
			delta.y += target.moved_down
			delta.y += _settle(target, delta.y)
	else:
		feet_on_screen = FEET_REST
	var top := scroll.y + delta.y
	if target.feet < top + FEET_TOP * UNITS_PER_PIXEL:
		delta.y += target.feet - (top + FEET_TOP * UNITS_PER_PIXEL)
	top = scroll.y + delta.y
	if target.feet > top + FEET_BOTTOM * UNITS_PER_PIXEL:
		delta.y += target.feet - (top + FEET_BOTTOM * UNITS_PER_PIXEL)
	if delta != Vector2i.ZERO:
		smooth_scroll(delta.clamp(-Vector2i(MAX_STEP, MAX_STEP), Vector2i(MAX_STEP, MAX_STEP)))


## Moves the view after a logic frame as on the world map and, in Keen 4,
## under water (Omni CK_MapCamera): the box [param left] … [param right],
## [param top] … [param bottom] (units) stays between 144 and 192 pixels
## from the left and 80 and 112 from the top; at most 255 units a frame.
func follow_map(left: int, top: int, right: int, bottom: int) -> void:
	var delta := Vector2i.ZERO
	if left < scroll.x + KEEN_LEFT * UNITS_PER_PIXEL:
		delta.x = left - (scroll.x + KEEN_LEFT * UNITS_PER_PIXEL)
	elif right > scroll.x + KEEN_RIGHT * UNITS_PER_PIXEL:
		delta.x = right + MAP_RIGHT_SLACK - (scroll.x + KEEN_RIGHT * UNITS_PER_PIXEL)
	if top < scroll.y + MAP_TOP * UNITS_PER_PIXEL:
		delta.y = top - (scroll.y + MAP_TOP * UNITS_PER_PIXEL)
	elif bottom > scroll.y + MAP_BOTTOM * UNITS_PER_PIXEL:
		delta.y = bottom - (scroll.y + MAP_BOTTOM * UNITS_PER_PIXEL)
	if delta != Vector2i.ZERO:
		smooth_scroll(delta.clamp(-Vector2i(MAX_STEP, MAX_STEP), Vector2i(MAX_STEP, MAX_STEP)))


## Where the view's top left may go, in units: the map's edges (Omni
## rf_scrollXMinUnit … rf_scrollYMaxUnit). Keen leaving the area these
## views cover to the side ends the level; below it he dies.
func limits() -> Rect2i:
	return Rect2i(_min, _max - _min)


## The top left of the view in pixels (the original scrolls by whole
## pixels).
func view_pixels() -> Vector2i:
	return Vector2i(scroll.x >> 4, scroll.y >> 4)


## The area between the scroll blocks (or the map's border) around the
## view, in pixels: what a wider view may show.
func area_pixels() -> Rect2i:
	var centre := scroll + VIEW_TILES * UNITS_PER_TILE / 2
	var left := _block_before(centre.x, column_blocks) + 1
	var right := _block_after(centre.x, column_blocks, _map_size.x)
	var top := _block_before(centre.y, row_blocks) + 1
	var bottom := _block_after(centre.y, row_blocks, _map_size.y)
	return Rect2i(
		left * TILE_PIXELS,
		top * TILE_PIXELS,
		(right - left) * TILE_PIXELS,
		(bottom - top) * TILE_PIXELS
	)


## The left pixel of a view [param width] pixels wide: centred on the
## original's view and inside [method area_pixels]; centred on that area
## when it is narrower (the rest is covered).
func wide_view_left(width: int) -> int:
	var area := area_pixels()
	var left := view_pixels().x + VIEW_PIXELS.x / 2 - width / 2
	if area.size.x < width:
		return area.position.x - (width - area.size.x) / 2
	return clampi(left, area.position.x, area.end.x - width)


func _follow_x(x: int) -> int:
	if x < scroll.x + KEEN_LEFT * UNITS_PER_PIXEL:
		return x - (scroll.x + KEEN_LEFT * UNITS_PER_PIXEL)
	if x > scroll.x + KEEN_RIGHT * UNITS_PER_PIXEL:
		return x - (scroll.x + KEEN_RIGHT * UNITS_PER_PIXEL)
	return 0


## Looking up or down: the view moves 1 pixel a tic, his feet staying
## between [constant LOOK_HIGHEST] and [constant LOOK_LOWEST].
func _look(target: Target) -> int:
	if target.look < 0:
		var down := mini(target.tics, LOOK_LOWEST - feet_on_screen)
		feet_on_screen += down
		return -down * UNITS_PER_PIXEL
	if target.look > 0:
		var up := mini(target.tics, feet_on_screen - LOOK_HIGHEST)
		feet_on_screen -= up
		return up * UNITS_PER_PIXEL
	return 0


## How far the view moves to bring Keen's feet back to their place.
func _settle(target: Target, delta_y: int) -> int:
	var wanted := feet_on_screen * UNITS_PER_PIXEL + scroll.y + delta_y
	if wanted == target.feet:
		return 0
	var distance := absi(wanted - target.feet)
	var step := mini(distance / SETTLE_DIVISOR, SETTLE_MAX) * target.tics
	if step < SETTLE_MIN:
		step = mini(distance, SETTLE_MIN)
	return -step if target.feet < wanted else step


## [param at] (units, one axis) moved off the first block in
## [param blocks] the view covers (Omni RF_RepositionLimit).
static func _off_blocks(at: int, blocks: PackedInt32Array, view_tiles: int) -> int:
	var tile := at >> 8
	var half := view_tiles / 2
	for block in blocks:
		if block >= tile and tile + half >= block:
			return (block + 1) * UNITS_PER_TILE
		if tile + half + 1 <= block and tile + view_tiles >= block:
			return (block - view_tiles) * UNITS_PER_TILE
	return at


## [param at] after moving [param delta] (one axis), stopped on the tile
## edge when the leading edge reached a block (Omni).
static func _stop_at_blocks(at: int, delta: int, blocks: PackedInt32Array, view_tiles: int) -> int:
	if delta > 0 and blocks.has((at >> 8) + view_tiles):
		return at & ~(UNITS_PER_TILE - 1)
	if delta < 0 and blocks.has(at >> 8):
		return (at & ~(UNITS_PER_TILE - 1)) + UNITS_PER_TILE
	return at


## The last block before [param centre] (units), in tiles.
static func _block_before(centre: int, blocks: PackedInt32Array) -> int:
	var found := -1
	for block in blocks:
		if block * UNITS_PER_TILE < centre:
			found = maxi(found, block)
	return found


## The first block at or after [param centre], or [param end].
static func _block_after(centre: int, blocks: PackedInt32Array, end: int) -> int:
	var found := end
	for block in blocks:
		if block * UNITS_PER_TILE >= centre:
			found = mini(found, block)
	return found
