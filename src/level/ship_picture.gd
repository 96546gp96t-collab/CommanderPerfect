class_name ShipPicture
extends RefCounted
## Draws the parts of the cabin of Keen's ship that stay still into an image
## of game pixels, for [ShipInterior]: the hull, the back wall, portholes,
## pipes, cables, the fuel tank, the cockpit, the sockets of the places,
## the floor and the hatch. Pixel art of our own, in the EGA palette.

const BLACK := ShipInterior.BLACK
const BLUE := ShipInterior.BLUE
const CYAN := ShipInterior.CYAN
const RED := ShipInterior.RED
const LIGHT_GRAY := ShipInterior.LIGHT_GRAY
const DARK_GRAY := ShipInterior.DARK_GRAY
const LIGHT_BLUE := ShipInterior.LIGHT_BLUE
const GREEN := ShipInterior.GREEN
const LIGHT_CYAN := ShipInterior.LIGHT_CYAN
const LIGHT_RED := ShipInterior.LIGHT_RED
const YELLOW := ShipInterior.YELLOW
const WHITE := ShipInterior.WHITE

## The lower part of the hull is shaded, with the red stripe of the ship.
const HULL_SHADE_Y := 140
const STRIPE := Rect2i(28, 145, 270, 4)
const STRIPE_DASH := 14
const STRIPE_GAP := 6
const RIVET_SPACING := 16
## Panels of the back wall.
const PANEL_WIDTH := 48
const PANEL_SEAM_Y := 84
const JOINT_SPACING := 40
const FLOOR_PLATE := 4
const FLOOR_GRATE := 6
const GROOVE_SPACING := 8
const HAZARD_STRIPE := 3


static func draw_hull(
	image: Image,
	hull: PackedVector2Array,
	cabin: PackedVector2Array,
	windshield: PackedVector2Array,
) -> void:
	var hull_mask := _mask(image, hull)
	_fill_outlined(image, hull_mask, WHITE)
	for y in range(HULL_SHADE_Y, image.get_height()):
		for x in image.get_width():
			if _is_inner(image, hull_mask, x, y):
				_pixel(image, x, y, LIGHT_GRAY)
	for x in range(STRIPE.position.x, STRIPE.end.x):
		var dash := (x - STRIPE.position.x) % (STRIPE_DASH + STRIPE_GAP) < STRIPE_DASH
		_rect(image, Rect2i(x, STRIPE.position.y, 1, STRIPE.size.y), RED if dash else WHITE)
	for x in range(RIVET_SPACING, 290, RIVET_SPACING):
		_pixel(image, x, 9, LIGHT_GRAY)
		_pixel(image, x, 153, DARK_GRAY)
	_fill_outlined(image, _mask(image, windshield), BLUE)
	for step in 6:
		_pixel(image, 312 + step * 2, 16 + step * 2, LIGHT_BLUE)
		_pixel(image, 330 + step * 2, 30 + step * 2, LIGHT_BLUE)
	# The edge of the cut: the thickness of the hull around the cabin.
	var cabin_mask := _mask(image, cabin)
	for y in image.get_height():
		for x in image.get_width():
			if not _at(image, cabin_mask, x, y) and _near(image, cabin_mask, x, y, 2):
				_pixel(image, x, y, DARK_GRAY)


## The back wall: dark panels with seams, rivets and a crack from the crash.
static func draw_wall(image: Image, cabin: PackedVector2Array) -> void:
	var cabin_mask := _mask(image, cabin)
	for y in image.get_height():
		for x in image.get_width():
			if _at(image, cabin_mask, x, y):
				_pixel(image, x, y, DARK_GRAY)
	for x in range(16 + PANEL_WIDTH, 292, PANEL_WIDTH):
		_rect(image, Rect2i(x, 32, 1, 96), BLACK)
		_rect(image, Rect2i(x + 1, 32, 1, 96), LIGHT_GRAY)
		for y in [38, PANEL_SEAM_Y - 3, PANEL_SEAM_Y + 4, 122]:
			_pixel(image, x - 3, y, LIGHT_GRAY)
			_pixel(image, x + 4, y, LIGHT_GRAY)
	for x in range(16, 353):
		if _at(image, cabin_mask, x, PANEL_SEAM_Y):
			_pixel(image, x, PANEL_SEAM_Y, BLACK)
			_pixel(image, x, PANEL_SEAM_Y + 1, LIGHT_GRAY)
	var crack: Array[Vector2i] = [
		Vector2i(98, 44),
		Vector2i(101, 50),
		Vector2i(97, 55),
		Vector2i(102, 62),
		Vector2i(99, 70),
		Vector2i(104, 76),
	]
	for index in crack.size() - 1:
		_line(image, crack[index], crack[index + 1], BLACK)


## A round window: a light frame, dark glass and the red ground of Mars.
static func draw_porthole(image: Image, center: Vector2i, radius: int) -> void:
	_circle(image, center, radius, BLACK)
	_circle(image, center, radius - 1, LIGHT_GRAY)
	_circle(image, center, radius - 3, WHITE)
	_circle(image, center, radius - 4, BLACK)
	var glass := radius - 5
	for y in range(-glass, glass + 1):
		for x in range(-glass, glass + 1):
			if x * x + y * y <= glass * glass:
				var color := BLUE if y < 3 else (LIGHT_RED if y == 3 else RED)
				_pixel(image, center.x + x, center.y + y, color)
	_pixel(image, center.x - 3, center.y - 5, LIGHT_BLUE)
	_pixel(image, center.x - 4, center.y - 4, LIGHT_BLUE)


static func draw_ceiling_pipe(image: Image, y: int, from_x: int, to_x: int) -> void:
	_rect(image, Rect2i(from_x, y, to_x - from_x, 5), LIGHT_GRAY)
	_rect(image, Rect2i(from_x, y, to_x - from_x, 1), WHITE)
	_rect(image, Rect2i(from_x, y + 4, to_x - from_x, 1), DARK_GRAY)
	_rect(image, Rect2i(from_x, y + 5, to_x - from_x, 1), BLACK)
	for x in range(from_x + JOINT_SPACING / 2, to_x, JOINT_SPACING):
		_rect(image, Rect2i(x, y - 1, 3, 8), BLACK)
		_rect(image, Rect2i(x, y, 2, 6), DARK_GRAY)
		_rect(image, Rect2i(x + 1, y - 3, 1, 2), BLACK)


## The fuel tank, the battery bay, a pipe with a valve, a vent, the pilot's
## seat and the controls with the radar.
static func draw_fixtures(image: Image) -> void:
	_draw_fuel_tank(image)
	_rect(image, Rect2i(136, 96, 32, 33), BLACK)
	_rect(image, Rect2i(137, 97, 30, 31), LIGHT_GRAY)
	_rect(image, Rect2i(139, 99, 26, 2), DARK_GRAY)
	_rect(image, Rect2i(140, 40, 1, 56), RED)
	_rect(image, Rect2i(164, 40, 1, 56), BLACK)
	_rect(image, Rect2i(193, 40, 6, 88), BLACK)
	_rect(image, Rect2i(194, 40, 4, 88), LIGHT_GRAY)
	_rect(image, Rect2i(194, 40, 1, 88), WHITE)
	_circle(image, Vector2i(196, 92), 5, BLACK)
	_circle(image, Vector2i(196, 92), 4, RED)
	_circle(image, Vector2i(196, 92), 1, DARK_GRAY)
	_rect(image, Rect2i(202, 90, 28, 39), BLACK)
	_rect(image, Rect2i(203, 91, 26, 37), LIGHT_GRAY)
	for y in range(94, 108, 3):
		_rect(image, Rect2i(206, y, 20, 1), BLACK)
	_draw_cockpit(image)


static func _draw_fuel_tank(image: Image) -> void:
	_rect(image, Rect2i(53, 74, 26, 55), BLACK)
	_rect(image, Rect2i(54, 75, 24, 53), CYAN)
	_rect(image, Rect2i(57, 76, 3, 51), LIGHT_CYAN)
	_rect(image, Rect2i(54, 86, 24, 2), DARK_GRAY)
	_rect(image, Rect2i(54, 116, 24, 2), DARK_GRAY)
	_rect(image, Rect2i(62, 70, 8, 5), BLACK)
	_rect(image, Rect2i(63, 71, 6, 3), LIGHT_GRAY)
	_rect(image, Rect2i(60, 96, 12, 8), RED)
	_rect(image, Rect2i(62, 98, 8, 1), WHITE)
	_rect(image, Rect2i(62, 101, 8, 1), WHITE)
	# The pipe from the tank to the place of the Everclear.
	_rect(image, Rect2i(78, 103, 9, 4), BLACK)
	_rect(image, Rect2i(78, 104, 8, 2), LIGHT_GRAY)
	_rect(image, Rect2i(84, 103, 4, 7), BLACK)
	_rect(image, Rect2i(85, 104, 2, 6), LIGHT_GRAY)


static func _draw_cockpit(image: Image) -> void:
	_rect(image, Rect2i(263, 95, 8, 28), BLACK)
	_rect(image, Rect2i(264, 96, 6, 26), RED)
	_rect(image, Rect2i(265, 97, 1, 22), LIGHT_RED)
	_rect(image, Rect2i(263, 113, 24, 8), BLACK)
	_rect(image, Rect2i(264, 114, 22, 6), RED)
	_rect(image, Rect2i(265, 114, 20, 1), LIGHT_RED)
	_rect(image, Rect2i(273, 121, 5, 7), DARK_GRAY)
	_rect(image, Rect2i(298, 100, 54, 29), BLACK)
	_rect(image, Rect2i(299, 101, 52, 27), LIGHT_GRAY)
	_rect(image, Rect2i(299, 101, 52, 1), WHITE)
	_rect(image, Rect2i(299, 104, 46, 8), DARK_GRAY)
	_rect(image, Rect2i(304, 116, 6, 6), RED)
	_rect(image, Rect2i(314, 116, 6, 6), GREEN)
	_rect(image, Rect2i(326, 117, 18, 2), BLACK)
	var radar := ShipInterior.RADAR
	_rect(image, radar.grow(2), LIGHT_GRAY)
	_rect(image, radar.grow(1), BLACK)
	_rect(image, radar, BLACK)
	var center := radar.get_center()
	for y in range(radar.position.y, radar.end.y):
		for x in range(radar.position.x, radar.end.x):
			var distance := Vector2(x, y).distance_to(Vector2(center))
			if absf(distance - 8.0) < 0.5 or absf(distance - 4.0) < 0.5:
				_pixel(image, x, y, GREEN)
	_rect(image, Rect2i(radar.position.x, center.y, radar.size.x, 1), GREEN)
	_rect(image, Rect2i(center.x, radar.position.y, 1, radar.size.y), GREEN)


## A cable that sags between two points: [x from, x to, sag, color, thick].
static func draw_cable(image: Image, cable: Array, y: int) -> void:
	var from_x: int = cable[0]
	var to_x: int = cable[1]
	var sag: float = cable[2]
	var previous := y
	for x in range(from_x, to_x + 1):
		var t := float(x - from_x) / float(to_x - from_x)
		var at := y + roundi(sag * 4.0 * t * (1.0 - t))
		for between in range(mini(previous, at), maxi(previous, at) + 1):
			_pixel(image, x, between, cable[3])
			if cable[4]:
				_pixel(image, x, between + 1, cable[3])
		previous = at


## A cable torn loose in the crash, hanging down: [x, length, color].
static func draw_torn_cable(image: Image, cable: Array, y: int) -> void:
	var x: int = cable[0]
	var length: int = cable[1]
	for step in length:
		_pixel(image, x + roundi(2.0 * sin(step * 0.15)), y + step, cable[2])
	var end := Vector2i(x + roundi(2.0 * sin(length * 0.15)), y + length)
	_pixel(image, end.x - 1, end.y, YELLOW)
	_pixel(image, end.x + 1, end.y, YELLOW)
	_pixel(image, end.x, end.y + 1, YELLOW)


## A dark recess around a place, with brackets at its corners.
static func draw_socket(image: Image, at: Vector2i) -> void:
	_rect(image, Rect2i(at - Vector2i(2, 2), Vector2i(20, 20)), LIGHT_GRAY)
	_rect(image, Rect2i(at - Vector2i(1, 1), Vector2i(18, 18)), BLACK)
	for corner in [Vector2i(-3, -3), Vector2i(16, -3)]:
		_rect(image, Rect2i(at + corner, Vector2i(3, 3)), WHITE)


static func draw_floor(image: Image, y: int, hatch: Rect2i) -> void:
	_rect(image, Rect2i(0, y, 352, FLOOR_PLATE), LIGHT_GRAY)
	_rect(image, Rect2i(0, y, 352, 1), WHITE)
	_rect(image, Rect2i(0, y + FLOOR_PLATE, 352, FLOOR_GRATE), DARK_GRAY)
	for x in range(0, 352, GROOVE_SPACING):
		_rect(image, Rect2i(x, y + FLOOR_PLATE, 1, FLOOR_GRATE), BLACK)
	_rect(image, Rect2i(0, y + FLOOR_PLATE + FLOOR_GRATE, 352, 1), BLACK)
	# Yellow and black where Keen steps through the hatch.
	for x in range(hatch.position.x, hatch.end.x):
		var yellow := (x / HAZARD_STRIPE) % 2 == 0
		_rect(image, Rect2i(x, y + 1, 1, FLOOR_PLATE - 1), YELLOW if yellow else BLACK)


## The hatch is open: Mars is seen through it. Its frame is striped.
static func draw_hatch(image: Image, hatch: Rect2i) -> void:
	_rect(image, hatch, Color.TRANSPARENT)
	for y in range(hatch.position.y - 4, hatch.end.y):
		var yellow := (y / HAZARD_STRIPE) % 2 == 0
		_rect(image, Rect2i(hatch.end.x - 2, y, 2, 1), YELLOW if yellow else BLACK)
	for x in range(hatch.position.x, hatch.end.x):
		var yellow := (x / HAZARD_STRIPE) % 2 == 0
		_rect(image, Rect2i(x, hatch.position.y - 4, 1, 4), YELLOW if yellow else BLACK)


## Which pixels of [param image] lie inside [param polygon]: one byte each.
static func _mask(image: Image, polygon: PackedVector2Array) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(image.get_width() * image.get_height())
	for y in image.get_height():
		for x in image.get_width():
			var center := Vector2(x + 0.5, y + 0.5)
			mask[y * image.get_width() + x] = int(Geometry2D.is_point_in_polygon(center, polygon))
	return mask


static func _at(image: Image, mask: PackedByteArray, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return false
	return mask[y * image.get_width() + x] != 0


## Fills the pixels in [param mask] with [param color] and a black edge of
## one pixel.
static func _fill_outlined(image: Image, mask: PackedByteArray, color: int) -> void:
	for y in image.get_height():
		for x in image.get_width():
			if _at(image, mask, x, y):
				_pixel(image, x, y, color if _is_inner(image, mask, x, y) else BLACK)


## In the mask, and not at its edge: all four neighbours are in it too.
static func _is_inner(image: Image, mask: PackedByteArray, x: int, y: int) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.ZERO]:
		if not _at(image, mask, x + offset.x, y + offset.y):
			return false
	return true


## Whether a pixel within [param distance] of ([param x], [param y]) is in
## the mask.
static func _near(image: Image, mask: PackedByteArray, x: int, y: int, distance: int) -> bool:
	for dy in range(-distance, distance + 1):
		for dx in range(-distance, distance + 1):
			if _at(image, mask, x + dx, y + dy):
				return true
	return false


static func _circle(image: Image, center: Vector2i, radius: int, color: int) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				_pixel(image, center.x + x, center.y + y, color)


static func _line(image: Image, from: Vector2i, to: Vector2i, color: int) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for step in steps + 1:
		var at := Vector2(from).lerp(Vector2(to), float(step) / maxf(steps, 1.0)).round()
		_pixel(image, int(at.x), int(at.y), color)


static func _rect(image: Image, rect: Rect2i, color: Variant) -> void:
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if clipped.has_area():
		image.fill_rect(clipped, color if color is Color else EgaPalette.color(color))


static func _pixel(image: Image, x: int, y: int, color: int) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, EgaPalette.color(color))
