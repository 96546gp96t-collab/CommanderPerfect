class_name LzexeDecompressor
extends RefCounted
## Unpacks the compressed program image of an EXE packed with LZEXE 0.91.
##
## The stream mixes 16-bit control words with plain bytes. Control bits are
## taken from the current word, lowest bit first. As soon as the last bit of a
## word has been taken, the next word is read, before any bytes that follow.
## Commands:
##   1               copy one literal byte
##   0 0 b1 b0, d    short copy: length 2 + (b1 * 2 + b0), distance d - 256
##   0 1, lo, hi     long copy: distance 13 bits from lo and the top 5 bits of
##                   hi, length (hi & 7) + 2; when that is 0, a length byte n
##                   follows: 0 ends the data, 1 is a segment marker without
##                   output, otherwise the length is n + 1
## A distance points back into the output that was already written.

const WORD_BITS := 16
const SHORT_COPY_MIN_LENGTH := 2
const SHORT_DISTANCE_BIAS := 256
const LONG_LENGTH_MASK := 0x07
const LONG_DISTANCE_HIGH_MASK := 0xF8
const LONG_DISTANCE_HIGH_SHIFT := 5
const LONG_DISTANCE_SIGN_BITS := 0xE000
const LONG_COPY_MIN_LENGTH := 2
const END_OF_DATA := 0
const SEGMENT_MARKER := 1

var _data: PackedByteArray
var _position := 0
var _bits := 0
var _bits_left := 0
var _output := PackedByteArray()
var _error := ""


## Returns the unpacked image, or an empty array when the data is corrupt.
static func decompress(data: PackedByteArray) -> PackedByteArray:
	var decompressor := LzexeDecompressor.new()
	decompressor._data = data
	if not decompressor._run():
		push_error("LZEXE data is corrupt: %s" % decompressor._error)
		return PackedByteArray()
	return decompressor._output


func _run() -> bool:
	_load_word()
	while _error.is_empty():
		if _read_bit() == 1:
			_output.append(_read_byte())
			continue
		var length: int
		var distance: int
		if _read_bit() == 0:
			length = SHORT_COPY_MIN_LENGTH + _read_bit() * 2 + _read_bit()
			distance = _read_byte() - SHORT_DISTANCE_BIAS
		else:
			var low := _read_byte()
			var high := _read_byte()
			distance = (
				(low | ((high & LONG_DISTANCE_HIGH_MASK) << LONG_DISTANCE_HIGH_SHIFT))
				| LONG_DISTANCE_SIGN_BITS
			)
			distance -= 1 << WORD_BITS
			length = high & LONG_LENGTH_MASK
			if length == 0:
				var count := _read_byte()
				if count == END_OF_DATA:
					return _error.is_empty()
				if count == SEGMENT_MARKER:
					continue
				length = count + 1
			else:
				length += LONG_COPY_MIN_LENGTH
		_copy(distance, length)
	return false


## Copies [param length] bytes from [param distance] (negative) bytes back.
## Byte by byte, because the source may overlap the bytes being written.
func _copy(distance: int, length: int) -> void:
	var source := _output.size() + distance
	if source < 0:
		_error = "copy from before the start of the output"
		return
	for i in length:
		_output.append(_output[source + i])


func _read_bit() -> int:
	var bit := _bits & 1
	_bits >>= 1
	_bits_left -= 1
	if _bits_left == 0:
		_load_word()
	return bit


func _load_word() -> void:
	_bits = _read_byte() | (_read_byte() << 8)
	_bits_left = WORD_BITS


func _read_byte() -> int:
	if _position >= _data.size():
		if _error.is_empty():
			_error = "unexpected end of data"
		return 0
	_position += 1
	return _data[_position - 1]
