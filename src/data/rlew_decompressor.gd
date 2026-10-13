class_name RlewDecompressor
extends RefCounted
## Decompresses the RLEW ("run-length encoded words") format of Keen 1 levels.
##
## File layout:
##   u32   decompressed size in bytes
##   ...   16-bit words
##
## A word equal to MARKER is followed by two more words, a count and a value,
## meaning "repeat value count times". Every other word is copied as-is.

const MARKER := 0xFEFE
const HEADER_SIZE := 4


## Returns the decompressed 16-bit words, or an empty array when the data is
## corrupt.
static func decompress(compressed: PackedByteArray) -> PackedInt32Array:
	if compressed.size() < HEADER_SIZE:
		push_error("RLEW data is too short to contain a header.")
		return PackedInt32Array()

	var expected_words := compressed.decode_u32(0) / 2
	var words := PackedInt32Array()
	var position := HEADER_SIZE

	while words.size() < expected_words:
		if position + 2 > compressed.size():
			push_error("RLEW data ended after %d of %d words." % [words.size(), expected_words])
			return PackedInt32Array()

		var word := compressed.decode_u16(position)
		if word == MARKER:
			if position + 6 > compressed.size():
				push_error("RLEW data ends inside a repeat block.")
				return PackedInt32Array()
			var count := compressed.decode_u16(position + 2)
			var value := compressed.decode_u16(position + 4)
			for i in count:
				words.append(value)
			position += 6
		else:
			words.append(word)
			position += 2

	words.resize(expected_words)
	return words
