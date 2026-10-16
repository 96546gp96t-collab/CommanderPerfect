class_name SnapshotMaker
extends RefCounted
## The host's side of [Snapshot]: takes the picture of one tick of a level
## or of the world map. Every actor keeps the same id for as long as it
## lives, so that the player who joins can move its sprite smoothly.

var _ids: Dictionary[Actor, int] = {}
var _next_id := 1


## Starts again: a new level has new actors.
func reset() -> void:
	_ids.clear()
	_next_id = 1


## The tick of [param session] as it is now.
func of_level(
	session: LevelSession, scene: int, inventory: Inventory, sounds: PackedByteArray
) -> Snapshot:
	var snapshot := _start(scene, inventory, sounds)
	for body in session.keens:
		var keen := Snapshot.Figure.new()
		keen.position = body.position
		keen.sprite = body.sprite_index()
		keen.width = body.visible_width()
		keen.dead = body.is_dead
		snapshot.keens.append(keen)
	var alive: Dictionary[Actor, int] = {}
	for actor in session.actors:
		if actor.removed:
			continue
		var figure := Snapshot.Figure.new()
		figure.id = _id_of(actor)
		alive[actor] = figure.id
		figure.position = actor.position
		var door := actor as OpeningDoor
		if door != null:
			figure.tiles = door.tiles
			figure.height = door.visible_height
			snapshot.doors.append(figure)
		else:
			figure.sprite = actor.sprite_index()
			snapshot.actors.append(figure)
	_ids = alive
	return snapshot


## The tick of the world map: Keen walking there.
func of_map(
	map_keen: MapKeen, scene: int, inventory: Inventory, sounds: PackedByteArray
) -> Snapshot:
	var snapshot := _start(scene, inventory, sounds)
	var keen := Snapshot.Figure.new()
	keen.position = map_keen.position
	keen.sprite = -1 if map_keen.hidden else map_keen.sprite_index()
	snapshot.keens.append(keen)
	return snapshot


## Only the inventory and the sounds, for scenes without a picture of their
## own to send.
func of_nothing(scene: int, inventory: Inventory, sounds: PackedByteArray) -> Snapshot:
	return _start(scene, inventory, sounds)


func _start(scene: int, inventory: Inventory, sounds: PackedByteArray) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.scene = scene
	snapshot.inventory = inventory
	snapshot.sounds = sounds
	return snapshot


func _id_of(actor: Actor) -> int:
	if not _ids.has(actor):
		_ids[actor] = _next_id
		_next_id += 1
	return _ids[actor]
