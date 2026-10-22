class_name LatticeWalls
extends RefCounted
## Finds where a patterned back wall shows on a tile (milestone AB2), for a
## wall that is not one colour but a pattern repeated on every tile: Keen
## 2's lattice (tile 143: light grey with a white and a dark grey line along
## each diagonal). Every tile that has something on that wall carries the
## lattice around it, pixel for pixel in the same place, so a pixel is the
## wall where it equals the lattice's pixel at the same place.
##
## Three kinds of wall pixel ([enum BackdropHoles.Kind]):
##   - lit: the lattice itself
##   - dark: the lattice in the dark (tile 147, black with dark grey lines,
##     the dark shafts of levels 5 and 14); next to a cone of light (tiles
##     157 and 158) its lines sit two pixels further right
##   - shadow: the lattice one EGA step darker (white to light grey, light
##     grey to dark grey, dark grey to black), where a wall casts its shadow
##     on it (tiles 148-152, 178, 179, the bevels along the walls)
##
## A colour that equals the lattice at one place is common in the things
## drawn on it (a plain grey box, a white board, a dithered roof), so a
## group of matching pixels only counts when it looks like the lattice:
##   - it is at least two by two pixels thick ([method _opened]), in one kind
##   - it touches the edge of the tile, as the colour rule's holes do
##   - it holds both kinds of line and its field pixels mostly have their
##     line pixels next to them ([method _looks_like_lattice]); a plain grey
##     box has the field's grey but none of the lines
## Thinner shadows (under a platform) join a shadow or wall next to them
## when they hold a darkened white line ([method _grow_shadows]); lone
## pixels between wall pixels (the corners where two tiles' lines do not
## quite meet) become wall too ([method _fill_specks]).

## Where a pixel lies in the lattice: the field between the lines, or on a
## line drawn darker or lighter than the field.
enum Place { FIELD, DARK_LINE, LIGHT_LINE }

const SIZE := EgaGraphics.TILE_SIZE
## One EGA step of brightness, in bytes (255 / 3).
const EGA_STEP := 85
## How far right the dark lattice's lines sit next to a cone of light.
const DARK_SHIFT := 2
## A group's field pixels must have at least this many times as many line
## pixels of the group next to them as line pixels that are not.
const LINE_RATIO := 3
## The largest group of stray pixels that becomes wall between wall pixels.
const SPECK_SIZE := 4
## A stray group needs at least this many wall pixels around it (a corner
## pixel has two neighbours in the tile).
const SPECK_NEIGHBOURS := 2
## A black pixel of a shadow is wall with at least this many wall neighbours
## (a lattice's dark line is black in the shadow; a black outline is not).
const BLACK_NEIGHBOURS := 3
const BYTES_PER_PIXEL := 4
const NEIGHBOURS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## The RGB of every pixel of each pattern, 3 bytes per pixel.
var _lit := PackedByteArray()
var _shadow := PackedByteArray()
var _darks: Array[PackedByteArray] = []
var _places := PackedByteArray()


## The walls of the lattice [param lit] (a tile), and when [param dark] is
## not null also of that lattice in the dark.
static func create(lit: Image, dark: Image = null) -> LatticeWalls:
	var walls := LatticeWalls.new()
	walls._lit = _rgb(lit)
	walls._shadow = _darker(walls._lit)
	walls._places = _places_of(walls._lit)
	if dark != null:
		var dark_rgb := _rgb(dark)
		walls._darks = [dark_rgb, _shifted(dark_rgb, DARK_SHIFT)]
	return walls


## Whether the lattice in the dark is a wall too.
func has_dark() -> bool:
	return not _darks.is_empty()


## The kind of wall ([enum BackdropHoles.Kind]) of every pixel of
## [param tile], row by row; NONE where it is not the wall.
func kinds(tile: Image) -> PackedByteArray:
	var rgb := _rgb(tile)
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	var lit := _matches(rgb, _lit)
	var shadow := _matches(rgb, _shadow)
	if not (lit.has(1) or shadow.has(1) or _any_dark(rgb)):
		return result
	var lit_wall := _accepted(lit, PackedByteArray())
	# Where a shadow or the dark meets the lit lattice (a cone of light, a
	# shadow's edge), the lattice's lines go on in the lit part.
	var shades: Array[PackedByteArray] = [lit_wall, _accepted(shadow, lit_wall)]
	# The dark lattice's two places of lines meet at a cone's edge.
	var darks: Array[PackedByteArray] = [lit_wall]
	for dark in _darks:
		darks.append(_matches(rgb, dark))
	var dark_beside := _union(darks)
	for i in range(1, darks.size()):
		shades.append(_accepted(darks[i], dark_beside))
	_grow_shadows(rgb, shadow, shades)
	for i in result.size():
		if shades[0][i]:
			result[i] = BackdropHoles.Kind.LIT
		elif shades.size() > 2 and (shades[2][i] or shades[3][i]):
			result[i] = BackdropHoles.Kind.DARK
		elif shades[1][i]:
			result[i] = BackdropHoles.Kind.SHADOW
	_fill_specks(rgb, result)
	return result


func _any_dark(rgb: PackedByteArray) -> bool:
	for dark in _darks:
		if _matches(rgb, dark).has(1):
			return true
	return false


## The groups of [param matched] that look like the lattice; a line pixel
## of [param beside] (another kind of wall) next to a group counts as its own.
func _accepted(matched: PackedByteArray, beside: PackedByteArray) -> PackedByteArray:
	var accepted := PackedByteArray()
	accepted.resize(SIZE * SIZE)
	for group in _groups(_opened(matched)):
		if _touches_edge(group) and _looks_like_lattice(group, beside):
			for i in group:
				accepted[i] = 1
	return accepted


## Whether [param group] holds both kinds of line, and its field pixels
## mostly have the group's own line pixels (or those of [param beside])
## next to them.
func _looks_like_lattice(group: PackedInt32Array, beside: PackedByteArray) -> bool:
	var places := {}
	var members := {}
	for i in group:
		places[_places[i]] = true
		members[i] = true
	if not (places.has(Place.DARK_LINE) and places.has(Place.LIGHT_LINE)):
		return false
	var joined := 0
	var cut := 0
	for i in group:
		if _places[i] != Place.FIELD:
			continue
		for j in _neighbours(i):
			if _places[j] == Place.FIELD:
				continue
			if members.has(j):
				joined += 1
			elif beside.is_empty() or not beside[j]:
				cut += 1
	return joined > 0 and joined >= LINE_RATIO * cut


## Adds the thinner shadows to [param shades] (lit, shadow, dark...): the
## groups of [param shadow] (not black) beside a wall pixel that hold a
## darkened white line, then the black pixels of the shadow mostly
## surrounded by wall.
func _grow_shadows(
	rgb: PackedByteArray, shadow: PackedByteArray, shades: Array[PackedByteArray]
) -> void:
	var wall := _union(shades)
	var candidates := PackedByteArray()
	candidates.resize(SIZE * SIZE)
	for i in candidates.size():
		candidates[i] = 1 if shadow[i] and not wall[i] and not _is_black(rgb, i) else 0
	for group in _groups(candidates):
		if _beside(group, wall) and _holds_places(group, [Place.FIELD, Place.LIGHT_LINE]):
			for i in group:
				shades[1][i] = 1
	wall = _union(shades)
	for i in wall.size():
		if shadow[i] and not wall[i] and _is_black(rgb, i):
			var neighbours := _neighbours(i)
			var walls := 0
			for j in neighbours:
				walls += wall[j]
			if walls >= BLACK_NEIGHBOURS or walls == neighbours.size():
				shades[1][i] = 1


## Makes small groups of grey pixels wall when every pixel beside them is
## wall, as the kind most of those neighbours have.
func _fill_specks(rgb: PackedByteArray, kinds: PackedByteArray) -> void:
	var stray := PackedByteArray()
	stray.resize(SIZE * SIZE)
	for i in stray.size():
		stray[i] = 1 if kinds[i] == BackdropHoles.Kind.NONE and _is_grey(rgb, i) else 0
	for group in _groups(stray):
		if group.size() > SPECK_SIZE:
			continue
		var counts := {}
		var walled := true
		var around := 0
		for i in group:
			for j in _neighbours(i):
				if group.has(j):
					continue
				walled = walled and kinds[j] != BackdropHoles.Kind.NONE
				counts[kinds[j]] = counts.get(kinds[j], 0) + 1
				around += 1
		if not walled or around < SPECK_NEIGHBOURS:
			continue
		var kind: int = counts.keys()[0]
		for candidate: int in counts:
			if counts[candidate] > counts[kind]:
				kind = candidate
		for i in group:
			kinds[i] = kind


func _holds_places(group: PackedInt32Array, wanted: Array) -> bool:
	for place: int in wanted:
		var found := false
		for i in group:
			if _places[i] == place:
				found = true
				break
		if not found:
			return false
	return true


## [param mask] with only the pixels that lie in a 2x2 square of it.
static func _opened(mask: PackedByteArray) -> PackedByteArray:
	var kept := PackedByteArray()
	kept.resize(SIZE * SIZE)
	for y in SIZE - 1:
		for x in SIZE - 1:
			var i := y * SIZE + x
			if mask[i] and mask[i + 1] and mask[i + SIZE] and mask[i + SIZE + 1]:
				for j in [i, i + 1, i + SIZE, i + SIZE + 1]:
					kept[j] = 1
	return kept


## The groups of pixels of [param mask] that touch each other (side by side
## or one above the other), as lists of pixel indices.
static func _groups(mask: PackedByteArray) -> Array[PackedInt32Array]:
	var groups: Array[PackedInt32Array] = []
	var seen := PackedByteArray()
	seen.resize(SIZE * SIZE)
	for start in mask.size():
		if not mask[start] or seen[start]:
			continue
		var group := PackedInt32Array()
		var pending: Array[int] = [start]
		seen[start] = 1
		while not pending.is_empty():
			var i: int = pending.pop_back()
			group.append(i)
			for j in _neighbours(i):
				if mask[j] and not seen[j]:
					seen[j] = 1
					pending.append(j)
		groups.append(group)
	return groups


## The pixels beside pixel [param i], inside the tile.
static func _neighbours(i: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	var at := Vector2i(i % SIZE, i / SIZE)
	for step in NEIGHBOURS:
		var next := at + step
		if next.x >= 0 and next.x < SIZE and next.y >= 0 and next.y < SIZE:
			result.append(next.y * SIZE + next.x)
	return result


static func _touches_edge(group: PackedInt32Array) -> bool:
	for i in group:
		var x := i % SIZE
		var y := i / SIZE
		if x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1:
			return true
	return false


static func _beside(group: PackedInt32Array, mask: PackedByteArray) -> bool:
	for i in group:
		for j in _neighbours(i):
			if mask[j]:
				return true
	return false


static func _union(masks: Array[PackedByteArray]) -> PackedByteArray:
	var result := masks[0].duplicate()
	for mask in masks:
		for i in result.size():
			result[i] = result[i] | mask[i]
	return result


## 1 where [param rgb] equals [param pattern], pixel for pixel.
static func _matches(rgb: PackedByteArray, pattern: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	for i in result.size():
		var at := i * 3
		if (
			rgb[at] == pattern[at]
			and rgb[at + 1] == pattern[at + 1]
			and rgb[at + 2] == pattern[at + 2]
		):
			result[i] = 1
	return result


static func _is_grey(rgb: PackedByteArray, i: int) -> bool:
	return rgb[i * 3] == rgb[i * 3 + 1] and rgb[i * 3 + 1] == rgb[i * 3 + 2]


static func _is_black(rgb: PackedByteArray, i: int) -> bool:
	return _is_grey(rgb, i) and rgb[i * 3] == 0


## The RGB bytes of [param image] (a tile), 3 per pixel.
static func _rgb(image: Image) -> PackedByteArray:
	var copy := image.duplicate() as Image
	copy.convert(Image.FORMAT_RGBA8)
	var rgba := copy.get_data()
	var rgb := PackedByteArray()
	rgb.resize(SIZE * SIZE * 3)
	for i in SIZE * SIZE:
		for channel in 3:
			rgb[i * 3 + channel] = rgba[i * BYTES_PER_PIXEL + channel]
	return rgb


## [param rgb] one EGA step darker.
static func _darker(rgb: PackedByteArray) -> PackedByteArray:
	var result := rgb.duplicate()
	for i in result.size():
		result[i] = maxi(result[i] - EGA_STEP, 0)
	return result


## [param rgb] (a tile) moved [param step] pixels right, wrapping around.
static func _shifted(rgb: PackedByteArray, step: int) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(rgb.size())
	for y in SIZE:
		for x in SIZE:
			var from := (y * SIZE + posmod(x - step, SIZE)) * 3
			var to := (y * SIZE + x) * 3
			for channel in 3:
				result[to + channel] = rgb[from + channel]
	return result


## Where each pixel of the lattice [param rgb] lies: its most common
## colour is the field, darker pixels a dark line, lighter ones a light line.
static func _places_of(rgb: PackedByteArray) -> PackedByteArray:
	var counts := {}
	for i in SIZE * SIZE:
		counts[rgb[i * 3]] = counts.get(rgb[i * 3], 0) + 1
	var field: int = counts.keys()[0]
	for value: int in counts:
		if counts[value] > counts[field]:
			field = value
	var places := PackedByteArray()
	places.resize(SIZE * SIZE)
	for i in places.size():
		var value := rgb[i * 3]
		if value < field:
			places[i] = Place.DARK_LINE
		elif value > field:
			places[i] = Place.LIGHT_LINE
	return places
