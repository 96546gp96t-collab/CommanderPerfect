class_name LevelData
extends RefCounted
## One level (or the world map) from a LEVELxx.CK1 file.
##
## A level has two layers of the same size, one 16-bit number per 16x16 cell:
##   tiles  which graphic tile is drawn in the cell
##   infos  what starts in the cell: Keen, an enemy, an item, or on the world
##          map which level an entrance leads to (0 means nothing)
##
## After RLEW decompression the data starts with a header of 16 words:
##   word 0  width in cells
##   word 1  height in cells
##   word 2  number of layers (always 2)
##   word 7  size of one layer in bytes
## The tile layer follows directly after the header, then the info layer.
##
## Every map has a border of [constant BORDER_CELLS] cells on each side that
## the original never scrolls into view; only the [method playable_rect] is
## ever shown.

const HEADER_WORDS := 16
const WIDTH_WORD := 0
const HEIGHT_WORD := 1
const LAYER_COUNT_WORD := 2
const LAYER_SIZE_WORD := 7
const EXPECTED_LAYER_COUNT := 2
const BORDER_CELLS := 2
## Info layer value that marks where Keen starts (in levels and on the map).
const PLAYER_START_INFO := 255

var width: int
var height: int
var tiles: PackedInt32Array
var infos: PackedInt32Array


## Returns the parsed level, or null when the data is damaged.
static func parse(compressed: PackedByteArray) -> LevelData:
	var words := RlewDecompressor.decompress(compressed)
	if words.size() < HEADER_WORDS:
		push_error("Level data is too short.")
		return null
	if words[LAYER_COUNT_WORD] != EXPECTED_LAYER_COUNT:
		push_error("Level has %d layers instead of 2." % words[LAYER_COUNT_WORD])
		return null

	var level := LevelData.new()
	level.width = words[WIDTH_WORD]
	level.height = words[HEIGHT_WORD]
	var cell_count := level.width * level.height
	# Layers can be padded, so the header tells where the second one starts.
	var layer_words: int = words[LAYER_SIZE_WORD] / 2
	var tiles_start := HEADER_WORDS
	var infos_start := HEADER_WORDS + layer_words

	if infos_start + cell_count > words.size():
		push_error("Level data ends before both layers are complete.")
		return null

	level.tiles = words.slice(tiles_start, tiles_start + cell_count)
	level.infos = words.slice(infos_start, infos_start + cell_count)
	return level


func tile_at(cell: Vector2i) -> int:
	return tiles[cell.y * width + cell.x]


## Changes the tile in [param cell], for example when Keen picks up an item.
func set_tile(cell: Vector2i, tile: int) -> void:
	tiles[cell.y * width + cell.x] = tile


func info_at(cell: Vector2i) -> int:
	return infos[cell.y * width + cell.x]


## The cells inside the border: the part of the map the player can see.
func playable_rect() -> Rect2i:
	var border := Vector2i(BORDER_CELLS, BORDER_CELLS)
	return Rect2i(border, Vector2i(width, height) - border * 2)


## Returns the first cell (row by row) whose info value is [param value], or
## [code]Vector2i(-1, -1)[/code] when there is none.
func find_info(value: int) -> Vector2i:
	var index := infos.find(value)
	if index < 0:
		return Vector2i(-1, -1)
	return Vector2i(index % width, index / width)
