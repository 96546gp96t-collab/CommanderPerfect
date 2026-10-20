class_name EgaGraphics
extends RefCounted
## All graphics of the episode, decoded into Godot images.
##
## The arrays follow the order of the original files, so a tile number from a
## level file or a sprite number from the game code can be used as index.

const TILE_SIZE := 16
const FONT_CHAR_SIZE := 8
const LATCH_PLANES := 4
const SPRITE_PLANES := 5  # four color planes and a mask plane
const SPRITE_MASK_PLANE := 4
## The two colors a mask tile is drawn in (EGA 0 and 15), as RGBA bytes.
const _MASK_BLACK: PackedByteArray = [0, 0, 0, 255]
const _MASK_WHITE: PackedByteArray = [255, 255, 255, 255]
const _BYTES_PER_PIXEL := 4

var header: EgaHeader
## 8x8 font characters, indexed by character code.
var font_chars: Array[Image] = []
## 16x16 level tiles, indexed by tile number.
var tiles: Array[Image] = []
## Full-screen pictures, in the same order as [member EgaHeader.bitmaps].
var bitmaps: Array[Image] = []
## Sprites with transparency, in the same order as [member EgaHeader.sprites].
var sprites: Array[Image] = []
## Whether each tile is drawn only in black and white; filled the first time
## [method has_tile_mask] asks.
var _black_and_white := PackedByteArray()


## Loads and decodes all graphics. Returns null when a file is missing or
## damaged; the reason is reported with push_error. [param extension] is the
## episode's file extension: EGAHEAD.CK1 for Keen 1, EGAHEAD.CK2 for Keen 2.
static func load_from(files: GameFiles, extension := GameFiles.DEFAULT_EXTENSION) -> EgaGraphics:
	var graphics := EgaGraphics.new()
	graphics.header = EgaHeader.parse(files.read("EGAHEAD." + extension))
	if graphics.header == null:
		return null

	var latch := _read_planes(
		files, "EGALATCH." + extension, graphics.header.latch_plane_size, LATCH_PLANES
	)
	var sprite_data := _read_planes(
		files, "EGASPRIT." + extension, graphics.header.sprite_plane_size, SPRITE_PLANES
	)
	if latch.is_empty() or sprite_data.is_empty():
		return null

	graphics._decode_font(latch)
	graphics._decode_tiles(latch)
	graphics._decode_bitmaps(latch)
	graphics._decode_sprites(sprite_data)
	return graphics


## Returns the bitmap with the given name, or null if there is none.
func find_bitmap(bitmap_name: String) -> Image:
	var index := bitmap_index(bitmap_name)
	return bitmaps[index] if index >= 0 else null


## The number of the bitmap with the given name, or -1 if there is none.
func bitmap_index(bitmap_name: String) -> int:
	if header == null:
		return -1
	for i in mini(header.bitmaps.size(), bitmaps.size()):
		if header.bitmaps[i].name == bitmap_name:
			return i
	return -1


## Whether tile [param tile] has a mask: the next tile, drawn only in black
## and white. A masked tile (behavior -2 in Keen 2 and 3) is drawn in front
## of the sprites only where its mask is black. The last tile has none.
func has_tile_mask(tile: int) -> bool:
	if tile < 0 or tile + 1 >= tiles.size():
		return false
	if _black_and_white.size() != tiles.size():
		_find_black_and_white_tiles()
	return _black_and_white[tile + 1] != 0


## Combines all tiles into one image, [param columns] tiles wide.
## Tile number n ends up at column n % columns, row n / columns.
func create_tile_atlas(columns: int) -> Image:
	return _create_atlas(tiles, TILE_SIZE, columns)


## Combines all font characters into one image, [param columns] characters wide.
func create_font_atlas(columns: int) -> Image:
	return _create_atlas(font_chars, FONT_CHAR_SIZE, columns)


func _find_black_and_white_tiles() -> void:
	_black_and_white.resize(tiles.size())
	for index in tiles.size():
		_black_and_white[index] = 1 if is_black_and_white(tiles[index]) else 0


## Whether every pixel of [param image] is black or white (EGA 0 or 15).
static func is_black_and_white(image: Image) -> bool:
	var rgba := image
	if image.get_format() != Image.FORMAT_RGBA8:
		rgba = image.duplicate() as Image
		rgba.convert(Image.FORMAT_RGBA8)
	var data := rgba.get_data()
	for start in range(0, data.size(), _BYTES_PER_PIXEL):
		var pixel := data.slice(start, start + _BYTES_PER_PIXEL)
		if pixel != _MASK_BLACK and pixel != _MASK_WHITE:
			return false
	return true


## Reads a planar data file. Depending on the game version the file is either
## stored as-is or LZW-compressed; the file size tells which one it is.
static func _read_planes(
	files: GameFiles, file_name: String, plane_size: int, plane_count: int
) -> PackedByteArray:
	var raw := files.read(file_name)
	var expected_size := plane_size * plane_count
	if raw.size() == expected_size:
		return raw

	var decompressed := LzwDecompressor.decompress(raw)
	if decompressed.size() != expected_size:
		push_error(
			(
				"%s should hold %d bytes but holds %d."
				% [file_name, expected_size, decompressed.size()]
			)
		)
		return PackedByteArray()
	return decompressed


func _decode_font(latch: PackedByteArray) -> void:
	var bytes_per_char := FONT_CHAR_SIZE * FONT_CHAR_SIZE / 8
	for i in header.font_char_count:
		var start := header.font_offset + i * bytes_per_char
		font_chars.append(_decode_latch_image(latch, start, FONT_CHAR_SIZE / 8, FONT_CHAR_SIZE))


func _decode_tiles(latch: PackedByteArray) -> void:
	var bytes_per_tile := TILE_SIZE * TILE_SIZE / 8
	for i in header.tile_count:
		var start := header.tile_offset + i * bytes_per_tile
		tiles.append(_decode_latch_image(latch, start, TILE_SIZE / 8, TILE_SIZE))


func _decode_bitmaps(latch: PackedByteArray) -> void:
	for entry in header.bitmaps:
		var start := header.bitmap_offset + entry.offset
		bitmaps.append(_decode_latch_image(latch, start, entry.width_in_bytes, entry.height))


func _decode_sprites(sprite_data: PackedByteArray) -> void:
	var plane_size := header.sprite_plane_size
	for entry in header.sprites:
		var start := header.sprite_offset + entry.offset
		var plane_starts := _plane_starts(start, plane_size)
		var colors := EgaPlanarDecoder.decode_colors(
			sprite_data, plane_starts, entry.width_in_bytes, entry.height
		)
		var mask := EgaPlanarDecoder.decode_single_plane(
			sprite_data, start + plane_size * SPRITE_MASK_PLANE, entry.width_in_bytes, entry.height
		)
		sprites.append(
			EgaPalette.create_image(colors, entry.width_in_bytes * 8, entry.height, mask)
		)


func _decode_latch_image(
	latch: PackedByteArray, start: int, width_in_bytes: int, height: int
) -> Image:
	var plane_starts := _plane_starts(start, header.latch_plane_size)
	var colors := EgaPlanarDecoder.decode_colors(latch, plane_starts, width_in_bytes, height)
	return EgaPalette.create_image(colors, width_in_bytes * 8, height)


## The color planes are stored one after another, each [param plane_size] long.
static func _plane_starts(start: int, plane_size: int) -> PackedInt32Array:
	var starts := PackedInt32Array()
	for plane in EgaPlanarDecoder.COLOR_PLANES:
		starts.append(start + plane * plane_size)
	return starts


static func _create_atlas(images: Array[Image], cell_size: int, columns: int) -> Image:
	var rows := ceili(images.size() / float(columns))
	var atlas := Image.create_empty(
		columns * cell_size, rows * cell_size, false, Image.FORMAT_RGBA8
	)
	var cell := Rect2i(0, 0, cell_size, cell_size)
	for i in images.size():
		var position := Vector2i(i % columns, i / columns) * cell_size
		atlas.blit_rect(images[i], cell, position)
	return atlas
