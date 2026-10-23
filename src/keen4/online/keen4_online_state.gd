class_name Keen4OnlineState
extends RefCounted
## Keen 4's own numbers in every online snapshot ([member
## GalaxySnapshot.extra], milestone D12): the shared inventory (score,
## lives, charges, drops, gems, the next extra life) and the progress
## (the rescued council members, the wetsuit, the levels done, the
## difficulty), so the joiner's score box and status window show them.

enum Field {
	SCORE,
	LIVES,
	SHOTS,
	DROPS,
	GEMS,
	NEXT_LIFE,
	RESCUED,
	WETSUIT,
	DONE_LEVELS,
	DIFFICULTY,
}

## Each gem colour's count takes a byte of [constant Field.GEMS].
const GEM_BITS := 8
const GEM_MASK := 0xFF
const MAX_SCORE := 999999999
const MAX_COUNT := 999


## The numbers of [param inventory], [param progress] and
## [param difficulty].
static func pack(
	inventory: GalaxyInventory, progress: Keen4Progress, difficulty: int
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
	numbers[Field.RESCUED] = progress.rescued
	numbers[Field.WETSUIT] = 1 if progress.wetsuit else 0
	var done := 0
	for level in progress.done_levels():
		if level >= 0 and level < Keen4Episode.LAST_MAP:
			done |= 1 << level
	numbers[Field.DONE_LEVELS] = done
	numbers[Field.DIFFICULTY] = difficulty
	return numbers


## Whether [param numbers] are a sane set of [method pack].
static func is_sane(numbers: PackedInt32Array) -> bool:
	if numbers.size() != Field.size():
		return false
	var score := numbers[Field.SCORE]
	if score < 0 or score > MAX_SCORE or numbers[Field.NEXT_LIFE] < 0:
		return false
	for field in [Field.LIVES, Field.SHOTS, Field.DROPS]:
		if numbers[field] < -1 or numbers[field] > MAX_COUNT:
			return false
	var rescued := numbers[Field.RESCUED]
	if rescued < 0 or rescued > Keen4Progress.COUNCIL_COUNT or numbers[Field.GEMS] < 0:
		return false
	return (
		numbers[Field.DIFFICULTY] >= 0 and numbers[Field.DIFFICULTY] < GalaxyDifficulty.Level.size()
	)


## Puts [param numbers] into [param inventory] and [param progress].
static func unpack(
	numbers: PackedInt32Array, inventory: GalaxyInventory, progress: Keen4Progress
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
	progress.rescued = numbers[Field.RESCUED]
	progress.wetsuit = numbers[Field.WETSUIT] != 0
	for level in Keen4Episode.LAST_MAP:
		if numbers[Field.DONE_LEVELS] & (1 << level):
			progress.mark_done(level)


## Keen 4's numbers as the shared game asks for them ([GalaxyOnlineState],
## milestone E13): Keen 4's own layout, so its snapshots stay as they were.
class GameState:
	extends GalaxyOnlineState

	func pack(
		inventory: GalaxyInventory, progress: GalaxyProgress, difficulty: int
	) -> PackedInt32Array:
		return Keen4OnlineState.pack(inventory, progress as Keen4Progress, difficulty)

	func is_sane(numbers: PackedInt32Array) -> bool:
		return Keen4OnlineState.is_sane(numbers)

	func unpack(
		numbers: PackedInt32Array, inventory: GalaxyInventory, progress: GalaxyProgress
	) -> void:
		Keen4OnlineState.unpack(numbers, inventory, progress as Keen4Progress)
