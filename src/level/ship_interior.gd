class_name ShipInterior
extends Node2D
## The cabin of Keen's crashed ship ([ShipLevels]), drawn here as pixel art
## of our own in the colors of the EGA palette: the white hull cut open,
## with portholes, pipes, sagging and torn cables, a fuel tank, the pilot's
## seat and the controls in the nose, and a socket around each place of a
## ship part. Through the hatch at the left and the portholes Mars is seen.
##
## It lies behind the tiles: the cabin's tiles are only its background,
## which is left out of the tiles, and the parts in their places. What
## stays still is drawn once into an image; what moves (twinkling stars,
## blinking lights, the radar, sparks from the torn cables, the light of
## each socket) is drawn over it.

## Size of the cabin's playable area in pixels (see [ShipLevels]).
const SIZE := Vector2i(384, 160)
## The floor Keen walks on, and the hatch in the back wall.
const FLOOR_Y := 128
const HATCH := Rect2i(0, 96, 16, 32)
## Seconds between two pictures of what moves.
const FRAME_TIME := 0.1

## EGA colors, by their number in the palette.
const BLACK := 0
const BLUE := 1
const GREEN := 2
const CYAN := 3
const RED := 4
const MAGENTA := 5
const BROWN := 6
const LIGHT_GRAY := 7
const DARK_GRAY := 8
const LIGHT_BLUE := 9
const LIGHT_GREEN := 10
const LIGHT_CYAN := 11
const LIGHT_RED := 12
const LIGHT_MAGENTA := 13
const YELLOW := 14
const WHITE := 15

## The hull from outside, and the cabin inside it, as polygons.
const HULL: PackedVector2Array = [
	Vector2(0, 4),
	Vector2(296, 4),
	Vector2(381, 84),
	Vector2(383, 100),
	Vector2(365, 157),
	Vector2(0, 157),
]
const CABIN: PackedVector2Array = [
	Vector2(16, 32),
	Vector2(292, 32),
	Vector2(352, 96),
	Vector2(352, 128),
	Vector2(16, 128),
]
const WINDSHIELD: PackedVector2Array = [
	Vector2(303, 12),
	Vector2(318, 12),
	Vector2(372, 66),
	Vector2(362, 76),
]
const PORTHOLES: Array[Vector2i] = [Vector2i(40, 64), Vector2i(150, 62), Vector2i(236, 64)]
const PORTHOLE_RADIUS := 12
## Stars in a porthole, from its middle.
const PORTHOLE_STARS: Array[Vector2i] = [
	Vector2i(-4, -4), Vector2i(3, -5), Vector2i(-1, -1), Vector2i(5, -2), Vector2i(-6, 1)
]
## Sagging cables between two points on the ceiling pipe: from x, to x,
## how far they sag, their color and whether they are thick.
const CABLES := [
	[20, 110, 18, RED, true],
	[60, 162, 28, YELLOW, false],
	[96, 188, 14, LIGHT_GREEN, true],
	[134, 262, 32, LIGHT_BLUE, false],
	[200, 286, 20, LIGHT_MAGENTA, true],
	[168, 232, 9, CYAN, false],
]
const CEILING_PIPE_Y := 34
## Torn cables hanging down, sparking at their end: x, length, color.
const TORN_CABLES := [[178, 56, YELLOW], [262, 44, LIGHT_RED]]
## The lights on the controls, and the radar screen above them.
const CONTROL_LIGHTS := 6
const RADAR := Rect2i(306, 70, 26, 20)

var _level: LevelData
var _picture: ImageTexture
var _time := 0.0
var _frame := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	set_process(false)


## Shows the cabin of [param level], the inside of the ship, or hides it
## when [param level] is null.
func show_level(level: LevelData) -> void:
	_level = level
	visible = level != null
	set_process(visible)
	if level == null:
		return
	position = Vector2.ONE * LevelData.BORDER_CELLS * EgaGraphics.TILE_SIZE
	if _picture == null:
		_picture = ImageTexture.create_from_image(_draw_picture())
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _time >= FRAME_TIME:
		_time -= FRAME_TIME
		_frame += 1
		queue_redraw()


func _draw() -> void:
	_draw_outside()
	draw_texture(_picture, Vector2.ZERO)
	_draw_stars()
	_draw_radar()
	_draw_control_lights()
	_draw_sparks()
	_draw_socket_lights()


## Mars behind the hull, seen through the hatch: dark sky with stars above
## the red ground.
func _draw_outside() -> void:
	var far := Vector2(SIZE) * 2.0
	draw_rect(Rect2(-far.x, -far.y, far.x * 3.0, far.y + FLOOR_Y), _color(BLUE))
	draw_rect(Rect2(-far.x, FLOOR_Y, far.x * 3.0, far.y), _color(RED))
	draw_rect(Rect2(-far.x, FLOOR_Y, far.x * 3.0, 1), _color(LIGHT_RED))
	for star in [Vector2(-40, 20), Vector2(-90, 60), Vector2(-20, 84), Vector2(-150, 30)]:
		draw_rect(Rect2(star, Vector2.ONE), _color(WHITE))


## Twinkling stars, and the red ground of Mars low in each porthole.
func _draw_stars() -> void:
	for index in PORTHOLES.size():
		for star in PORTHOLE_STARS.size():
			# Each star is dark now and then, not all at the same time.
			if (_frame + star * 3 + index * 5) % 11 < 2:
				continue
			var at := Vector2(PORTHOLES[index] + PORTHOLE_STARS[star])
			draw_rect(Rect2(at, Vector2.ONE), _color(WHITE))


## The radar: a line that turns around the middle of the screen.
func _draw_radar() -> void:
	var center := Vector2(RADAR.get_center())
	var angle := _frame * 0.35
	for step in 9:
		var point := center + Vector2(cos(angle), sin(angle)) * step
		draw_rect(Rect2(point.floor(), Vector2.ONE), _color(LIGHT_GREEN))
	if _frame % 20 < 10:
		draw_rect(Rect2(center + Vector2(5, -4), Vector2(2, 2)), _color(LIGHT_GREEN))


func _draw_control_lights() -> void:
	var colors: PackedInt32Array = [LIGHT_RED, LIGHT_GREEN, YELLOW, LIGHT_CYAN]
	for index in CONTROL_LIGHTS:
		var lit := (_frame / (2 + index % 3) + index) % 3 != 0
		var color := colors[(index + _frame / 7) % colors.size()] if lit else DARK_GRAY
		draw_rect(Rect2(300 + index * 7, 106, 4, 3), _color(color))


## Now and then the torn cables spark at their end.
func _draw_sparks() -> void:
	for cable in TORN_CABLES:
		if (_frame + int(cable[0])) % 13 > 1:
			continue
		var end := Vector2(int(cable[0]), CEILING_PIPE_Y + 5 + int(cable[1]))
		_rng.seed = _frame * 31 + int(cable[0])
		for spark in 5:
			var offset := Vector2(_rng.randi_range(-3, 3), _rng.randi_range(-1, 4))
			var color := WHITE if spark % 2 == 0 else YELLOW
			draw_rect(Rect2(end + offset, Vector2.ONE), _color(color))


## Above each place a light: red while its part is missing, green once it is
## back.
func _draw_socket_lights() -> void:
	if _level == null:
		return
	for part in ShipLevels.PLACE_COLUMNS.size():
		var cell := ShipLevels.place_cell(part)
		var tile := _level.tile_at(cell + Vector2i.ONE * LevelData.BORDER_CELLS)
		var installed := tile == ShipLevels.PART_TILES[part]
		var color := LIGHT_GREEN if installed else (LIGHT_RED if _frame % 10 < 6 else RED)
		var at := Vector2(cell * EgaGraphics.TILE_SIZE) + Vector2(6, -7)
		draw_rect(Rect2(at - Vector2.ONE, Vector2(6, 4)), _color(BLACK))
		draw_rect(Rect2(at, Vector2(4, 2)), _color(color))


static func _color(index: int) -> Color:
	return EgaPalette.color(index)


## Everything that stays still, in one image of the cabin.
func _draw_picture() -> Image:
	var image := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	ShipPicture.draw_hull(image, HULL, CABIN, WINDSHIELD)
	ShipPicture.draw_wall(image, CABIN)
	for center in PORTHOLES:
		ShipPicture.draw_porthole(image, center, PORTHOLE_RADIUS)
	ShipPicture.draw_ceiling_pipe(image, CEILING_PIPE_Y, 16, 290)
	ShipPicture.draw_fixtures(image)
	for cable in CABLES:
		ShipPicture.draw_cable(image, cable, CEILING_PIPE_Y + 5)
	for cable in TORN_CABLES:
		ShipPicture.draw_torn_cable(image, cable, CEILING_PIPE_Y + 5)
	for part in ShipLevels.PLACE_COLUMNS.size():
		ShipPicture.draw_socket(image, ShipLevels.place_cell(part) * EgaGraphics.TILE_SIZE)
	ShipPicture.draw_floor(image, FLOOR_Y, HATCH)
	ShipPicture.draw_hatch(image, HATCH)
	return image
