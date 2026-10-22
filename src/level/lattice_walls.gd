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
##   - it is at least two by two pixels thick ([method opened]), in one kind
##   - it touches the edge of the tile, as the colour rule's holes do
##   - it holds both kinds of line and its field pixels mostly have their
##     line pixels next to them ([method _looks_like_lattice]); a plain grey
##     box has the field's grey but none of the lines
## Thinner shadows (under a platform) join a shadow or wall next to them
## when they hold a darkened white line, and then the rest of such a shadow
## beside them ([method _grow_shadows]); lone pixels between wall pixels
## (the corners where two tiles' lines do not quite meet) become wall too
## when they have a colour of the lattice they lie in ([method _fill_specks]).
##
## The fixes of 22-10 (the user's second test) add two rules that work on
## any tile ([method framed_strips], [method drawing_runs]): a thin strip of
## lattice between a tile's edge and a black outline is wall (the ends of a
## beam), and a long straight line of one colour that is not the lattice
## somewhere along it is the drawing, never wall (a door's frame).

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
## How far from a tile's edge [method edge_strip] and [method framed_strips]
## look, in pixels.
const EDGE_STRIP := 2
## The fewest pixels of a strip that [method framed_strips] takes: a lone
## pixel of the lattice's colour beside a black outline is as often a
## thing's own (a dark pixel of a city on a Tantalus screen).
const STRIP_SIZE := 4
## The shortest straight line of one colour that [method drawing_runs]
## judges; the lattice's own lines are diagonal, so along a row or a column
## its colour changes every few pixels.
const RUN_LENGTH := 6
## What ends a part of a run in [method _mark_drawing].
const NO_BOUND := 0
const EDGE_BOUND := 1
const FOREIGN_BOUND := 2
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
## The colours (as [method _colour] numbers) a pixel of each kind of wall
## ([enum BackdropHoles.Kind]) can have.
var _colours: Dictionary[int, Dictionary] = {}


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
	var lit_colours := _colours_of(walls._lit)
	walls._colours[BackdropHoles.Kind.LIT] = lit_colours
	walls._colours[BackdropHoles.Kind.SHADOW] = lit_colours.merged(_colours_of(walls._shadow))
	walls._colours[BackdropHoles.Kind.DARK] = lit_colours.duplicate()
	for pattern in walls._darks:
		walls._colours[BackdropHoles.Kind.DARK].merge(_colours_of(pattern))
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
	# The drawing's straight lines are never wall, whatever rule would take them.
	var drawing := _drawing_runs_of(rgb)
	var lit := _without(_matches(rgb, _lit), drawing)
	var shadow := _without(_matches(rgb, _shadow), drawing)
	if not (lit.has(1) or shadow.has(1) or _any_dark(rgb)):
		return result
	var lit_wall := _accepted(lit, PackedByteArray())
	# Where a shadow or the dark meets the lit lattice (a cone of light, a
	# shadow's edge), the lattice's lines go on in the lit part.
	var shades: Array[PackedByteArray] = [lit_wall, _accepted(shadow, lit_wall)]
	# The dark lattice's two places of lines meet at a cone's edge.
	var darks: Array[PackedByteArray] = [lit_wall]
	for dark in _darks:
		darks.append(_without(_matches(rgb, dark), drawing))
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
	_fill_specks(rgb, result, drawing)
	return result


## The lattice around an item on [param tile] (1 for each such pixel): every
## pixel that equals the lit lattice at its place and is joined to the
## tile's edge through more of them. Items have a dark outline, so this
## stops at the item; the pattern rule of [method kinds] would leave the
## thin sides between an item and the tile's edge, and the small pockets
## around it, as lattice.
func item_background(tile: Image) -> PackedByteArray:
	return _edge_flood(_matches(_rgb(tile), _lit))


## The kind of wall of every pixel of [param tile] by its colour alone: lit
## where it equals the lattice at its place, a shadow where it equals the
## lattice one EGA step darker, dark where it equals the lattice in the
## dark; NONE elsewhere. Without the checks of [method kinds], for a part
## of a tile that is known to lie on the wall (the glass of a window).
func pixel_kinds(tile: Image) -> PackedByteArray:
	var rgb := _rgb(tile)
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	var lit := _matches(rgb, _lit)
	var shadow := _matches(rgb, _shadow)
	var darks: Array[PackedByteArray] = []
	for dark in _darks:
		darks.append(_matches(rgb, dark))
	for i in result.size():
		if lit[i]:
			result[i] = BackdropHoles.Kind.LIT
		elif shadow[i]:
			result[i] = BackdropHoles.Kind.SHADOW
		elif darks.any(func(dark: PackedByteArray) -> bool: return dark[i] == 1):
			result[i] = BackdropHoles.Kind.DARK
	return result


## The lattice along the edge of [param tile]: the pixels of
## [method item_background] that lie within [constant EDGE_STRIP] pixels of
## the edge, joined to it through such pixels. Where something stands on the
## lattice a pixel or two from the tile's edge (a sign, a lamp's arms), that
## thin strip is too thin for the pattern rule.
func edge_strip(tile: Image) -> PackedByteArray:
	var matched := _matches(_rgb(tile), _lit)
	for i in matched.size():
		var x := i % SIZE
		var y := i / SIZE
		if mini(mini(x, y), mini(SIZE - 1 - x, SIZE - 1 - y)) >= EDGE_STRIP:
			matched[i] = 0
	return _edge_flood(matched)


## The thin strips of lattice between [param tile]'s edge and a black
## outline, as the kind of wall of every pixel ([enum BackdropHoles.Kind];
## NONE elsewhere): each group of pixels that equal one kind of the lattice
## at their place, has at least [constant STRIP_SIZE] pixels, lies within
## [constant EDGE_STRIP] pixels of the edge and touches it, and has only
## black pixels or pixels of [param walls] (the wall found so far) around
## it inside the tile. The two columns of lattice
## at the end of Keen 2's thick red beam, and its shadow beyond the other
## end, are such strips: too thin and without lines for the pattern rule.
func framed_strips(tile: Image, walls: PackedByteArray) -> PackedByteArray:
	var rgb := _rgb(tile)
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	var patterns: Dictionary[int, Array] = {
		BackdropHoles.Kind.LIT: [_lit],
		BackdropHoles.Kind.SHADOW: [_shadow],
		BackdropHoles.Kind.DARK: _darks,
	}
	for kind: int in patterns:
		for pattern: PackedByteArray in patterns[kind]:
			var matched := _matches(rgb, pattern)
			for i in matched.size():
				matched[i] = matched[i] if walls[i] == 0 and result[i] == 0 else 0
			for group in _groups(matched):
				if _is_framed_strip(rgb, group, walls):
					for i in group:
						result[i] = kind
	return result


## 1 for every pixel of [param tile] in a straight line (a row or a column)
## of at least [constant RUN_LENGTH] pixels of one colour that goes on past
## a place where it is not the lattice (lit, in a shadow or in the dark):
## the frame of a door, the band of a machine. The lattice's lines are
## diagonal, so a straight line of one colour that is all lattice lies on
## its field; a line that passes a place of the lattice's lines in the same
## colour belongs to the drawing, also where its colour equals the lattice
## by chance ([method _mark_drawing]).
func drawing_runs(tile: Image) -> PackedByteArray:
	return _drawing_runs_of(_rgb(tile))


func _drawing_runs_of(rgb: PackedByteArray) -> PackedByteArray:
	var foreign := _foreign(rgb)
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	for line in SIZE:
		for along: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var start := Vector2i(0, line) if along == Vector2i.RIGHT else Vector2i(line, 0)
			_mark_runs(rgb, foreign, start, along, result)
	return result


## Marks in [param result] the runs of one colour along the line from
## [param start] in steps of [param along] that are long enough and hold a
## pixel of [param foreign] ([method _mark_drawing]).
static func _mark_runs(
	rgb: PackedByteArray,
	foreign: PackedByteArray,
	start: Vector2i,
	along: Vector2i,
	result: PackedByteArray
) -> void:
	var run := PackedInt32Array()
	var from := 0
	for step in SIZE + 1:
		var at := start + along * step
		var i := at.y * SIZE + at.x
		if step < SIZE and not run.is_empty() and _colour(rgb, i) == _colour(rgb, run[0]):
			run.append(i)
			continue
		if run.size() >= RUN_LENGTH:
			_mark_drawing(run, foreign, from == 0, step == SIZE, result)
		if step < SIZE:
			run = PackedInt32Array([i])
			from = step


## Marks in [param result] the pixels of [param run] (one colour along a
## line) that lie between two of its pixels of [param foreign], or between
## one and the tile's edge where the run reaches it ([param at_start],
## [param at_end]): there the line goes on past a place where the lattice
## has another colour, so it is the drawing. A part of the run with a
## foreign pixel on one side only, ending in another colour on the other,
## is the lattice beside a thing of its colour.
static func _mark_drawing(
	run: PackedInt32Array,
	foreign: PackedByteArray,
	at_start: bool,
	at_end: bool,
	result: PackedByteArray
) -> void:
	var count := run.size()
	# What lies before each pixel along the run: nothing, the tile's edge or
	# a foreign pixel (the nearest one counts).
	var before := PackedByteArray()
	before.resize(count)
	var bound := EDGE_BOUND if at_start else NO_BOUND
	for k in count:
		if foreign[run[k]]:
			bound = FOREIGN_BOUND
		before[k] = bound
	bound = EDGE_BOUND if at_end else NO_BOUND
	for k in range(count - 1, -1, -1):
		if foreign[run[k]]:
			bound = FOREIGN_BOUND
			result[run[k]] = 1
		elif (
			bound != NO_BOUND
			and before[k] != NO_BOUND
			and (bound == FOREIGN_BOUND or before[k] == FOREIGN_BOUND)
		):
			result[run[k]] = 1


## 1 for every pixel of [param rgb] that equals no kind of the lattice at
## its place.
func _foreign(rgb: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	result.fill(1)
	var patterns: Array[PackedByteArray] = [_lit, _shadow]
	patterns.append_array(_darks)
	for pattern in patterns:
		var matched := _matches(rgb, pattern)
		for i in result.size():
			if matched[i]:
				result[i] = 0
	return result


## Whether [param group] (pixels of [param rgb]) lies along the tile's edge
## within [constant EDGE_STRIP] pixels, touches it, and has only black
## pixels and pixels of [param walls] around it.
static func _is_framed_strip(
	rgb: PackedByteArray, group: PackedInt32Array, walls: PackedByteArray
) -> bool:
	if group.size() < STRIP_SIZE or not _touches_edge(group):
		return false
	var members := {}
	for i in group:
		members[i] = true
		var x := i % SIZE
		var y := i / SIZE
		if mini(mini(x, y), mini(SIZE - 1 - x, SIZE - 1 - y)) >= EDGE_STRIP:
			return false
	for i in group:
		for j in _neighbours(i):
			if not members.has(j) and walls[j] == 0 and not _is_black(rgb, j):
				return false
	return true


## The pixels of [param matched] joined to the tile's edge through more of
## them.
static func _edge_flood(matched: PackedByteArray) -> PackedByteArray:
	var result := PackedByteArray()
	result.resize(SIZE * SIZE)
	var pending: Array[int] = []
	for i in SIZE * SIZE:
		var x := i % SIZE
		var y := i / SIZE
		if matched[i] and (x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1):
			result[i] = 1
			pending.append(i)
	while not pending.is_empty():
		for j in _neighbours(pending.pop_back()):
			if matched[j] and not result[j]:
				result[j] = 1
				pending.append(j)
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
	for group in _groups(opened(matched)):
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
	var rest: Array[PackedInt32Array] = []
	for group in _groups(candidates):
		if _beside(group, wall) and _holds_places(group, [Place.FIELD, Place.LIGHT_LINE]):
			for i in group:
				shades[1][i] = 1
		else:
			rest.append(group)
	_join_black(rgb, shadow, shades, false)
	# The end of a shadow whose lines lie in the part already taken (the
	# right end of the shadow under Keen 2's small platforms), and the black
	# pixels it then surrounds; only grey pixels count as their wall then, so
	# a black outline along the shadow is not taken pixel by pixel.
	var grown := true
	while grown:
		grown = false
		for group in rest:
			if not shades[1][group[0]] and _beside(group, shades[1]):
				for i in group:
					shades[1][i] = 1
				grown = true
	_join_black(rgb, shadow, shades, true)


## Adds to the shadow in [param shades] the black pixels of [param shadow]
## mostly surrounded by wall (with [param grey_only] only grey wall pixels
## count).
func _join_black(
	rgb: PackedByteArray, shadow: PackedByteArray, shades: Array[PackedByteArray], grey_only: bool
) -> void:
	var wall := _union(shades)
	for i in wall.size():
		if shadow[i] and not wall[i] and _is_black(rgb, i):
			var neighbours := _neighbours(i)
			var walls := 0
			for j in neighbours:
				if not grey_only or not _is_black(rgb, j):
					walls += wall[j]
			if walls >= BLACK_NEIGHBOURS or walls == neighbours.size():
				shades[1][i] = 1


## Makes small groups of grey pixels wall when every pixel beside them is
## wall, as the kind most of those neighbours have among the kinds whose
## colours they have and that at least [constant SPECK_NEIGHBOURS] of them
## have.
func _fill_specks(rgb: PackedByteArray, kinds: PackedByteArray, drawing: PackedByteArray) -> void:
	var stray := PackedByteArray()
	stray.resize(SIZE * SIZE)
	for i in stray.size():
		var free := kinds[i] == BackdropHoles.Kind.NONE and not drawing[i]
		stray[i] = 1 if free and _is_grey(rgb, i) else 0
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
		# The most common kind around them whose colours they have: a black
		# pixel among the lit lattice is drawing (the thin arms of Keen 2's
		# zapper), the lit lattice has no black.
		var kind: int = BackdropHoles.Kind.NONE
		for candidate: int in counts:
			if (
				counts[candidate] < SPECK_NEIGHBOURS
				or not _all_of_colours(rgb, group, _colours[candidate])
			):
				continue
			if kind == BackdropHoles.Kind.NONE or counts[candidate] > counts[kind]:
				kind = candidate
		if kind != BackdropHoles.Kind.NONE:
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
static func opened(mask: PackedByteArray) -> PackedByteArray:
	var kept := PackedByteArray()
	kept.resize(SIZE * SIZE)
	for y in SIZE - 1:
		for x in SIZE - 1:
			var i := y * SIZE + x
			if mask[i] and mask[i + 1] and mask[i + SIZE] and mask[i + SIZE + 1]:
				for j in [i, i + 1, i + SIZE, i + SIZE + 1]:
					kept[j] = 1
	return kept


## The groups of pixels of [param mask] (a tile) that touch each other
## (side by side or one above the other), as lists of pixel indices.
static func groups_of(mask: PackedByteArray) -> Array[PackedInt32Array]:
	return _groups(mask)


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


## [param mask] without the pixels of [param other].
static func _without(mask: PackedByteArray, other: PackedByteArray) -> PackedByteArray:
	for i in mask.size():
		if other[i]:
			mask[i] = 0
	return mask


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


static func _all_of_colours(
	rgb: PackedByteArray, group: PackedInt32Array, colours: Dictionary
) -> bool:
	for i in group:
		if not colours.has(_colour(rgb, i)):
			return false
	return true


## The colour of pixel [param i] of [param rgb] as one number.
static func _colour(rgb: PackedByteArray, i: int) -> int:
	return rgb[i * 3] << 16 | rgb[i * 3 + 1] << 8 | rgb[i * 3 + 2]


## The colours of [param rgb] (a tile), as keys.
static func _colours_of(rgb: PackedByteArray) -> Dictionary:
	var colours := {}
	for i in SIZE * SIZE:
		colours[_colour(rgb, i)] = true
	return colours


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
