class_name GalaxyMapFile
extends RefCounted
## GAMEMAPS: the maps of a Galaxy episode. MAPHEAD gives the RLEW tag and
## where each map's header lies; a header gives the offsets and lengths of
## the three planes, the size and the name, and ends with "!ID!". Each
## plane is Carmack-compressed, then RLEW-compressed. See
## docs/keen4/file-formats.md, "GAMEMAPS.CK4 and MAPHEAD".

const PLANE_LENGTHS_START := 12
const SIZE_START := 18
const NAME_START := 22
const NAME_SIZE := 16

var data := PackedByteArray()
var tag := 0
## The header offset of every map slot; 0 = no map.
var offsets := PackedInt32Array()


static func create(
	file_data: PackedByteArray, rlew_tag: int, map_offsets: PackedInt32Array
) -> GalaxyMapFile:
	var file := GalaxyMapFile.new()
	file.data = file_data
	file.tag = rlew_tag
	file.offsets = map_offsets
	return file


## The maps of the episode, with MAPHEAD from [param headers]; null when
## GAMEMAPS is missing.
static func load_from(
	files: GameFiles, episode: GalaxyEpisode, headers: GalaxyHeaders
) -> GalaxyMapFile:
	var file_data := files.read(episode.file_name("GAMEMAPS"))
	if file_data.is_empty():
		return null
	return create(file_data, headers.map_tag, headers.map_offsets)


## One more than the highest slot that holds a map.
func map_count() -> int:
	for slot in range(offsets.size() - 1, -1, -1):
		if has_map(slot):
			return slot + 1
	return 0


func has_map(number: int) -> bool:
	return (
		number >= 0
		and number < offsets.size()
		and offsets[number] > 0
		and offsets[number] + GalaxyHeaderSearch.MAP_SIGNATURE_OFFSET <= data.size()
	)


## The name of map [param number] in the file; "" when there is none.
func map_name(number: int) -> String:
	if not has_map(number):
		return ""
	var start := offsets[number] + NAME_START
	return data.slice(start, start + NAME_SIZE).get_string_from_ascii()


## The size of map [param number] in tiles.
func map_size(number: int) -> Vector2i:
	if not has_map(number):
		return Vector2i.ZERO
	var header := offsets[number]
	return Vector2i(data.decode_u16(header + SIZE_START), data.decode_u16(header + SIZE_START + 2))


## Map [param number] with its three planes; null when there is none or a
## plane does not expand to the map's size.
func load_map(number: int) -> GalaxyMap:
	if not has_map(number):
		push_error("There is no map %d." % number)
		return null
	var header := offsets[number]
	var map := GalaxyMap.new()
	map.number = number
	map.name = map_name(number)
	var size := map_size(number)
	map.width = size.x
	map.height = size.y
	for plane in GalaxyMap.PLANE_COUNT:
		var start := data.decode_u32(header + plane * 4)
		var words := GalaxyRlew.expand(GalaxyCarmack.expand(data, start), tag)
		if words.size() != size.x * size.y:
			push_error("Plane %d of map %d does not fit its size." % [plane, number])
			return null
		map.planes.append(words)
	return map
