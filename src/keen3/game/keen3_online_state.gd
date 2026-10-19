class_name Keen3OnlineState
extends RefCounted
## Keen 3's own part of an online snapshot (milestone C10): the numbers in
## [member Snapshot.extra] that the player who joined needs besides what
## every game sends (the Keens, the actors, the shared inventory with the
## raygun's charges and the keycards). The host fills one every tick
## ([method of_level], [method of_map]); the joiner reads it back with
## [method from_numbers], which checks every number, because it comes from
## the network.
##   0        the done levels, bit n - 1 for level n
##   1, 2     the ankh time left of player 1's Keen (the host's) and of
##            player 2's, in ticks (the halo itself is an actor)
##   3        Keen 3's own sounds of the tick ([constant Keen3Sounds.NAMES]),
##            one bit each: the shared sounds only carry Keen 1's names
##   4, 5     the middle of the host's view of the world map (Keen 3's map
##            has a view of its own, [Keen3MapScroll]), in 1/16 pixels
##   6, 7, 8  Messie on the map: her place in 1/16 pixels and her picture
##            (-1: no Messie, as in a level)

## How many numbers Keen 3 sends.
const FIELDS := 9
const DONE_INDEX := 0
const ANKH_INDEX := 1
const SOUNDS_INDEX := 3
const VIEW_INDEX := 4
const MESSIE_INDEX := 6
## Places on the map go in this many parts of a pixel, so that the view and
## Messie glide as smoothly at the joiner as at the host.
const PLACE_SCALE := 16.0
## Keen 3 has levels 1-16; anything above is no done level.
const DONE_MASK := 0xFFFF
## More ankh time than this is nobody's: a few hundred ankhs.
const MAX_ANKH_TICKS := Keen3Body.ANKH_TICKS * 256
## No map of ours is this many pixels across.
const MAX_PLACE := OnlineMessages.MAX_CELL * EgaGraphics.TILE_SIZE
## Sent for a view that does not exist (in a level).
const NO_VIEW := -1
const KEENS := 2

## The levels done so far, bit n - 1 for level n.
var done_levels := 0
## The ankh time left of each Keen, in ticks: player 1's first.
var ankh_ticks: PackedInt32Array = [0, 0]
## Keen 3's own sounds of the tick, by name ([constant Keen3Sounds.NAMES]).
var sounds := PackedStringArray()
## The middle of the host's view of the map; INF in a level.
var view_center := Vector2.INF
## Messie's top left and picture; -1 without her.
var messie_position := Vector2.ZERO
var messie_sprite := -1


## The state of a tick in [param session]: the ankh time of each Keen,
## the done levels of [param progress] and [param sound_names].
static func of_level(
	session: LevelSession, progress: GameProgress, sound_names: PackedStringArray
) -> Keen3OnlineState:
	var state := _started(progress, sound_names)
	for index in mini(session.keens.size(), KEENS):
		var body := session.keens[index] as Keen3Body
		if body != null:
			state.ankh_ticks[index] = body.ankh_ticks
	return state


## The state of a tick on the map of [param map_session]: its view and
## Messie, the done levels of [param progress] and [param sound_names].
static func of_map(
	map_session: Keen3MapSession, progress: GameProgress, sound_names: PackedStringArray
) -> Keen3OnlineState:
	var state := _started(progress, sound_names)
	if map_session.scroll != null:
		state.view_center = map_session.scroll.center()
	if map_session.messie != null:
		state.messie_position = map_session.messie.position
		state.messie_sprite = map_session.messie.sprite_index()
	return state


## The done levels of [param progress] as bits, level 1 lowest.
static func done_bits(progress: GameProgress) -> int:
	var bits := 0
	for number in progress.completed_levels():
		if number >= Keen3Files.FIRST_LEVEL and number <= Keen3Files.LAST_LEVEL:
			bits |= 1 << (number - Keen3Files.FIRST_LEVEL)
	return bits


## The state in [param numbers], or null when they are not Keen 3's.
static func from_numbers(numbers: PackedInt32Array) -> Keen3OnlineState:
	if numbers.size() != FIELDS:
		return null
	var state := Keen3OnlineState.new()
	state.done_levels = numbers[DONE_INDEX] & DONE_MASK
	for index in KEENS:
		state.ankh_ticks[index] = clampi(numbers[ANKH_INDEX + index], 0, MAX_ANKH_TICKS)
	for bit in Keen3Sounds.NAMES.size():
		if numbers[SOUNDS_INDEX] & (1 << bit) != 0:
			state.sounds.append(Keen3Sounds.NAMES[bit])
	if numbers[VIEW_INDEX] >= 0:
		state.view_center = _place(numbers[VIEW_INDEX], numbers[VIEW_INDEX + 1])
	state.messie_position = _place(numbers[MESSIE_INDEX], numbers[MESSIE_INDEX + 1])
	var sprite := numbers[MESSIE_INDEX + 2]
	state.messie_sprite = sprite if sprite >= 0 and sprite < Snapshot.MAX_SPRITE else -1
	return state


## The numbers to send.
func to_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array()
	numbers.resize(FIELDS)
	numbers[DONE_INDEX] = done_levels & DONE_MASK
	for index in KEENS:
		numbers[ANKH_INDEX + index] = ankh_ticks[index]
	var sound_bits := 0
	for sound_name in sounds:
		var bit := Keen3Sounds.NAMES.find(sound_name)
		if bit >= 0:
			sound_bits |= 1 << bit
	numbers[SOUNDS_INDEX] = sound_bits
	numbers[VIEW_INDEX] = NO_VIEW
	numbers[VIEW_INDEX + 1] = NO_VIEW
	if view_center.is_finite():
		numbers[VIEW_INDEX] = roundi(view_center.x * PLACE_SCALE)
		numbers[VIEW_INDEX + 1] = roundi(view_center.y * PLACE_SCALE)
	numbers[MESSIE_INDEX] = roundi(messie_position.x * PLACE_SCALE)
	numbers[MESSIE_INDEX + 1] = roundi(messie_position.y * PLACE_SCALE)
	numbers[MESSIE_INDEX + 2] = messie_sprite
	return numbers


## The levels done, as numbers.
func completed_levels() -> Array[int]:
	var levels: Array[int] = []
	for number in range(Keen3Files.FIRST_LEVEL, Keen3Files.LAST_LEVEL + 1):
		if done_levels & (1 << (number - Keen3Files.FIRST_LEVEL)) != 0:
			levels.append(number)
	return levels


## The ankh time of player [param player]'s Keen in the status screen's
## "seconds", as [method Keen3Body.ankh_seconds] counts them.
func ankh_seconds(player: int) -> int:
	return floori(ankh_ticks[player] / Keen3Body.TICKS_PER_ANKH_SECOND)


static func _started(progress: GameProgress, sound_names: PackedStringArray) -> Keen3OnlineState:
	var state := Keen3OnlineState.new()
	state.done_levels = done_bits(progress)
	state.sounds = sound_names
	return state


## A place from the network (in 1/16 pixels), in pixels and on a map.
static func _place(x: int, y: int) -> Vector2:
	var most := roundi(MAX_PLACE * PLACE_SCALE)
	return Vector2(clampi(x, 0, most), clampi(y, 0, most)) / PLACE_SCALE
