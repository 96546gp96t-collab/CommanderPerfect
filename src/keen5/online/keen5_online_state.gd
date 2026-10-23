class_name Keen5OnlineState
extends GalaxyOnlineState
## Keen 5's numbers in every online snapshot (milestone E11): the shared
## Galaxy ones ([GalaxyOnlineState]) and what only Keen 5 keeps (Omni
## ck_gameState.ep.ck5): the keycard and the fuses still to break
## ([Keen5Inventory]), which levels were done by their fuse (14, not 1)
## and the arrival on Korath III ([Keen5Progress]), so the joiner's end
## pages are the secret ones when the host broke Korath III's fuse.

enum Extra { KEYCARD, FUSES_REMAINING, FUSE_LEVELS, KORATH_ARRIVAL }

## More fuses than this in a level is not Keen 5 (the most is 4).
const MAX_FUSES := 64


func _extra_size() -> int:
	return Extra.size()


func _pack_extra(inventory: GalaxyInventory, progress: GalaxyProgress) -> PackedInt32Array:
	var numbers := PackedInt32Array()
	numbers.resize(Extra.size())
	var carried := inventory as Keen5Inventory
	if carried != null:
		numbers[Extra.KEYCARD] = 1 if carried.keycard else 0
		numbers[Extra.FUSES_REMAINING] = carried.fuses_remaining
	numbers[Extra.FUSE_LEVELS] = GalaxyOnlineState.level_bits(
		progress, func(value: int) -> bool: return value == Keen5Progress.DONE_BY_FUSE
	)
	var keen_5 := progress as Keen5Progress
	numbers[Extra.KORATH_ARRIVAL] = 1 if keen_5 != null and keen_5.korath_arrival else 0
	return numbers


func _is_extra_sane(extra: PackedInt32Array) -> bool:
	for flag in [Extra.KEYCARD, Extra.KORATH_ARRIVAL]:
		if extra[flag] < 0 or extra[flag] > 1:
			return false
	var fuses := extra[Extra.FUSES_REMAINING]
	return fuses >= 0 and fuses <= MAX_FUSES and extra[Extra.FUSE_LEVELS] >= 0


func _unpack_extra(
	extra: PackedInt32Array, inventory: GalaxyInventory, progress: GalaxyProgress
) -> void:
	var carried := inventory as Keen5Inventory
	if carried != null:
		carried.keycard = extra[Extra.KEYCARD] != 0
		carried.fuses_remaining = extra[Extra.FUSES_REMAINING]
	for level in LEVEL_BITS:
		if extra[Extra.FUSE_LEVELS] & (1 << level) != 0:
			progress.mark_done(level, Keen5Progress.DONE_BY_FUSE)
	var keen_5 := progress as Keen5Progress
	if keen_5 != null:
		keen_5.korath_arrival = extra[Extra.KORATH_ARRIVAL] != 0
