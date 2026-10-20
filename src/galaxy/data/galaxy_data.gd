class_name GalaxyData
extends RefCounted
## All the data of a Galaxy episode in the player's files: the program
## with its texts, the headers it holds, the graphics, the maps with their
## tile information, and the sounds. Loading finds the headers and works
## out the chunk ranges; pictures, tiles and maps are decoded only when
## asked for ([GalaxyGraphics], [GalaxyMapFile]).

var episode: GalaxyEpisode
var executable: GalaxyExecutable
var headers: GalaxyHeaders
var graphics: GalaxyGraphics
var maps: GalaxyMapFile
var tile_info: GalaxyTileInfo
var audio: GalaxyAudioFile


## The episode in [param files]; null (with the reason) when a file is
## missing or a header is not found.
static func load_from(files: GameFiles, episode: GalaxyEpisode) -> GalaxyData:
	var executable := GalaxyExecutable.load_from(files, episode)
	if executable == null:
		return null
	var headers := GalaxyHeaders.find(executable.image, files, episode)
	if headers == null:
		return null
	var data := GalaxyData.new()
	data.episode = episode
	data.executable = executable
	data.headers = headers
	data.graphics = GalaxyGraphics.load_from(files, episode, headers)
	data.maps = GalaxyMapFile.load_from(files, episode, headers)
	data.audio = GalaxyAudioFile.load_from(files, episode, headers)
	if data.graphics == null or data.maps == null or data.audio == null:
		return null
	data.tile_info = GalaxyTileInfo.parse(
		headers.tile_info,
		data.graphics.ranges.back_tile_count,
		data.graphics.ranges.fore_tile_count
	)
	if data.tile_info == null:
		return null
	return data
