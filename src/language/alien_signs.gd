class_name AlienSigns
extends RefCounted
## Finds the signs in the alien alphabet (the Standard Galactic Alphabet) in
## a level, as cells of the tile grid with their English text. Two kinds:
##   - signs drawn as whole tiles with the words in them (Keen 1's "THIS IS
##     NEAT" next to every raygun): a [Group] of tile numbers; touching cells
##     whose tiles are of the same group are one sign, so a sign of several
##     tiles, its animation frames and its top and bottom halves need no
##     exact layout;
##   - texts spelled with one tile per letter (Keen 2 and 3 have the whole
##     alphabet as tiles): letters in a row are a word, up to
##     [constant WORD_GAP] other tiles between two words are a space ("KILL
##     KEEN"), and lines straight under each other are one sign ("LOWER" over
##     "VORTIVILLE").
## The tables of each game are in [AlienSignTables].

## Most tiles between two words of one line.
const WORD_GAP := 2


## One sign: the cells it covers and what it says in English.
class Sign:
	extends RefCounted
	var cells := Rect2i()
	var text := ""

	static func create(at: Rect2i, english: String) -> Sign:
		var made := Sign.new()
		made.cells = at
		made.text = english
		return made


## Tiles that together show one text.
class Group:
	extends RefCounted
	var tiles := PackedInt32Array()
	var text := ""

	static func create(group_tiles: PackedInt32Array, english: String) -> Group:
		var made := Group.new()
		made.tiles = group_tiles
		made.text = english
		return made


## A line of letters found in one row.
class Line:
	extends RefCounted
	var row := 0
	var first := 0
	var last := 0
	var text := ""


## The signs in a grid of [param size] cells whose tile numbers
## [param tile_at] (Vector2i -> int) gives: the [param groups] and the words
## spelled with [param letters] (tile -> letter).
static func find(
	size: Vector2i, tile_at: Callable, groups: Array[Group], letters: Dictionary[int, String] = {}
) -> Array[Sign]:
	var signs := _find_groups(size, tile_at, groups)
	if not letters.is_empty():
		signs.append_array(_find_words(size, tile_at, letters))
	return signs


static func _find_groups(size: Vector2i, tile_at: Callable, groups: Array[Group]) -> Array[Sign]:
	var group_of: Dictionary[int, int] = {}
	for index in groups.size():
		for tile in groups[index].tiles:
			group_of[tile] = index
	var signs: Array[Sign] = []
	if group_of.is_empty():
		return signs
	var seen: Dictionary[Vector2i, bool] = {}
	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var tile: int = tile_at.call(cell)
			if seen.has(cell) or not group_of.has(tile):
				continue
			var group: int = group_of[tile]
			var area := _flood(cell, size, tile_at, group_of, group, seen)
			signs.append(Sign.create(area, groups[group].text))
	return signs


## The cells around [param start] (and touching it) of [param group], as
## the rectangle that holds them; marks them as [param seen].
static func _flood(
	start: Vector2i,
	size: Vector2i,
	tile_at: Callable,
	group_of: Dictionary[int, int],
	group: int,
	seen: Dictionary[Vector2i, bool]
) -> Rect2i:
	var area := Rect2i(start, Vector2i.ONE)
	var pending: Array[Vector2i] = [start]
	seen[start] = true
	var bounds := Rect2i(Vector2i.ZERO, size)
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		area = area.expand(cell + Vector2i.ONE)
		area = area.expand(cell)
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or not bounds.has_point(next):
				continue
			if group_of.get(tile_at.call(next), -1) == group:
				seen[next] = true
				pending.append(next)
	return area


static func _find_words(
	size: Vector2i, tile_at: Callable, letters: Dictionary[int, String]
) -> Array[Sign]:
	var lines: Array[Line] = []
	for y in size.y:
		lines.append_array(_lines_in_row(y, size.x, tile_at, letters))
	var signs: Array[Sign] = []
	var parts: Array = []
	for line in lines:
		var joined := false
		for index in signs.size():
			var sign := signs[index]
			var below := line.row == sign.cells.end.y
			var overlaps := line.first < sign.cells.end.x and line.last >= sign.cells.position.x
			if below and overlaps:
				sign.cells = sign.cells.merge(
					Rect2i(line.first, line.row, line.last - line.first + 1, 1)
				)
				parts[index].append(line.text)
				joined = true
				break
		if not joined:
			signs.append(
				Sign.create(Rect2i(line.first, line.row, line.last - line.first + 1, 1), "")
			)
			parts.append(PackedStringArray([line.text]))
	for index in signs.size():
		signs[index].text = _joined(parts[index])
	return signs


## The lines of letters in row [param y]: a gap of up to
## [constant WORD_GAP] tiles between two letters is a space.
static func _lines_in_row(
	y: int, width: int, tile_at: Callable, letters: Dictionary[int, String]
) -> Array[Line]:
	var found: Array[Line] = []
	var line: Line = null
	for x in width:
		var letter: String = letters.get(tile_at.call(Vector2i(x, y)), "")
		if not letter.is_empty():
			if line == null:
				line = Line.new()
				line.row = y
				line.first = x
			elif line.last < x - 1:
				line.text += " "
			line.text += letter
			line.last = x
		elif line != null and line.last < x - WORD_GAP:
			found.append(line)
			line = null
	if line != null:
		found.append(line)
	return found


## Lines of one letter each, stacked, are one word ("W" over "A" on Keen 2's
## map is "WA"); otherwise the lines are words of one text.
static func _joined(lines: PackedStringArray) -> String:
	for line in lines:
		if line.length() > 1:
			return " ".join(lines)
	return "".join(lines)
