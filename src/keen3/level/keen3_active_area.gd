class_name Keen3ActiveArea
extends RefCounted
## Where Keen 3's sprites are awake, as the original decides it (Choco). The
## original counts in whole tiles from the top left tile of its 320x200 view
## (20 tiles across, 12.5 down) and looks at the cell of a sprite's top left
## corner:
##   wakes        the cell is more than 2 tiles left of / above the view's
##                corner and less than 23 tiles right / 12 tiles down from it
##   stays awake  the cell is at most 8 tiles left of / above the corner and
##                at most 28 right / 18 down from it; outside that a sprite
##                falls asleep again, and shots, splashes and corpses are
##                deleted
##   on screen    more than 0 and less than 19 tiles right, more than 0 and
##                less than 12 down (only the Foob looks at this)
## In a wider view (widescreen) the right-hand limits grow with the view's
## width and the bottom limits with its height: the margins around the
## visible area stay the original's. With two views (split screen) a sprite
## counts when it is inside the area of either.

const TILE := float(EgaGraphics.TILE_SIZE)
## The original view in tiles: the limits below are counted from it.
const ORIGINAL_WIDTH := 20
const ORIGINAL_HEIGHT := 12
## Wake: cells strictly between these (Choco).
const WAKE_BEFORE := -2
const WAKE_RIGHT := 23
const WAKE_DOWN := 12
## Stay awake: cells from / up to these, inclusive (Choco).
const STAY_BEFORE := -8
const STAY_RIGHT := 28
const STAY_DOWN := 18
## On screen: cells strictly between these (Choco).
const SCREEN_BEFORE := 0
const SCREEN_RIGHT := 19
const SCREEN_DOWN := 12


## Whether a sleeping sprite whose top left is at [param point] wakes up in
## any of [param views] (rectangles in level pixels).
static func wakes(views: Array[Rect2], point: Vector2) -> bool:
	return _inside_any(views, point, WAKE_BEFORE, WAKE_RIGHT, WAKE_DOWN, false)


## Whether an awake sprite at [param point] stays awake.
static func keeps_awake(views: Array[Rect2], point: Vector2) -> bool:
	return _inside_any(views, point, STAY_BEFORE, STAY_RIGHT, STAY_DOWN, true)


## Whether a sprite at [param point] is on the screen (the Foob's test).
static func on_screen(views: Array[Rect2], point: Vector2) -> bool:
	return _inside_any(views, point, SCREEN_BEFORE, SCREEN_RIGHT, SCREEN_DOWN, false)


static func _inside_any(
	views: Array[Rect2], point: Vector2, before: int, right: int, down: int, inclusive: bool
) -> bool:
	var cell := Vector2i(floori(point.x / TILE), floori(point.y / TILE))
	for view in views:
		var corner := Vector2i(floori(view.position.x / TILE), floori(view.position.y / TILE))
		var low := corner + Vector2i(before, before)
		var high := corner + Vector2i(right, down) + _growth(view)
		if inclusive and _between_inclusive(cell, low, high):
			return true
		if not inclusive and _between_exclusive(cell, low, high):
			return true
	return false


## How many tiles wider and taller than the original's [param view] is.
static func _growth(view: Rect2) -> Vector2i:
	return Vector2i(
		maxi(0, roundi(view.size.x / TILE) - ORIGINAL_WIDTH),
		maxi(0, floori(view.size.y / TILE) - ORIGINAL_HEIGHT)
	)


static func _between_inclusive(cell: Vector2i, low: Vector2i, high: Vector2i) -> bool:
	return cell.x >= low.x and cell.y >= low.y and cell.x <= high.x and cell.y <= high.y


static func _between_exclusive(cell: Vector2i, low: Vector2i, high: Vector2i) -> bool:
	return cell.x > low.x and cell.y > low.y and cell.x < high.x and cell.y < high.y
