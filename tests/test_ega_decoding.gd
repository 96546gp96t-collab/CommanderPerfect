extends "res://tests/test_case.gd"
## Tests for planar EGA decoding and palette conversion.


func test_planes_combine_into_color_indices() -> void:
	# One row of 8 pixels, one byte per plane. The first pixel only has its
	# plane 0 bit set (blue, index 1), the second pixel has all four bits set
	# (white, index 15), all other pixels are black.
	var data := PackedByteArray([0b1100_0000, 0b0100_0000, 0b0100_0000, 0b0100_0000])
	var colors := EgaPlanarDecoder.decode_colors(data, PackedInt32Array([0, 1, 2, 3]), 1, 1)
	assert_equal(colors, PackedByteArray([1, 15, 0, 0, 0, 0, 0, 0]), "color indices")


func test_mask_bits_make_pixels_transparent() -> void:
	var colors := PackedByteArray([15, 15])
	var transparent := PackedByteArray([0, 1])
	var image := EgaPalette.create_image(colors, 2, 1, transparent)
	assert_equal(image.get_pixel(0, 0), Color.WHITE, "opaque pixel")
	assert_equal(image.get_pixel(1, 0).a, 0.0, "alpha of masked pixel")
