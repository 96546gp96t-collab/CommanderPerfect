class_name GalaxyIntroBitmap
extends RefCounted
## One of the two big one-colour pictures of a Galaxy episode's intro
## credits (EGAGRAPH misc chunks: the first and the second word of the
## series name; Omni `ck_inter.c`, facts only; docs/keen4/file-formats.md):
## a 16-bit height and width, 200 16-bit offsets (one per row, from the
## start of the chunk), then per row runs of pixels as 16-bit lengths,
## dark and light in turn starting with dark, ended by 0xFFFF.
## [member rows] keeps each row as the x where every run starts, then the
## width.

const HEADER_WORDS := 2
const ROW_COUNT := 200
const END_OF_ROW := 0xFFFF

var width := 0
var height := 0
## Per row: the start of each run (dark, light, dark, ...), then the end.
var rows: Array[PackedInt32Array] = []


## The picture in [param chunk]; null when the chunk is too short.
static func parse(chunk: PackedByteArray) -> GalaxyIntroBitmap:
	var header := (HEADER_WORDS + ROW_COUNT) * 2
	if chunk.size() < header:
		push_error("An intro picture of %d bytes is too short." % chunk.size())
		return null
	var bitmap := GalaxyIntroBitmap.new()
	bitmap.height = chunk.decode_u16(0)
	bitmap.width = chunk.decode_u16(2)
	for row in ROW_COUNT:
		var at := chunk.decode_u16((HEADER_WORDS + row) * 2)
		var starts := PackedInt32Array([0])
		while at + 1 < chunk.size():
			var run := chunk.decode_u16(at)
			at += 2
			if run == END_OF_ROW:
				break
			starts.append(starts[-1] + run)
		bitmap.rows.append(starts)
	return bitmap


## The light runs of row [param row] as [start, end) pairs.
func light_runs(row: int) -> PackedInt32Array:
	var runs := PackedInt32Array()
	if row < 0 or row >= rows.size():
		return runs
	var starts := rows[row]
	for index in range(1, starts.size() - 1, 2):
		runs.append(starts[index])
		runs.append(starts[index + 1])
	return runs


## The picture in [param color] on a see-through image; with
## [param doubled_rows] every even row is shown twice (the original keeps
## only every second row of the first word while it scrolls).
func image(color: Color, doubled_rows := false) -> Image:
	var picture := Image.create_empty(maxi(1, width), ROW_COUNT, false, Image.FORMAT_RGBA8)
	for row in ROW_COUNT:
		var source := row - row % 2 if doubled_rows else row
		var runs := light_runs(source)
		for index in range(0, runs.size(), 2):
			picture.fill_rect(Rect2i(runs[index], row, runs[index + 1] - runs[index], 1), color)
	return picture
