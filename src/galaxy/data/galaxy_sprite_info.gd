class_name GalaxySpriteInfo
extends RefCounted
## One entry of the sprite table (EGAGRAPH chunk 2, 18 bytes): the size of
## the picture, where its origin lies and the hit box the game collides
## with. Origin and box are in global units (16 per pixel), as the original
## keeps them, both relative to the object's position: the picture is drawn
## at position + origin. Every frame of an animation has its own box
## (Keen 4 v1.0: a standing Keen's box ends where his feet do). See
## docs/keen4/file-formats.md.

const ENTRY_SIZE := 18
const UNITS_PER_PIXEL := 16
const PIXELS_PER_BYTE := 8

## The picture's size in pixels.
var width := 0
var height := 0
var width_in_bytes := 0
## Where the picture's top-left corner lies relative to the object.
var origin := Vector2i.ZERO
## The hit box relative to the object: left, top, right, bottom.
var box_left := 0
var box_top := 0
var box_right := 0
var box_bottom := 0
## How many shifted copies the original made for smooth movement.
var shifts := 0


## Every entry of the sprite table [param table].
static func parse_table(table: PackedByteArray) -> Array[GalaxySpriteInfo]:
	var entries: Array[GalaxySpriteInfo] = []
	for index in table.size() / ENTRY_SIZE:
		entries.append(parse(table, index * ENTRY_SIZE))
	return entries


## The entry at [param offset] of [param table].
static func parse(table: PackedByteArray, offset: int) -> GalaxySpriteInfo:
	var info := GalaxySpriteInfo.new()
	info.width_in_bytes = table.decode_s16(offset)
	info.width = info.width_in_bytes * PIXELS_PER_BYTE
	info.height = table.decode_s16(offset + 2)
	info.origin = Vector2i(table.decode_s16(offset + 4), table.decode_s16(offset + 6))
	info.box_left = table.decode_s16(offset + 8)
	info.box_top = table.decode_s16(offset + 10)
	info.box_right = table.decode_s16(offset + 12)
	info.box_bottom = table.decode_s16(offset + 14)
	info.shifts = table.decode_s16(offset + 16)
	return info


## The hit box in the picture's pixels, relative to its top-left corner.
func hit_box_pixels() -> Rect2i:
	var left := (box_left - origin.x) / UNITS_PER_PIXEL
	var top := (box_top - origin.y) / UNITS_PER_PIXEL
	var right := (box_right - origin.x) / UNITS_PER_PIXEL
	var bottom := (box_bottom - origin.y) / UNITS_PER_PIXEL
	return Rect2i(left, top, right - left, bottom - top)
