class_name LzwDecompressor
extends RefCounted
## Decompresses the LZW variant that Keen 1 uses for EGALATCH and EGASPRIT.
##
## File layout:
##   u32   decompressed size in bytes
##   u16   maximum code width in bits (12 in practice)
##   ...   codes, packed most-significant bit first, starting at 9 bits wide
##
## Codes 0-255 stand for a single byte. Code 256 marks an error and code 257 the
## end of the data, so new dictionary entries start at 258. The code width grows
## by one bit as soon as the dictionary fills up the current width.

const HEADER_SIZE := 6
const START_CODE_WIDTH := 9
const ERROR_CODE := 256
const END_CODE := 257
const FIRST_FREE_CODE := 258


## Returns the decompressed bytes, or an empty array when the data is corrupt.
static func decompress(compressed: PackedByteArray) -> PackedByteArray:
	if compressed.size() < HEADER_SIZE:
		push_error("LZW data is too short to contain a header.")
		return PackedByteArray()

	var expected_size := compressed.decode_u32(0)
	var max_code_width := compressed.decode_u16(4)
	var max_dictionary_size := 1 << max_code_width
	var dictionary := _create_initial_dictionary()
	var reader := _BitReader.new(compressed, HEADER_SIZE)
	var code_width := START_CODE_WIDTH
	var output := PackedByteArray()

	if not reader.has_bits(code_width):
		push_error("LZW data holds no codes.")
		return PackedByteArray()
	var previous_code := reader.read(code_width)
	if previous_code >= ERROR_CODE:
		push_error("LZW data must start with a single byte code.")
		return PackedByteArray()
	output.append_array(dictionary[previous_code])

	while output.size() < expected_size and reader.has_bits(code_width):
		var code := reader.read(code_width)
		if code == ERROR_CODE or code == END_CODE:
			break
		if code > dictionary.size():
			push_error("LZW data refers to unknown code %d." % code)
			return PackedByteArray()

		var previous: PackedByteArray = dictionary[previous_code]
		var entry: PackedByteArray
		if code < dictionary.size():
			entry = dictionary[code]
		else:
			# The code is the entry that is being defined right now ("KwKwK").
			entry = previous + previous.slice(0, 1)

		if dictionary.size() < max_dictionary_size:
			dictionary.append(previous + entry.slice(0, 1))
			var code_width_is_full := dictionary.size() >= (1 << code_width) - 1
			if code_width_is_full and code_width < max_code_width:
				code_width += 1

		output.append_array(entry)
		previous_code = code

	if output.size() < expected_size:
		push_error("LZW data ended after %d of %d bytes." % [output.size(), expected_size])
		return PackedByteArray()
	output.resize(expected_size)
	return output


static func _create_initial_dictionary() -> Array[PackedByteArray]:
	var dictionary: Array[PackedByteArray] = []
	for byte in 256:
		dictionary.append(PackedByteArray([byte]))
	# Placeholders for the error and end codes, so new entries start at 258.
	dictionary.append(PackedByteArray())
	dictionary.append(PackedByteArray())
	return dictionary


## Reads codes of a variable bit width, most-significant bit first.
class _BitReader:
	var _data: PackedByteArray
	var _position: int
	var _buffer := 0
	var _buffered_bits := 0

	func _init(data: PackedByteArray, start: int) -> void:
		_data = data
		_position = start

	func has_bits(count: int) -> bool:
		return (_data.size() - _position) * 8 + _buffered_bits >= count

	## Callers must check [method has_bits] first.
	func read(width: int) -> int:
		while _buffered_bits < width:
			_buffer = ((_buffer << 8) | _data[_position]) & 0xFFFFFF
			_position += 1
			_buffered_bits += 8
		_buffered_bits -= width
		return (_buffer >> _buffered_bits) & ((1 << width) - 1)
