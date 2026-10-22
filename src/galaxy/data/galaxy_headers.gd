class_name GalaxyHeaders
extends RefCounted
## The six headers that the Galaxy data files need: the chunk offsets of
## AUDIO and EGAGRAPH, the map offsets of GAMEMAPS with the RLEW tag, the
## tile information, and the two Huffman dictionaries. A header file next
## to the game (EGAHEAD.CK4, EGADICT.CK4, MAPHEAD.CK4, AUDIOHED.CK4,
## AUDIODCT.CK4, as mods have) wins; otherwise each piece is found in the
## program by its content ([GalaxyHeaderSearch]).

const AUDIO_ENTRY_SIZE := 4
const GRAPHICS_ENTRY_SIZE := 3
## Where a piece came from when it was read from a file next to the game.
const FROM_FILE := -1
const NOT_FOUND := -2
## How many chunks a dictionary must expand to count as the file's.
const CHUNKS_TO_CHECK := 3

## The chunk offsets of AUDIO, up to and including its size; -1 = empty.
var audio_offsets := PackedInt32Array()
## The chunk offsets of EGAGRAPH, up to and including its size; -1 = empty.
var graphics_offsets := PackedInt32Array()
## The RLEW tag of the maps (0xABCD in Keen 4).
var map_tag := 0
## Per map slot the offset of its header in GAMEMAPS; 0 = no map.
var map_offsets := PackedInt32Array()
## The tile information and whatever follows it (cut to size by
## [GalaxyTileInfo]).
var tile_info := PackedByteArray()
var audio_dictionary: GalaxyHuffman
var graphics_dictionary: GalaxyHuffman
## Where each [enum GalaxyEpisode.Header] was found: a raw image offset,
## [constant FROM_FILE] or [constant NOT_FOUND].
var found_at: Dictionary[GalaxyEpisode.Header, int] = {}


## Finds every header for the data files in [param files], in the program
## [param image]. Returns null (with the reason) when one is missing.
static func find(image: PackedByteArray, files: GameFiles, episode: GalaxyEpisode) -> GalaxyHeaders:
	var headers := GalaxyHeaders.new()
	var audio := files.read(episode.file_name("AUDIO"))
	var graphics := files.read(episode.file_name("EGAGRAPH"))
	var maps := files.read(episode.file_name("GAMEMAPS"))
	headers._find_tables(image, files, episode, audio.size(), graphics.size())
	headers._find_maps(image, files, episode, maps)
	headers._find_dictionaries(image, files, episode, audio, graphics)
	for piece in GalaxyEpisode.Header.values():
		if headers.found_at.get(piece, NOT_FOUND) == NOT_FOUND:
			push_error(
				(
					"%s was not found in the program or next to it."
					% GalaxyEpisode.Header.keys()[piece]
				)
			)
			return null
	return headers


## The empty chunks and the digitised-sound block of AUDIOHED turned into
## -1, so that every other chunk ends where the next one starts.
func audio_chunk_offsets() -> PackedInt32Array:
	return GalaxyHeaderSearch.without_bogus(audio_offsets)


func _find_tables(
	image: PackedByteArray,
	files: GameFiles,
	episode: GalaxyEpisode,
	audio_size: int,
	graphics_size: int
) -> void:
	var audio_file := episode.file_name("AUDIOHED")
	if files.has_file(audio_file):
		audio_offsets = GalaxyHeaderSearch.offset_table(
			files.read(audio_file), 0, AUDIO_ENTRY_SIZE, audio_size
		)
		found_at[GalaxyEpisode.Header.AUDIOHED] = FROM_FILE
	else:
		var start := GalaxyHeaderSearch.find_offset_table(
			image, AUDIO_ENTRY_SIZE, audio_size, _known(episode, GalaxyEpisode.Header.AUDIOHED)
		)
		audio_offsets = GalaxyHeaderSearch.offset_table(image, start, AUDIO_ENTRY_SIZE, audio_size)
		found_at[GalaxyEpisode.Header.AUDIOHED] = start
	var graphics_file := episode.file_name("EGAHEAD")
	if files.has_file(graphics_file):
		graphics_offsets = GalaxyHeaderSearch.offset_table(
			files.read(graphics_file), 0, GRAPHICS_ENTRY_SIZE, graphics_size
		)
		found_at[GalaxyEpisode.Header.EGAHEAD] = FROM_FILE
	else:
		var start := GalaxyHeaderSearch.find_offset_table(
			image, GRAPHICS_ENTRY_SIZE, graphics_size, _known(episode, GalaxyEpisode.Header.EGAHEAD)
		)
		graphics_offsets = GalaxyHeaderSearch.offset_table(
			image, start, GRAPHICS_ENTRY_SIZE, graphics_size
		)
		found_at[GalaxyEpisode.Header.EGAHEAD] = start
	for piece in [GalaxyEpisode.Header.AUDIOHED, GalaxyEpisode.Header.EGAHEAD]:
		var table := audio_offsets if piece == GalaxyEpisode.Header.AUDIOHED else graphics_offsets
		if table.is_empty():
			found_at[piece] = NOT_FOUND


func _find_maps(
	image: PackedByteArray, files: GameFiles, episode: GalaxyEpisode, maps: PackedByteArray
) -> void:
	var source := image
	var start := -1
	var head_file := episode.file_name("MAPHEAD")
	if files.has_file(head_file):
		source = files.read(head_file)
		start = 0 if GalaxyHeaderSearch.is_map_head(source, 0, maps) else -1
	else:
		start = GalaxyHeaderSearch.find_map_head(
			image, maps, _known(episode, GalaxyEpisode.Header.MAPHEAD)
		)
	if start < 0:
		found_at[GalaxyEpisode.Header.MAPHEAD] = NOT_FOUND
		found_at[GalaxyEpisode.Header.TILEINFO] = NOT_FOUND
		return
	map_tag = source.decode_u16(start)
	map_offsets.resize(GalaxyHeaderSearch.MAP_SLOTS)
	for slot in GalaxyHeaderSearch.MAP_SLOTS:
		map_offsets[slot] = source.decode_u32(start + GalaxyHeaderSearch.TAG_SIZE + slot * 4)
	# The tile information follows MAPHEAD, in the program as in MAPHEAD.CK4.
	var info_start := start + GalaxyHeaderSearch.MAP_HEAD_SIZE
	tile_info = source.slice(info_start)
	var in_file := source != image
	found_at[GalaxyEpisode.Header.MAPHEAD] = FROM_FILE if in_file else start
	found_at[GalaxyEpisode.Header.TILEINFO] = FROM_FILE if in_file else info_start


func _find_dictionaries(
	image: PackedByteArray,
	files: GameFiles,
	episode: GalaxyEpisode,
	audio: PackedByteArray,
	graphics: PackedByteArray
) -> void:
	var audio_file := episode.file_name("AUDIODCT")
	var graphics_file := episode.file_name("EGADICT")
	if files.has_file(audio_file):
		audio_dictionary = GalaxyHuffman.from_bytes(files.read(audio_file))
		found_at[GalaxyEpisode.Header.AUDIODCT] = FROM_FILE if audio_dictionary else NOT_FOUND
	if files.has_file(graphics_file):
		graphics_dictionary = GalaxyHuffman.from_bytes(files.read(graphics_file))
		found_at[GalaxyEpisode.Header.EGADICT] = FROM_FILE if graphics_dictionary else NOT_FOUND
	if audio_dictionary != null and graphics_dictionary != null:
		return
	var known := _known(episode, GalaxyEpisode.Header.AUDIODCT)
	known.append_array(_known(episode, GalaxyEpisode.Header.EGADICT))
	_take_dictionaries(image, GalaxyHeaderSearch.known_dictionaries(image, known), audio, graphics)
	if audio_dictionary == null or graphics_dictionary == null:
		_take_dictionaries(image, GalaxyHeaderSearch.find_dictionaries(image), audio, graphics)


## Of the dictionaries at [param offsets], takes the one that expands the
## first graphics chunk and the one that expands the first audio chunk.
func _take_dictionaries(
	image: PackedByteArray,
	offsets: PackedInt32Array,
	audio: PackedByteArray,
	graphics: PackedByteArray
) -> void:
	for offset in offsets:
		var dictionary := GalaxyHuffman.from_bytes(image, offset)
		if (
			graphics_dictionary == null
			and _fits_first_chunk(dictionary, graphics, graphics_offsets)
		):
			graphics_dictionary = dictionary
			found_at[GalaxyEpisode.Header.EGADICT] = offset
		elif audio_dictionary == null and _fits_first_chunk(dictionary, audio, audio_offsets):
			audio_dictionary = dictionary
			found_at[GalaxyEpisode.Header.AUDIODCT] = offset


## Whether [param dictionary] expands the first chunks of [param file]:
## the test that tells the two dictionaries apart. One small chunk could
## fit a wrong dictionary by chance; several in a row do not.
static func _fits_first_chunk(
	dictionary: GalaxyHuffman, file: PackedByteArray, offsets: PackedInt32Array
) -> bool:
	var cleaned := GalaxyHeaderSearch.without_bogus(offsets)
	var checked := 0
	for index in cleaned.size() - 1:
		var end := GalaxyHeaderSearch.chunk_end(cleaned, index)
		if cleaned[index] < 0 or end <= cleaned[index]:
			continue
		if not GalaxyHeaderSearch.fits_chunk(dictionary, file, cleaned[index], end):
			return false
		checked += 1
		if checked == CHUNKS_TO_CHECK:
			break
	return checked > 0


static func _known(episode: GalaxyEpisode, piece: GalaxyEpisode.Header) -> PackedInt32Array:
	return episode.known_offsets.get(piece, PackedInt32Array()).duplicate()
