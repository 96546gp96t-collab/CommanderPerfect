class_name LevelFingerprint
extends RefCounted
## A short hash of every level file the player has. The host runs the game
## and the player who joins draws it with his own level files, so both must
## have the same ones: a host refuses a player whose fingerprint differs
## (another version of Keen 1, or changed levels). The files themselves
## never travel.

## Hex characters kept of the SHA-256: plenty to tell versions apart.
const LENGTH := 16


## The fingerprint of the levels in [param files]; empty without files.
static func of(files: GameFiles) -> String:
	if files == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for number in files.level_numbers():
		var data := files.read(files.level_file(number))
		context.update(("%d:%d;" % [number, data.size()]).to_utf8_buffer())
		context.update(data)
	return context.finish().hex_encode().left(LENGTH)
