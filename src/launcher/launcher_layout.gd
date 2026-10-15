class_name LauncherLayout
extends RefCounted
## Where the start screen puts things: the picture as large as fits at the
## top, whole and in its own shape, and below it a dark gray bar with the
## icons of the games in its bottom right. The bar always keeps room for
## the icons, so on a 16:9 screen the picture is a little smaller, with dark
## gray beside it.

## The bar is at least this part of the height of the screen.
const BAR_SHARE := 0.1
## The icons are this part of the height of the bar.
const ICON_SHARE := 0.8
## Space between the icons, and from the edge of the screen, as a part of
## the height of the bar.
const GAP_SHARE := 0.1


## Where the picture of [param picture_size] goes on a screen of
## [param screen] pixels.
static func picture_rect(screen: Vector2, picture_size: Vector2) -> Rect2:
	if picture_size.x <= 0.0 or picture_size.y <= 0.0:
		return Rect2()
	var aspect := picture_size.x / picture_size.y
	var height := minf(screen.x / aspect, screen.y * (1.0 - BAR_SHARE))
	var width := height * aspect
	return Rect2((screen.x - width) / 2.0, 0.0, width, height)


## The bar under [param picture].
static func bar_rect(screen: Vector2, picture: Rect2) -> Rect2:
	return Rect2(0.0, picture.end.y, screen.x, screen.y - picture.end.y)


## How many screen pixels an icon pixel is in a bar of [param bar_height].
static func icon_scale(bar_height: float) -> int:
	return maxi(1, floori(bar_height * ICON_SHARE / GameIcon.BASE_SIZE.y))


## Where the icons of [param count] games of [param icon_size] go in
## [param bar]: against its right edge, in the middle of its height.
static func icon_positions(bar: Rect2, icon_size: Vector2, count: int) -> Array[Vector2]:
	var gap := roundf(bar.size.y * GAP_SHARE)
	var positions: Array[Vector2] = []
	var x := bar.end.x - gap - icon_size.x
	var y := bar.position.y + (bar.size.y - icon_size.y) / 2.0
	for index in count:
		positions.push_front(Vector2(x, y).round())
		x -= icon_size.x + gap
	return positions
