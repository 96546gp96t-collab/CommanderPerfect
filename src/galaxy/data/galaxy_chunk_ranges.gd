class_name GalaxyChunkRanges
extends RefCounted
## Which EGAGRAPH chunks hold what, worked out from the file itself and
## never written down as chunk numbers (Keen 4 v1.0 has 107 pictures, v1.4
## 115, so every later chunk moves). See docs/keen4/file-formats.md.
##
## Chunks 0-2 are the tables of the pictures, masked pictures and sprites:
## their lengths give those counts. The fonts come right after them, their
## number from the episode, then the pictures, masked pictures, sprites, one
## chunk of 8×8 tiles and one of masked 8×8 tiles. At the end of the file
## come the episode's misc chunks, texts and demos. In between lie the
## 16×16 tiles, background then foreground, one chunk each: a background
## tile holds 128 bytes, a foreground tile 160, which the Huffman data
## itself tells apart.

const PICTURE_TABLE := 0
const MASKED_PICTURE_TABLE := 1
const SPRITE_TABLE := 2
const TABLE_COUNT := 3
const PICTURE_ENTRY_SIZE := 4
const SPRITE_ENTRY_SIZE := 18
const PLANE_COUNT := 4
const TILE8_PLANE_BYTES := 8
## 4 colour planes of 8 rows, plus a mask plane for a masked tile.
const TILE8_BYTES := TILE8_PLANE_BYTES * PLANE_COUNT
const TILE8_MASKED_BYTES := TILE8_PLANE_BYTES * (PLANE_COUNT + 1)
const TILE16_PLANE_BYTES := 32
const BACK_TILE_BYTES := TILE16_PLANE_BYTES * PLANE_COUNT
const FORE_TILE_BYTES := TILE16_PLANE_BYTES * (PLANE_COUNT + 1)
## TED5 lays the 16×16 tile sets out 18 tiles wide; every Galaxy tile set
## is a multiple of 18 tiles (Keen 4: 1296 and 2916). Used only to place
## the border between the sets when empty chunks lie around it.
const TILE_SHEET_WIDTH := 18

var font_start := TABLE_COUNT
var font_count := 0
var picture_start := 0
var picture_count := 0
var masked_picture_start := 0
var masked_picture_count := 0
var sprite_start := 0
var sprite_count := 0
var tile8_chunk := 0
var tile8_count := 0
var masked_tile8_chunk := 0
var masked_tile8_count := 0
var back_tile_start := 0
var back_tile_count := 0
var fore_tile_start := 0
var fore_tile_count := 0
var misc_start := 0
var misc_count := 0
var text_start := 0
var text_count := 0
var demo_start := 0
var demo_count := 0


## The ranges of [param file] for [param episode]; null when the file does
## not add up (too few chunks, no tile chunks).
static func from_file(file: GalaxyGraphicsFile, episode: GalaxyEpisode) -> GalaxyChunkRanges:
	var ranges := GalaxyChunkRanges.new()
	ranges.font_count = episode.font_count
	ranges.picture_start = TABLE_COUNT + episode.font_count
	ranges.picture_count = file.expanded_length(PICTURE_TABLE) / PICTURE_ENTRY_SIZE
	ranges.masked_picture_start = ranges.picture_start + ranges.picture_count
	ranges.masked_picture_count = file.expanded_length(MASKED_PICTURE_TABLE) / PICTURE_ENTRY_SIZE
	ranges.sprite_start = ranges.masked_picture_start + ranges.masked_picture_count
	ranges.sprite_count = file.expanded_length(SPRITE_TABLE) / SPRITE_ENTRY_SIZE
	ranges.tile8_chunk = ranges.sprite_start + ranges.sprite_count
	ranges.masked_tile8_chunk = ranges.tile8_chunk + 1
	ranges.tile8_count = file.expand_whole(ranges.tile8_chunk).size() / TILE8_BYTES
	ranges.masked_tile8_count = (
		file.expand_whole(ranges.masked_tile8_chunk).size() / TILE8_MASKED_BYTES
	)
	ranges.back_tile_start = ranges.masked_tile8_chunk + 1
	ranges.misc_count = episode.misc_count
	ranges.text_count = episode.text_count
	ranges.demo_count = episode.demo_count
	ranges.demo_start = file.chunk_count() - episode.demo_count
	ranges.text_start = ranges.demo_start - episode.text_count
	ranges.misc_start = ranges.text_start - episode.misc_count
	var tile_count := ranges.misc_start - ranges.back_tile_start
	if ranges.sprite_count <= 0 or tile_count <= 0:
		push_error("EGAGRAPH has too few chunks for its tables.")
		return null
	ranges.back_tile_count = _back_tile_count(file, ranges.back_tile_start, tile_count)
	ranges.fore_tile_start = ranges.back_tile_start + ranges.back_tile_count
	ranges.fore_tile_count = tile_count - ranges.back_tile_count
	return ranges


## How many of the [param count] tile chunks from [param start] are
## background tiles: the foreground tiles are the ones that hold
## [constant FORE_TILE_BYTES]. Empty chunks around the border could belong
## to either set; the border is then put on a whole row of the tile sheet.
static func _back_tile_count(file: GalaxyGraphicsFile, start: int, count: int) -> int:
	var first_fore := _first_fore_tile(file, start, start + count)
	var last_back := first_fore - 1
	while last_back >= start and file.is_empty(last_back):
		last_back -= 1
	var lowest := last_back + 1 - start
	var highest := first_fore - start
	var row_end := ceili(float(lowest) / TILE_SHEET_WIDTH) * TILE_SHEET_WIDTH
	return row_end if row_end <= highest else lowest


## The first chunk in [param start] up to [param end] that is a foreground
## tile, found by halving (all background tiles come first); [param end]
## when there is none.
static func _first_fore_tile(file: GalaxyGraphicsFile, start: int, end: int) -> int:
	var low := start
	var high := end
	while low < high:
		var middle := (low + high) / 2
		var probe := middle
		while probe < high and file.is_empty(probe):
			probe += 1
		if probe == high:
			high = middle
		elif file.holds(probe, FORE_TILE_BYTES):
			high = middle
		else:
			low = probe + 1
	# "high" may lie before a run of empty chunks: move to the first tile.
	while high < end and file.is_empty(high):
		high += 1
	return high


## The size of the tile information for these tile sets: two tables per
## background tile, seven per foreground tile.
func tile_info_size() -> int:
	return (
		GalaxyTileInfo.BACK_TABLES * back_tile_count + GalaxyTileInfo.FORE_TABLES * fore_tile_count
	)
