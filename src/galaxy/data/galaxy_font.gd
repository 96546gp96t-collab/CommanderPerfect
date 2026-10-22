class_name GalaxyFont
extends RefCounted
## One of the proportional fonts of a Galaxy episode (EGAGRAPH, right after
## the tables): a height, then for each of the 256 characters where its
## pixels start and how wide it is, then one bit per pixel, a row at a time
## (the leftmost pixel in the highest bit). See docs/keen4/file-formats.md.

const CHARACTERS := 256
const HEADER_SIZE := 2 + CHARACTERS * 2 + CHARACTERS
const WIDTHS_START := 2 + CHARACTERS * 2
const PIXELS_PER_BYTE := 8

var height := 0
var _offsets := PackedInt32Array()
var _widths := PackedByteArray()
var _data := PackedByteArray()


## The font in [param chunk] (the expanded font chunk); null when it is too
## short for its header.
static func parse(chunk: PackedByteArray) -> GalaxyFont:
	if chunk.size() < HEADER_SIZE:
		push_error("A font chunk of %d bytes is too short." % chunk.size())
		return null
	var font := GalaxyFont.new()
	font.height = chunk.decode_u16(0)
	font._offsets.resize(CHARACTERS)
	for character in CHARACTERS:
		font._offsets[character] = chunk.decode_u16(2 + character * 2)
	font._widths = chunk.slice(WIDTHS_START, WIDTHS_START + CHARACTERS)
	font._data = chunk
	return font


## How wide [param character] is in pixels (0 for one the font lacks).
func width_of(character: int) -> int:
	if character < 0 or character >= CHARACTERS:
		return 0
	return _widths[character]


## How wide [param text] is in pixels.
func text_width(text: String) -> int:
	var total := 0
	for index in text.length():
		total += width_of(text.unicode_at(index))
	return total


## Whether pixel ([param x], [param y]) of [param character] is set.
func is_set(character: int, x: int, y: int) -> bool:
	var width := width_of(character)
	if x < 0 or x >= width or y < 0 or y >= height:
		return false
	var row_bytes := ceili(float(width) / PIXELS_PER_BYTE)
	var position := _offsets[character] + y * row_bytes + x / PIXELS_PER_BYTE
	if position >= _data.size():
		return false
	return _data[position] & (0x80 >> (x % PIXELS_PER_BYTE)) != 0


## [param text] in [param color] on a see-through image, one row high.
func render(text: String, color: Color) -> Image:
	var image := Image.create_empty(
		maxi(1, text_width(text)), maxi(1, height), false, Image.FORMAT_RGBA8
	)
	var left := 0
	for index in text.length():
		var character := text.unicode_at(index)
		for y in height:
			for x in width_of(character):
				if is_set(character, x, y):
					image.set_pixel(left + x, y, color)
		left += width_of(character)
	return image
