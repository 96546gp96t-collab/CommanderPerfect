class_name EgaPlanarDecoder
extends RefCounted
## Decodes EGA "planar" graphics into one color index per pixel.
##
## EGA hardware stores an image as four separate bit planes. Each plane holds
## one bit of every pixel, eight pixels per byte with the leftmost pixel in the
## highest bit. The pixel's color index combines the planes like this:
##   bit 0 = plane 0 (blue), bit 1 = plane 1 (green),
##   bit 2 = plane 2 (red),  bit 3 = plane 3 (intensity).
##
## Sprites add a fifth plane: the mask. A set mask bit means "transparent".

const COLOR_PLANES := 4


## Returns one color index (0-15) per pixel.
## [param plane_starts] holds the byte position of the image in each of the
## four color planes; [param width_in_bytes] is the image width divided by 8.
static func decode_colors(
	data: PackedByteArray,
	plane_starts: PackedInt32Array,
	width_in_bytes: int,
	height: int,
) -> PackedByteArray:
	var width := width_in_bytes * 8
	var indices := PackedByteArray()
	indices.resize(width * height)
	for plane in COLOR_PLANES:
		_add_plane_bits(data, plane_starts[plane], width_in_bytes, height, 1 << plane, indices)
	return indices


## Returns one value per pixel: 1 where the plane bit is set, 0 elsewhere.
## Used for the sprite mask plane.
static func decode_single_plane(
	data: PackedByteArray,
	plane_start: int,
	width_in_bytes: int,
	height: int,
) -> PackedByteArray:
	var bits := PackedByteArray()
	bits.resize(width_in_bytes * 8 * height)
	_add_plane_bits(data, plane_start, width_in_bytes, height, 1, bits)
	return bits


static func _add_plane_bits(
	data: PackedByteArray,
	start: int,
	width_in_bytes: int,
	height: int,
	value: int,
	target: PackedByteArray,
) -> void:
	var pixel := 0
	for byte_index in width_in_bytes * height:
		var byte := data[start + byte_index]
		for bit in range(7, -1, -1):
			if byte & (1 << bit):
				target[pixel] |= value
			pixel += 1
