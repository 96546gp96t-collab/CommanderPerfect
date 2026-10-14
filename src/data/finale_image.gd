class_name FinaleImage
extends RefCounted
## Decodes FINALE.CK1: the full-screen picture of Keen's house at the end of
## the game.
##
## The file starts with a u32: the size of the four EGA planes together after
## decompression (4 x 8192 bytes). A run-length code follows:
##   byte n with the high bit set   (n & 0x7F) + 1 bytes are copied as they are
##   byte n without it              the next byte is repeated n + 3 times
## Each plane holds a 320x200 picture, row by row; the rest of its 8192 bytes
## is padding (see docs/file-formats.md).

const FILE_NAME := "FINALE.CK1"
const SIZE := Vector2i(320, 200)
const SIZE_BYTES := 4
const LITERAL_FLAG := 0x80
const LITERAL_COUNT_MASK := 0x7F
const MIN_REPEAT := 3


## Returns the picture, or null when the data is damaged.
static func decode(data: PackedByteArray) -> Image:
	if data.size() < SIZE_BYTES:
		push_error("%s is too short." % FILE_NAME)
		return null
	var total := data.decode_u32(0)
	var plane_size := total / EgaPlanarDecoder.COLOR_PLANES
	var row_bytes := SIZE.x / 8
	if plane_size < row_bytes * SIZE.y:
		push_error("%s holds planes of only %d bytes." % [FILE_NAME, plane_size])
		return null
	var planes := _decompress(data, total)
	if planes.size() < total:
		push_error("%s ends before its picture is complete." % FILE_NAME)
		return null
	var starts := PackedInt32Array()
	for plane in EgaPlanarDecoder.COLOR_PLANES:
		starts.append(plane * plane_size)
	var colors := EgaPlanarDecoder.decode_colors(planes, starts, row_bytes, SIZE.y)
	return EgaPalette.create_image(colors, SIZE.x, SIZE.y)


## Loads the picture from the game files; null when it is missing or damaged.
static func load_from(files: GameFiles) -> Image:
	if not files.has_file(FILE_NAME):
		push_error("%s is missing in %s." % [FILE_NAME, files.directory])
		return null
	return decode(files.read(FILE_NAME))


## Unpacks the run-length code into at most [param total] bytes.
static func _decompress(data: PackedByteArray, total: int) -> PackedByteArray:
	var output := PackedByteArray()
	var position := SIZE_BYTES
	while output.size() < total and position < data.size():
		var command := data[position]
		position += 1
		if command & LITERAL_FLAG:
			var count := (command & LITERAL_COUNT_MASK) + 1
			output.append_array(data.slice(position, position + count))
			position += count
		elif position < data.size():
			var repeated := PackedByteArray()
			repeated.resize(command + MIN_REPEAT)
			repeated.fill(data[position])
			output.append_array(repeated)
			position += 1
	return output.slice(0, total)
