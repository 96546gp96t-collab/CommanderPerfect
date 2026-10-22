class_name GalaxyHuffman
extends RefCounted
## The Huffman dictionaries of the Galaxy engine (EGADICT for the graphics,
## AUDIODCT for the sounds), and expanding data with them. See
## docs/keen4/file-formats.md, "Huffman".
##
## A dictionary is 255 nodes of two 16-bit values: what to do after a 0 bit
## and after a 1 bit. A value below 256 is a byte (a leaf); 256 or more is
## the node (value - 256). Expanding starts at the root, reads the bits of
## each byte from the lowest up, and writes a byte at every leaf.

const NODE_COUNT := 255
const ROOT := NODE_COUNT - 1
const BYTE_VALUES := 256
## The bytes of a dictionary as the program stores it (two words a node).
const SIZE := NODE_COUNT * 4
## Each dictionary takes 1024 bytes in memory: 256 nodes, the last unused.
const STORED_SIZE := 1024
const BITS_PER_BYTE := 8

## The value after a 0 bit at [code]node * 2[/code], after a 1 bit at
## [code]node * 2 + 1[/code].
var _links := PackedInt32Array()


## The dictionary at [param offset] in [param data], or null when the bytes
## there are not a complete tree ([method is_tree_at]).
static func from_bytes(data: PackedByteArray, offset := 0) -> GalaxyHuffman:
	if not is_tree_at(data, offset):
		return null
	var dictionary := GalaxyHuffman.new()
	dictionary._links.resize(NODE_COUNT * 2)
	for index in NODE_COUNT * 2:
		dictionary._links[index] = data.decode_u16(offset + index * 2)
	return dictionary


## Whether [param data] holds a complete tree at [param offset]: every byte
## 0-255 is a leaf exactly once, every node but the root is reached from
## exactly one place, and the root from none. Random bytes and program
## code never pass, so this also finds the dictionaries in the EXE.
static func is_tree_at(data: PackedByteArray, offset: int) -> bool:
	if offset < 0 or offset + SIZE > data.size():
		return false
	var seen := PackedByteArray()
	seen.resize(BYTE_VALUES + NODE_COUNT)
	for index in NODE_COUNT * 2:
		var value := data.decode_u16(offset + index * 2)
		# Value 256 + ROOT would point back at the root.
		if value >= BYTE_VALUES + ROOT or seen[value] != 0:
			return false
		seen[value] = 1
	return true


## Expands [param length] bytes from [param source], starting at
## [param start]. Returns fewer bytes when the source ends first.
func expand(source: PackedByteArray, start: int, length: int) -> PackedByteArray:
	var result := _expand(source, start, source.size(), length)
	return result[0]


## How many bytes of [param source] (from [param start]) expanding
## [param length] bytes reads, or -1 when the source ends first. A chunk is
## never shorter than this, and at most a few bytes longer, which tells
## whether a chunk without a length holds [param length] bytes.
func bytes_needed(source: PackedByteArray, start: int, length: int) -> int:
	var result := _expand(source, start, source.size(), length)
	var expanded: PackedByteArray = result[0]
	return result[1] if expanded.size() == length else -1


## Expands everything from [param start] up to [param end]. The last byte
## may hold a few bits of padding, so the result can be a few bytes longer
## than what was packed.
func expand_all(source: PackedByteArray, start: int, end: int) -> PackedByteArray:
	var result := _expand(source, start, mini(end, source.size()), -1)
	return result[0]


## Returns [the bytes, the source bytes read]. [param length] -1 means
## "until [param end]".
func _expand(source: PackedByteArray, start: int, end: int, length: int) -> Array:
	var output := PackedByteArray()
	if length >= 0:
		output.resize(length)
	var written := 0
	var node := ROOT
	var position := start
	var links := _links
	while position < end and (length < 0 or written < length):
		var byte := source[position]
		position += 1
		for bit in BITS_PER_BYTE:
			var value := links[node * 2 + ((byte >> bit) & 1)]
			if value < BYTE_VALUES:
				if length < 0:
					output.append(value)
				else:
					output[written] = value
				written += 1
				node = ROOT
				if written == length:
					break
			else:
				node = value - BYTE_VALUES
	if length >= 0 and written < length:
		output.resize(written)
	return [output, position - start]
