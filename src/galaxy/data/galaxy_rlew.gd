class_name GalaxyRlew
extends RefCounted
## Expands the RLEW step of the Galaxy maps (after [GalaxyCarmack]). Unlike
## Keen 1's [RlewDecompressor], the marker word ("tag") is not fixed: it
## comes from MAPHEAD (0xABCD in Keen 4), and the length is a 16-bit word.
##
## The first word is the length in bytes. Then a word equal to the tag is
## followed by a count and a value ("repeat value count times"); every other
## word is copied as it is.


## Expands [param words] (the output of [method GalaxyCarmack.expand]).
## Returns the plane's words, or an empty array when the data is corrupt.
static func expand(words: PackedInt32Array, tag: int) -> PackedInt32Array:
	if words.is_empty():
		push_error("RLEW data is too short to hold its length.")
		return PackedInt32Array()
	var word_count := words[0] / 2
	var plane := PackedInt32Array()
	plane.resize(word_count)
	var written := 0
	var position := 1
	while written < word_count:
		if position >= words.size():
			push_error("RLEW data ended after %d of %d words." % [written, word_count])
			return PackedInt32Array()
		var word := words[position]
		if word != tag:
			plane[written] = word
			written += 1
			position += 1
			continue
		if position + 2 >= words.size():
			push_error("RLEW data ends inside a repeat.")
			return PackedInt32Array()
		var count := words[position + 1]
		if written + count > word_count:
			push_error("RLEW repeat runs past the end of the plane.")
			return PackedInt32Array()
		var value := words[position + 2]
		for index in count:
			plane[written + index] = value
		written += count
		position += 3
	return plane
