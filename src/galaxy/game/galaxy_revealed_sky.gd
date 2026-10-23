class_name GalaxyRevealedSky
extends RefCounted
## What a cell shows behind it once Keen has taken the item drawn in it
## (ours, milestone E12.1). At the start of a map the rule for the picture
## behind a level decides, pixel by pixel, which see-through pixels show
## the picture and which keep the sky's colour; the item covered some of
## them then. Taking it reveals them. A revealed part shows what it is
## joined to: the picture when it touches a pixel of the cell that showed
## the picture before, or one across the cell's side that shows it now; the
## sky's colour otherwise (a closed pocket stays closed). So an item over
## Korath III's sky or in a window to space leaves exactly the picture
## around it, and one over a door's black inside leaves black.

const TILE := GalaxyGraphics.TILE16_SIZE
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## The rows (level pixels, one pixel high) of [param cell] that keep the
## sky's colour now. [param mask] holds the cell's see-through pixels now
## (1 each, [method GalaxySkyPockets.see_through]; empty: none),
## [param showed] whether pixel [code]i[/code] of the cell
## ([code]y * TILE + x[/code]) showed the picture before, and
## [param shows] whether a level pixel of a cell around it shows the
## picture now.
static func kept_rows(
	cell: Vector2i, mask: PackedByteArray, showed: Callable, shows: Callable
) -> Array[Rect2i]:
	var rows: Array[Rect2i] = []
	if mask.is_empty():
		return rows
	var seen := PackedByteArray()
	seen.resize(TILE * TILE)
	var corner := cell * TILE
	for start in TILE * TILE:
		if mask[start] == 0 or seen[start] == 1:
			continue
		var part := _part_of(mask, seen, start)
		if not _is_open(part, corner, showed, shows):
			_add_rows(rows, part, corner)
	return rows


## The pixels (indices) 4-joined to [param start] in [param mask], marked
## in [param seen].
static func _part_of(mask: PackedByteArray, seen: PackedByteArray, start: int) -> Array[int]:
	var part: Array[int] = [start]
	seen[start] = 1
	var next_index := 0
	while next_index < part.size():
		var index := part[next_index]
		next_index += 1
		var at := Vector2i(index % TILE, index / TILE)
		for side in SIDES:
			var next := at + side
			if next.x < 0 or next.y < 0 or next.x >= TILE or next.y >= TILE:
				continue
			var other := next.y * TILE + next.x
			if mask[other] == 1 and seen[other] == 0:
				seen[other] = 1
				part.append(other)
	return part


## Whether [param part] showed the picture before somewhere, or touches a
## pixel across the cell's side that shows it now.
static func _is_open(part: Array[int], corner: Vector2i, showed: Callable, shows: Callable) -> bool:
	for index in part:
		if showed.call(index):
			return true
	for index in part:
		var at := Vector2i(index % TILE, index / TILE)
		for side in SIDES:
			var next := at + side
			var inside := next.x >= 0 and next.y >= 0 and next.x < TILE and next.y < TILE
			if not inside and shows.call(corner + next):
				return true
	return false


static func _add_rows(rows: Array[Rect2i], part: Array[int], corner: Vector2i) -> void:
	var marked := PackedByteArray()
	marked.resize(TILE * TILE)
	for index in part:
		marked[index] = 1
	for y in TILE:
		var x := 0
		while x < TILE:
			if marked[y * TILE + x] == 0:
				x += 1
				continue
			var start := x
			while x < TILE and marked[y * TILE + x] == 1:
				x += 1
			rows.append(Rect2i(corner + Vector2i(start, y), Vector2i(x - start, 1)))
