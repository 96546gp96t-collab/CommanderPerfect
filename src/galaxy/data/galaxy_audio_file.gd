class_name GalaxyAudioFile
extends RefCounted
## AUDIO: the sounds and songs of a Galaxy episode as chunks of bytes
## (AUDIOHED gives where each starts, AUDIODCT expands them). Nothing is
## played yet; D9 turns the bytes into sound. In Keen 4 the PC speaker
## sounds come first, then the AdLib sounds, the (absent) digitised sounds
## and the songs. See docs/keen4/file-formats.md, "AUDIO.CK4".

const LENGTH_SIZE := 4

var data := PackedByteArray()
## Chunk offsets with the empty and bogus ones as -1, then the file size.
var offsets := PackedInt32Array()
var dictionary: GalaxyHuffman


static func create(
	file_data: PackedByteArray, chunk_offsets: PackedInt32Array, huffman: GalaxyHuffman
) -> GalaxyAudioFile:
	var file := GalaxyAudioFile.new()
	file.data = file_data
	file.offsets = GalaxyHeaderSearch.without_bogus(chunk_offsets)
	file.dictionary = huffman
	return file


## The sounds of the episode, with AUDIOHED and AUDIODCT from
## [param headers]; null when AUDIO is missing.
static func load_from(
	files: GameFiles, episode: GalaxyEpisode, headers: GalaxyHeaders
) -> GalaxyAudioFile:
	var file_data := files.read(episode.file_name("AUDIO"))
	if file_data.is_empty():
		return null
	return create(file_data, headers.audio_offsets, headers.audio_dictionary)


func chunk_count() -> int:
	return maxi(0, offsets.size() - 1)


## Whether chunk [param index] holds nothing (such as the digitised sounds).
func is_empty(index: int) -> bool:
	if index < 0 or index >= chunk_count() or offsets[index] < 0:
		return true
	return GalaxyHeaderSearch.chunk_end(offsets, index) - offsets[index] < LENGTH_SIZE


## The expanded bytes of chunk [param index]; empty for an empty chunk.
func chunk(index: int) -> PackedByteArray:
	if is_empty(index):
		return PackedByteArray()
	var start := offsets[index]
	return dictionary.expand(data, start + LENGTH_SIZE, data.decode_u32(start))
