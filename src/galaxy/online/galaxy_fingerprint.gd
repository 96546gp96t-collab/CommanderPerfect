class_name GalaxyFingerprint
extends RefCounted
## The fingerprint of a Galaxy episode's maps, as [LevelFingerprint] is for
## Keen 1-3's level files (milestone D12): a Galaxy episode has one GAMEMAPS
## file, read with the map headers (MAPHEAD: the RLEW tag and where each map
## starts). The host refuses a player whose maps differ (another version,
## or changed maps); the files themselves never travel.

const LENGTH := LevelFingerprint.LENGTH


## The fingerprint of [param maps]; empty without them.
static func of(maps: GalaxyMapFile) -> String:
	if maps == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(("galaxy:%d:%d;" % [maps.tag, maps.offsets.size()]).to_utf8_buffer())
	context.update(maps.offsets.to_byte_array())
	context.update(maps.data)
	return context.finish().hex_encode().left(LENGTH)
