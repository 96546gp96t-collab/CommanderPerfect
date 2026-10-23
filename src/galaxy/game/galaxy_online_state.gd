class_name GalaxyOnlineState
extends RefCounted
## A Galaxy episode's own numbers in every online snapshot ([member
## GalaxySnapshot.extra]; made from Keen 4's [Keen4OnlineState], milestone
## E11): the shared inventory (score, lives, charges, drops, gems, the next
## extra life), the levels done and the difficulty, so the joiner's score
## box (and his end pages) show them. An episode keeps more through its
## subclass ([method _extra_size], [method _pack_extra],
## [method _is_extra_sane], [method _unpack_extra]; Keen 5's keycard,
## fuses and Korath III: [Keen5OnlineState]); those numbers follow the
## shared ones.

enum Field {
	SCORE,
	LIVES,
	SHOTS,
	DROPS,
	GEMS,
	NEXT_LIFE,
	DONE_LEVELS,
	DIFFICULTY,
}

## Each gem colour's count takes a byte of [constant Field.GEMS].
const GEM_BITS := 8
const GEM_MASK := 0xFF
const MAX_SCORE := 999999999
const MAX_COUNT := 999
## The levels done are bits of one number: maps 0-30.
const LEVEL_BITS := 31


## The numbers of [param inventory], [param progress] and
## [param difficulty].
func pack(
	inventory: GalaxyInventory, progress: GalaxyProgress, difficulty: int
) -> PackedInt32Array:
	var numbers := PackedInt32Array()
	numbers.resize(Field.size())
	numbers[Field.SCORE] = inventory.score
	numbers[Field.LIVES] = inventory.lives
	numbers[Field.SHOTS] = inventory.shots
	numbers[Field.DROPS] = inventory.drops
	var gems := 0
	for colour in GalaxyInventory.GEM_COUNT:
		gems |= (clampi(inventory.gems[colour], 0, GEM_MASK >> 1)) << (colour * GEM_BITS)
	numbers[Field.GEMS] = gems
	numbers[Field.NEXT_LIFE] = inventory.next_life_at
	numbers[Field.DONE_LEVELS] = level_bits(progress, func(_value: int) -> bool: return true)
	numbers[Field.DIFFICULTY] = difficulty
	numbers.append_array(_pack_extra(inventory, progress))
	return numbers


## Whether [param numbers] are a sane set of [method pack].
func is_sane(numbers: PackedInt32Array) -> bool:
	if numbers.size() != Field.size() + _extra_size():
		return false
	var score := numbers[Field.SCORE]
	if score < 0 or score > MAX_SCORE or numbers[Field.NEXT_LIFE] < 0:
		return false
	for field in [Field.LIVES, Field.SHOTS, Field.DROPS]:
		if numbers[field] < -1 or numbers[field] > MAX_COUNT:
			return false
	if numbers[Field.GEMS] < 0 or numbers[Field.DONE_LEVELS] < 0:
		return false
	var difficulty := numbers[Field.DIFFICULTY]
	if difficulty < 0 or difficulty >= GalaxyDifficulty.Level.size():
		return false
	return _is_extra_sane(numbers.slice(Field.size()))


## Puts [param numbers] into [param inventory] and [param progress]: the
## levels done are exactly the host's.
func unpack(
	numbers: PackedInt32Array, inventory: GalaxyInventory, progress: GalaxyProgress
) -> void:
	if not is_sane(numbers):
		return
	inventory.score = numbers[Field.SCORE]
	inventory.lives = numbers[Field.LIVES]
	inventory.shots = numbers[Field.SHOTS]
	inventory.drops = numbers[Field.DROPS]
	for colour in GalaxyInventory.GEM_COUNT:
		inventory.gems[colour] = (numbers[Field.GEMS] >> (colour * GEM_BITS)) & GEM_MASK
	inventory.next_life_at = numbers[Field.NEXT_LIFE]
	for level in LEVEL_BITS:
		var done := numbers[Field.DONE_LEVELS] & (1 << level) != 0
		progress.mark_done(level, GalaxyProgress.DONE if done else 0)
	_unpack_extra(numbers.slice(Field.size()), inventory, progress)


## The levels of [param progress] whose done value [param chosen] takes,
## as bits.
static func level_bits(progress: GalaxyProgress, chosen: Callable) -> int:
	var bits := 0
	for level in progress.done_levels():
		if level >= 0 and level < LEVEL_BITS and chosen.call(progress.done_value(level)):
			bits |= 1 << level
	return bits


## How many numbers the episode adds (none by default).
func _extra_size() -> int:
	return 0


## The episode's own numbers of [param _inventory] and [param _progress].
func _pack_extra(_inventory: GalaxyInventory, _progress: GalaxyProgress) -> PackedInt32Array:
	return PackedInt32Array()


## Whether the episode's numbers [param _extra] are sane.
func _is_extra_sane(_extra: PackedInt32Array) -> bool:
	return true


## Puts the episode's numbers [param _extra] (sane) into
## [param _inventory] and [param _progress].
func _unpack_extra(
	_extra: PackedInt32Array, _inventory: GalaxyInventory, _progress: GalaxyProgress
) -> void:
	pass
