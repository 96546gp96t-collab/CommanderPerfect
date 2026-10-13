class_name EgaHeader
extends RefCounted
## Parsed contents of EGAHEAD.CK1: the table of contents for all graphics.
##
## The graphics themselves live in two other files:
##   EGALATCH.CK1  four color planes with the font, the 16x16 tiles and the
##                 full-screen bitmaps (title screen, logos, ...)
##   EGASPRIT.CK1  four color planes plus a mask plane with all sprites
##
## Every offset below is a byte position inside one plane of those files.
## See docs/file-formats.md for the full byte layout.

## Keen 1 version 1.34 has six extra bytes in front of the counts; all other
## versions start them at byte 16.
const COUNTS_START_STANDARD := 16
const COUNTS_START_V1_34 := 22

const BITMAP_ENTRY_SIZE := 16
const SPRITE_ENTRY_SIZE := 128
const FONT_CHAR_BYTES := 8  # 8x8 pixels, 1 byte per row, per plane
const TILE_BYTES := 32  # 16x16 pixels, 2 bytes per row, per plane

## Sprite hitboxes are stored as fixed-point numbers with 8 fractional bits.
const HITBOX_FIXED_POINT_SHIFT := 8

var latch_plane_size: int
var sprite_plane_size: int
var font_char_count: int
var font_offset: int
var tile_count: int
var tile_offset: int
var bitmap_offset: int
var sprite_offset: int
var bitmaps: Array[BitmapEntry] = []
var sprites: Array[SpriteEntry] = []


## Returns the parsed header, or null when the data does not look like a
## Keen 1 EGAHEAD file.
static func parse(data: PackedByteArray) -> EgaHeader:
	if data.size() < COUNTS_START_V1_34 + 32:
		push_error("EGAHEAD is too small (%d bytes)." % data.size())
		return null

	for counts_start in [COUNTS_START_STANDARD, COUNTS_START_V1_34]:
		var header := EgaHeader.new()
		header._read_main_fields(data, counts_start)
		if header._is_plausible():
			header._read_bitmap_table(data, data.decode_u32(8))
			header._read_sprite_table(data, data.decode_u32(12))
			return header

	push_error("EGAHEAD has an unknown layout.")
	return null


func _read_main_fields(data: PackedByteArray, counts_start: int) -> void:
	latch_plane_size = data.decode_u32(0)
	sprite_plane_size = data.decode_u32(4)
	# Each item below is a u16 count followed by a u32 offset.
	var position := counts_start
	font_char_count = data.decode_u16(position)
	font_offset = data.decode_u32(position + 2)
	position += 6
	position += 6  # Unused "screen tiles" count and offset.
	tile_count = data.decode_u16(position)
	tile_offset = data.decode_u32(position + 2)
	position += 6
	var bitmap_count := data.decode_u16(position)
	bitmap_offset = data.decode_u32(position + 2)
	position += 6
	var sprite_count := data.decode_u16(position)
	sprite_offset = data.decode_u32(position + 2)
	bitmaps.resize(bitmap_count)
	sprites.resize(sprite_count)


## The font sits directly in front of the tiles, and the tiles must fit in a
## latch plane. A header read with the wrong layout fails these checks.
func _is_plausible() -> bool:
	var font_end := font_offset + font_char_count * FONT_CHAR_BYTES
	var tiles_end := tile_offset + tile_count * TILE_BYTES
	return (
		tile_count > 0
		and font_end == tile_offset
		and tiles_end <= latch_plane_size
		and bitmap_offset <= latch_plane_size
	)


func _read_bitmap_table(data: PackedByteArray, table_start: int) -> void:
	for i in bitmaps.size():
		var position := table_start + i * BITMAP_ENTRY_SIZE
		var entry := BitmapEntry.new()
		entry.width_in_bytes = data.decode_u16(position)
		entry.height = data.decode_u16(position + 2)
		entry.offset = data.decode_u32(position + 4)
		entry.name = _read_name(data, position + 8, 8)
		bitmaps[i] = entry


func _read_sprite_table(data: PackedByteArray, table_start: int) -> void:
	for i in sprites.size():
		var position := table_start + i * SPRITE_ENTRY_SIZE
		var entry := SpriteEntry.new()
		entry.width_in_bytes = data.decode_u16(position)
		entry.height = data.decode_u16(position + 2)
		# The location is stored in 16-byte "paragraphs" plus a byte offset.
		entry.offset = data.decode_u16(position + 6) * 16 + data.decode_u16(position + 4)
		var left := data.decode_s16(position + 8) >> HITBOX_FIXED_POINT_SHIFT
		var top := data.decode_s16(position + 10) >> HITBOX_FIXED_POINT_SHIFT
		var right := data.decode_s16(position + 12) >> HITBOX_FIXED_POINT_SHIFT
		var bottom := data.decode_s16(position + 14) >> HITBOX_FIXED_POINT_SHIFT
		entry.hitbox = Rect2i(left, top, right - left, bottom - top)
		entry.name = _read_name(data, position + 16, 12)
		sprites[i] = entry


## Reads a zero-terminated ASCII name of at most [param max_length] bytes.
static func _read_name(data: PackedByteArray, start: int, max_length: int) -> String:
	var name_bytes := data.slice(start, start + max_length)
	var end := name_bytes.find(0)
	if end != -1:
		name_bytes = name_bytes.slice(0, end)
	return name_bytes.get_string_from_ascii().strip_edges()


## A full-screen picture in EGALATCH, such as the title screen.
class BitmapEntry:
	extends RefCounted
	var name: String
	var width_in_bytes: int
	var height: int
	## Byte position inside a latch plane, relative to [member EgaHeader.bitmap_offset].
	var offset: int


## A moving object in EGASPRIT, such as one animation frame of Keen.
class SpriteEntry:
	extends RefCounted
	var name: String
	var width_in_bytes: int
	var height: int
	## Byte position inside a sprite plane, relative to [member EgaHeader.sprite_offset].
	var offset: int
	## Area that counts for collisions, in pixels relative to the sprite's corner.
	var hitbox: Rect2i
