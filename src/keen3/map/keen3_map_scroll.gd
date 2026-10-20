class_name Keen3MapScroll
extends RefCounted
## Which part of Keen 3's world map the view shows: the top left corner of
## the view, moved as the original moves it (Choco `CVort_move_worldmap`,
## `CVort3_do_messie`, `CVort3_worldmap_sprites`), instead of the shared
## camera's dead zone around the middle:
##   - Keen (or Messie with Keen on her back) may move freely while the top
##     left of his sprite is 9-11 cells from the left edge of the view and
##     3-7 cells from the top; moving beyond, the view moves along by the
##     same distance
##   - a new game starts with Keen at 9 cells from the left and 3 from the
##     top (the start cell (44,47) shows cell (35,44) top left; seen in
##     js-dos)
##   - a teleporter puts its destination 10 cells from the left and 6 from
##     the top
## The view never shows anything outside the playable area. The numbers are
## for the original 320x200 view; a wider view keeps Keen's free stretch in
## its middle, as wide as in 4:3. [Keen3View] puts the camera on
## [method center].

## Free stretch for the top left of Keen's sprite, in pixels from the left
## and the top of a 320x200 view.
const FREE_LEFT := 144.0
const FREE_RIGHT := 176.0
const FREE_TOP := 48.0
const FREE_BOTTOM := 112.0
## Where a teleporter's destination ends up, from the top left of the view.
const DESTINATION_OFFSET := Vector2(160, 96)
const ORIGINAL_VIEW := Vector2(320, 200)

## The top left of the view, in map pixels, after the last tick and before
## it (for drawing between ticks).
var corner := Vector2.ZERO
var previous_corner := Vector2.ZERO
var view_size := ORIGINAL_VIEW
## The part of the map that may be seen, in pixels.
var area := Rect2()


## A view of [param size] pixels over [param playable] (pixels), showing
## [param keen_at] (the top left of Keen's sprite) as a new game does.
static func showing(playable: Rect2, size: Vector2, keen_at: Vector2) -> Keen3MapScroll:
	var scroll := Keen3MapScroll.new()
	scroll.area = playable
	scroll.view_size = size
	scroll.jump_to(keen_at - scroll._free_start())
	return scroll


## The same view over [param playable], at [param top_left] (as it was when
## Keen left the map).
static func at_corner(playable: Rect2, size: Vector2, top_left: Vector2) -> Keen3MapScroll:
	var scroll := Keen3MapScroll.new()
	scroll.area = playable
	scroll.view_size = size
	scroll.jump_to(top_left)
	return scroll


## Starts a new tick: what the view showed becomes the "before".
func begin_tick() -> void:
	previous_corner = corner


## Moves along with something whose sprite has its top left at
## [param at] and that just moved by [param moved].
func follow(at: Vector2, moved: Vector2) -> void:
	var start := _free_start()
	var end := _free_end()
	var relative := at - corner
	for axis in [0, 1]:
		if moved[axis] > 0.0 and relative[axis] > end[axis]:
			corner[axis] += moved[axis]
		elif moved[axis] < 0.0 and relative[axis] < start[axis]:
			corner[axis] += moved[axis]
	corner = _clamped(corner)


## Shows [param cell] where a teleporter puts its destination.
func show_destination(cell: Vector2i) -> void:
	var offset := Vector2(view_size.x / 2.0, DESTINATION_OFFSET.y * view_size.y / ORIGINAL_VIEW.y)
	jump_to(Vector2(cell * EgaGraphics.TILE_SIZE) - offset)


## Puts the top left of the view at [param top_left] at once (no drawing in
## between).
func jump_to(top_left: Vector2) -> void:
	corner = _clamped(top_left)
	previous_corner = corner


## A view of another size (widescreen on or off): the middle stays.
func resize(size: Vector2) -> void:
	if size == view_size:
		return
	var middle := corner + view_size / 2.0
	view_size = size
	jump_to(middle - size / 2.0)


## The middle of the view, [param blend] of the way from the last tick
## before to the last one.
func center(blend := 1.0) -> Vector2:
	return previous_corner.lerp(corner, blend) + view_size / 2.0


func _free_start() -> Vector2:
	var middle := view_size.x / 2.0
	var half_width := (FREE_RIGHT - FREE_LEFT) / 2.0
	return Vector2(middle - half_width, FREE_TOP * view_size.y / ORIGINAL_VIEW.y)


func _free_end() -> Vector2:
	var middle := view_size.x / 2.0
	var half_width := (FREE_RIGHT - FREE_LEFT) / 2.0
	return Vector2(middle + half_width, FREE_BOTTOM * view_size.y / ORIGINAL_VIEW.y)


## [param top_left] moved so that the view stays inside [member area]; a
## view larger than the area is centred on it.
func _clamped(top_left: Vector2) -> Vector2:
	var result := top_left
	for axis in [0, 1]:
		var spare := area.size[axis] - view_size[axis]
		if spare < 0.0:
			result[axis] = area.position[axis] + spare / 2.0
		else:
			result[axis] = clampf(result[axis], area.position[axis], area.position[axis] + spare)
	return result
