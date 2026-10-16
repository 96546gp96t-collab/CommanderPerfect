class_name Snapshot
extends RefCounted
## What the player who joins sees of one tick: the Keens, the other actors,
## the doors that sink into the floor, the shared [Inventory] and the sounds
## of that tick. The host makes one every tick ([SnapshotMaker]) and sends it
## unreliably: a lost one is replaced by the next.
##
## On the wire it is a short array of packed numbers (see [method to_message]);
## [method from_message] checks every part, because it comes from the
## network.

## Numbers per Keen: x, y, sprite, visible width, dead.
const KEEN_FIELDS := 5
## Numbers per actor: id, x, y, sprite.
const ACTOR_FIELDS := 4
## Numbers per door before its tiles: id, x, y, visible height, tile count.
const DOOR_HEADER := 5
## Numbers in the inventory: score, lives, charges, flags.
const INVENTORY_FIELDS := 4
## More than this is not a level of Keen 1 but somebody's attack.
const MAX_FIGURES := 512
const MAX_DOOR_TILES := 16
const MAX_SPRITE := 4096


## Something drawn with a sprite: a Keen or another actor. For a door,
## [member tiles] and [member height] are set instead of the sprite.
class Figure:
	extends RefCounted
	var id := 0
	var position := Vector2.ZERO
	var sprite := -1
	## How much of Keen is visible from the left (he walks out through a door).
	var width := KeenPhysics.SPRITE_SIZE.x
	var dead := false
	var tiles := PackedInt32Array()
	var height := 0


## Which [OnlineScene] this tick belongs to; a snapshot of another scene is
## ignored.
var scene := 0
var inventory := Inventory.new()
var sounds := PackedByteArray()
## Player 1's Keen (the host's) first, then player 2's. On the world map the
## one Keen walking there.
var keens: Array[Figure] = []
var actors: Array[Figure] = []
var doors: Array[Figure] = []


func to_message() -> Array:
	var keen_numbers := PackedFloat32Array()
	for keen in keens:
		keen_numbers.append_array(
			[keen.position.x, keen.position.y, keen.sprite, keen.width, 1.0 if keen.dead else 0.0]
		)
	var actor_numbers := PackedFloat32Array()
	for actor in actors:
		actor_numbers.append_array([actor.id, actor.position.x, actor.position.y, actor.sprite])
	var door_numbers := PackedInt32Array()
	for door in doors:
		door_numbers.append_array(
			[door.id, int(door.position.x), int(door.position.y), door.height, door.tiles.size()]
		)
		door_numbers.append_array(door.tiles)
	return [
		OnlineProtocol.Message.SNAPSHOT,
		scene,
		_inventory_numbers(),
		sounds,
		keen_numbers,
		actor_numbers,
		door_numbers,
	]


## The snapshot in [param message], or null when it is not a sane one.
static func from_message(message: Array) -> Snapshot:
	if message.size() != 7 or not message[1] is int:
		return null
	var parts := [message[2], message[3], message[4], message[5], message[6]]
	var types: Array[int] = [
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
	]
	for index in parts.size():
		if typeof(parts[index]) != types[index]:
			return null
	var snapshot := Snapshot.new()
	snapshot.scene = message[1]
	snapshot.sounds = message[3]
	if (
		not snapshot._read_inventory(message[2])
		or not snapshot._read_keens(message[4])
		or not snapshot._read_actors(message[5])
		or not snapshot._read_doors(message[6])
	):
		return null
	return snapshot


func _inventory_numbers() -> PackedInt32Array:
	var flags := 1 if inventory.has_pogo else 0
	for color in inventory.keycards.size():
		flags |= (1 << (1 + color)) if inventory.keycards[color] else 0
	for part in inventory.ship_parts.size():
		flags |= (1 << (5 + part)) if inventory.ship_parts[part] else 0
	return PackedInt32Array([inventory.score, inventory.lives, inventory.charges, flags])


func _read_inventory(numbers: PackedInt32Array) -> bool:
	if numbers.size() != INVENTORY_FIELDS:
		return false
	inventory.score = numbers[0]
	inventory.lives = numbers[1]
	inventory.charges = numbers[2]
	var flags := numbers[3]
	inventory.has_pogo = flags & 1 != 0
	for color in inventory.keycards.size():
		inventory.keycards[color] = flags & (1 << (1 + color)) != 0
	for part in inventory.ship_parts.size():
		inventory.ship_parts[part] = flags & (1 << (5 + part)) != 0
	return true


func _read_keens(numbers: PackedFloat32Array) -> bool:
	if numbers.size() % KEEN_FIELDS != 0 or numbers.size() > KEEN_FIELDS * MAX_FIGURES:
		return false
	for start in range(0, numbers.size(), KEEN_FIELDS):
		var keen := Figure.new()
		keen.position = Vector2(numbers[start], numbers[start + 1])
		keen.sprite = _sprite(numbers[start + 2])
		keen.width = clampf(numbers[start + 3], 0.0, KeenPhysics.SPRITE_SIZE.x)
		keen.dead = numbers[start + 4] != 0.0
		if not keen.position.is_finite():
			return false
		keens.append(keen)
	return true


func _read_actors(numbers: PackedFloat32Array) -> bool:
	if numbers.size() % ACTOR_FIELDS != 0 or numbers.size() > ACTOR_FIELDS * MAX_FIGURES:
		return false
	for start in range(0, numbers.size(), ACTOR_FIELDS):
		var actor := Figure.new()
		actor.id = int(numbers[start])
		actor.position = Vector2(numbers[start + 1], numbers[start + 2])
		actor.sprite = _sprite(numbers[start + 3])
		if not actor.position.is_finite():
			return false
		actors.append(actor)
	return true


func _read_doors(numbers: PackedInt32Array) -> bool:
	var start := 0
	while start < numbers.size():
		if start + DOOR_HEADER > numbers.size() or doors.size() >= MAX_FIGURES:
			return false
		var count := numbers[start + 4]
		if count < 0 or count > MAX_DOOR_TILES or start + DOOR_HEADER + count > numbers.size():
			return false
		var door := Figure.new()
		door.id = numbers[start]
		door.position = Vector2(numbers[start + 1], numbers[start + 2])
		door.height = clampi(numbers[start + 3], 0, count * EgaGraphics.TILE_SIZE)
		door.tiles = numbers.slice(start + DOOR_HEADER, start + DOOR_HEADER + count)
		doors.append(door)
		start += DOOR_HEADER + count
	return true


## A sprite number from the network: -1 (nothing) or one that may exist.
static func _sprite(value: float) -> int:
	var index := int(value)
	return index if index >= 0 and index < MAX_SPRITE else -1
