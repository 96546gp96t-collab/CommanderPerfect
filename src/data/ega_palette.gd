class_name EgaPalette
extends RefCounted
## The 16 standard EGA colors and helpers to turn color indices into images.

const _RGB_HEX: PackedStringArray = [
	"000000",  #  0 black
	"0000AA",  #  1 blue
	"00AA00",  #  2 green
	"00AAAA",  #  3 cyan
	"AA0000",  #  4 red
	"AA00AA",  #  5 magenta
	"AA5500",  #  6 brown
	"AAAAAA",  #  7 light gray
	"555555",  #  8 dark gray
	"5555FF",  #  9 light blue
	"55FF55",  # 10 light green
	"55FFFF",  # 11 light cyan
	"FF5555",  # 12 light red
	"FF55FF",  # 13 light magenta
	"FFFF55",  # 14 yellow
	"FFFFFF",  # 15 white
]

## The color the font draws its background in.
const WHITE := 15

## RGBA bytes for every palette entry, four bytes per color.
static var _rgba_bytes := _build_rgba_bytes()


static func color(index: int) -> Color:
	return Color.html(_RGB_HEX[index])


## Builds an RGBA image from one color index (0-15) per pixel.
## A pixel whose entry in [param transparent] is non-zero becomes see-through.
static func create_image(
	indices: PackedByteArray,
	width: int,
	height: int,
	transparent := PackedByteArray(),
) -> Image:
	var has_mask := not transparent.is_empty()
	var rgba := PackedByteArray()
	rgba.resize(width * height * 4)
	for pixel in width * height:
		var target := pixel * 4
		if has_mask and transparent[pixel] != 0:
			continue  # Bytes are already zero: fully transparent black.
		var source := indices[pixel] * 4
		rgba[target] = _rgba_bytes[source]
		rgba[target + 1] = _rgba_bytes[source + 1]
		rgba[target + 2] = _rgba_bytes[source + 2]
		rgba[target + 3] = 255
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba)


static func _build_rgba_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()
	for hex in _RGB_HEX:
		var c := Color.html(hex)
		bytes.append_array([c.r8, c.g8, c.b8, 255])
	return bytes
