class_name DisplaySettings
extends RefCounted
## How the game picture is shaped: how many game pixels are visible, and how
## that picture is stretched to fit the window.
##
## The original runs at 320x200 on a 4:3 monitor, so its pixels are 1.2 times
## taller than wide. With [member correct_pixel_aspect] on, the picture is
## stretched the same way; with it off, pixels are square.
##
## [constant Aspect.ORIGINAL] shows exactly what the original showed.
## [constant Aspect.WIDESCREEN] keeps the same height and shows more of the
## level on the sides, enough to fill a 16:9 screen.

enum Aspect { ORIGINAL, WIDESCREEN }

const ORIGINAL_SIZE := Vector2i(320, 200)
const ORIGINAL_PIXEL_ASPECT := 1.2  # (4 / 3) / (320 / 200)
const WIDESCREEN_RATIO := 16.0 / 9.0

var aspect := Aspect.ORIGINAL
var correct_pixel_aspect := true


## Size of the visible part of the level, in game pixels.
func game_size() -> Vector2i:
	if aspect == Aspect.ORIGINAL:
		return ORIGINAL_SIZE
	var width := ORIGINAL_SIZE.y * pixel_aspect() * WIDESCREEN_RATIO
	# Even, so that the view has a center on a whole pixel.
	return Vector2i(roundi(width / 2.0) * 2, ORIGINAL_SIZE.y)


## Height of one game pixel relative to its width.
func pixel_aspect() -> float:
	return ORIGINAL_PIXEL_ASPECT if correct_pixel_aspect else 1.0


## Shape of the picture on screen, before scaling it to the window.
func display_size() -> Vector2:
	var size := Vector2(game_size())
	return Vector2(size.x, size.y * pixel_aspect())


## The largest rectangle with the shape of [method display_size] that fits in
## [param window_size], centered.
func fit_rect(window_size: Vector2) -> Rect2:
	var shape := display_size()
	var scale := minf(window_size.x / shape.x, window_size.y / shape.y)
	var size := shape * scale
	return Rect2((window_size - size) / 2.0, size)


func aspect_name() -> String:
	return "original" if aspect == Aspect.ORIGINAL else "widescreen"
