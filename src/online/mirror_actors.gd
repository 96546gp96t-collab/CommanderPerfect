class_name MirrorActors
extends RefCounted
## The joining player's copies of the host's actors, made from [Snapshot]s:
## the same [Actor] objects [ActorLayer] draws, but they only hold a sprite
## and a position and never step. Each keeps its id, so that its sprite
## moves smoothly from tick to tick.

var _actors: Dictionary[int, Actor] = {}


func clear() -> void:
	_actors.clear()


## The actors of [param snapshot], in the order to draw them.
func update(snapshot: Snapshot) -> Array[Actor]:
	var seen: Dictionary[int, Actor] = {}
	var result: Array[Actor] = []
	for figure in snapshot.doors:
		var door := _actors.get(figure.id) as OpeningDoor
		if door == null:
			door = OpeningDoor.create(Vector2i.ZERO, figure.tiles)
		door.position = figure.position
		door.visible_height = figure.height
		seen[figure.id] = door
		result.append(door)
	for figure in snapshot.actors:
		var copy := _actors.get(figure.id) as Copy
		if copy == null:
			copy = Copy.new()
		copy.position = figure.position
		copy.sprite = figure.sprite
		seen[figure.id] = copy
		result.append(copy)
	_actors = seen
	return result


## One actor as the host showed it.
class Copy:
	extends Actor
	var sprite := -1

	func sprite_index() -> int:
		return sprite
