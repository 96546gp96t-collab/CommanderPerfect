class_name SnapshotBuffer
extends RefCounted
## The joining player's queue of [Snapshot]s. They arrive at the pace of
## the network, a little uneven; the game shows one per tick. A small
## reserve evens that out; when the queue grows long (the network caught
## up after a hiccup), the oldest are skipped so that the picture does not
## stay behind.

## Snapshots kept in reserve before showing starts again after the queue
## ran dry.
const RESERVE := 2
## More than this waiting and the oldest go.
const MOST := 6

var _queue: Array[Snapshot] = []
var _waiting := true


func clear() -> void:
	_queue.clear()
	_waiting = true


func push(snapshot: Snapshot) -> void:
	_queue.append(snapshot)
	while _queue.size() > MOST:
		_queue.pop_front()


## The snapshot for the next tick, or null to keep showing the last one.
func take() -> Snapshot:
	if _waiting:
		if _queue.size() < RESERVE:
			return null
		_waiting = false
	if _queue.is_empty():
		_waiting = true
		return null
	return _queue.pop_front()


func size() -> int:
	return _queue.size()
