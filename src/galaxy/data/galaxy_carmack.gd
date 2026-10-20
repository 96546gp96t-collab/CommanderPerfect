class_name GalaxyCarmack
extends RefCounted
## Expands the "Carmack" compression of the Galaxy maps (the first of the two
## steps per plane in GAMEMAPS; [GalaxyRlew] is the second). See
## docs/keen4/file-formats.md, "GAMEMAPS.CK4 and MAPHEAD".
##
## The data is 16-bit words. A word whose high byte is [constant NEAR] copies
## its low byte's number of words from a few words back (the next byte says
## how far, counted back from the end of the output); [constant FAR] copies
## from a place counted from the start of the output (the next word). A
## count of 0 marks a plain word with that high byte, whose low byte follows.

const NEAR := 0xA7
const FAR := 0xA8


## Expands the plane that starts at [param start] in [param source]: a
## 16-bit length in bytes, then the compressed words. Returns the words, or
## an empty array when the data is corrupt.
static func expand(source: PackedByteArray, start: int) -> PackedInt32Array:
	if start < 0 or start + 2 > source.size():
		push_error("Carmack data is too short to hold its length.")
		return PackedInt32Array()
	var word_count := source.decode_u16(start) / 2
	var words := PackedInt32Array()
	words.resize(word_count)
	var written := 0
	var position := start + 2
	while written < word_count:
		if position + 2 > source.size():
			push_error("Carmack data ended after %d of %d words." % [written, word_count])
			return PackedInt32Array()
		var word := source.decode_u16(position)
		position += 2
		var marker := word >> 8
		if marker != NEAR and marker != FAR:
			words[written] = word
			written += 1
			continue
		var count := word & 0xFF
		if position >= source.size():
			push_error("Carmack data ends inside a copy.")
			return PackedInt32Array()
		if count == 0:
			words[written] = (marker << 8) | source[position]
			written += 1
			position += 1
			continue
		var from := 0
		if marker == NEAR:
			from = written - source[position]
			position += 1
		else:
			if position + 2 > source.size():
				push_error("Carmack data ends inside a far copy.")
				return PackedInt32Array()
			from = source.decode_u16(position)
			position += 2
		if from < 0 or from >= written or written + count > word_count:
			push_error("Carmack copy at word %d points outside the plane." % written)
			return PackedInt32Array()
		for index in count:
			words[written] = words[from + index]
			written += 1
	return words
