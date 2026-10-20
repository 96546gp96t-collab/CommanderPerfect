class_name Keen3BorderFlash
extends Control
## The border flash of Keen 3 (milestone C7): when a shot destroys a spark
## or the heart of Mortimer's machine, the original makes the EGA border
## (the edge of the monitor picture around the game) blink yellow and cyan
## (colours 14 and 3, every [constant PHASE_SECONDS] for
## [constant FLASH_SECONDS], Choco). We have no EGA border; by the user's
## decision a thin frame blinks around the game picture instead: outside
## it where the window has room (the black bars around the 4:3 picture),
## over the picture's own edge where it has none (a window of exactly that
## shape, and mostly widescreen). It lies over the [code]Screen[/code] and
## under the messages; [Keen3EndingScreen] tells it where the picture is.

## 26 and 124 ticks of 60 a second (Choco: 63 and 300 clock ticks).
const PHASE_SECONDS := 26.0 / 60.0
const FLASH_SECONDS := 124.0 / 60.0
## EGA colours 14 (yellow) and 3 (cyan), in turn, yellow first.
const COLORS: Array[Color] = [Color8(0xFF, 0xFF, 0x55), Color8(0x00, 0xAA, 0xAA)]
## How thick the frame is, in game pixels (subtle; our choice).
const THICKNESS_GAME_PIXELS := 2.0

## The game picture on the screen, in this control's coordinates.
var picture_rect := Rect2()
var _time_left := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Starts the blinking (again).
func flash() -> void:
	_time_left = FLASH_SECONDS
	queue_redraw()


func is_flashing() -> bool:
	return _time_left > 0.0


## The colour shown now.
func current_color() -> Color:
	var phase := floori((FLASH_SECONDS - _time_left) / PHASE_SECONDS)
	return COLORS[phase % COLORS.size()]


## The four bars of the frame around [param picture] inside [param area]
## (the window), [param thickness] screen pixels thick.
static func frame_bars(picture: Rect2, area: Rect2, thickness: float) -> Array[Rect2]:
	var outer := picture.grow(thickness).intersection(area)
	var inner := outer.grow(-thickness)
	return [
		Rect2(outer.position, Vector2(outer.size.x, thickness)),
		Rect2(Vector2(outer.position.x, inner.end.y), Vector2(outer.size.x, thickness)),
		Rect2(Vector2(outer.position.x, inner.position.y), Vector2(thickness, inner.size.y)),
		Rect2(Vector2(inner.end.x, inner.position.y), Vector2(thickness, inner.size.y)),
	]


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	queue_redraw()


func _draw() -> void:
	if _time_left <= 0.0 or not picture_rect.has_area():
		return
	var pixel := picture_rect.size.y / Keen3Window.PICTURE_SIZE.y
	var thickness := maxf(1.0, roundf(pixel * THICKNESS_GAME_PIXELS))
	for bar in frame_bars(picture_rect, Rect2(Vector2.ZERO, size), thickness):
		draw_rect(bar, current_color())
