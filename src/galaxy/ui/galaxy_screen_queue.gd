class_name GalaxyScreenQueue
extends RefCounted
## What a Galaxy game shows between its frames, one step after the other
## (message boxes, the box while a map "loads", fades): each step has a
## picture over the game (or none), how bright the whole picture is, and
## either a time in tics or "until a key is pressed". A step may run
## something when it starts (the next map is put on the screen behind a
## fade). The game stands still while the queue is not empty; when its last
## step ends, [member then] runs. The view draws [method current].


## One step.
class Step:
	extends RefCounted
	## The picture over the game (320 × 200, see-through around it); null for
	## none.
	var image: Image
	## Tics it lasts; 0 waits for a key.
	var tics := 0
	## 1 for the normal picture, 0 for black.
	var brightness := 1.0
	## Runs when the step starts.
	var start: Callable


var steps: Array[Step] = []
## Runs after the last step.
var then: Callable
## Tics the current step has run.
var _elapsed := 0
var _started := false


## A step showing [param image] until a key is pressed.
func add_box(image: Image) -> Step:
	return add(image, 0)


## A step showing [param image] for [param tics] tics at [param brightness];
## [param start] runs when it begins.
func add(image: Image, tics: int, brightness := 1.0, start := Callable()) -> Step:
	var step := Step.new()
	step.image = image
	step.tics = tics
	step.brightness = brightness
	step.start = start
	steps.append(step)
	return step


func is_empty() -> bool:
	return steps.is_empty()


## The step shown now (its start has run), or null.
func current() -> Step:
	if steps.is_empty():
		return null
	if not _started:
		_started = true
		if steps[0].start.is_valid():
			steps[0].start.call()
	return steps[0]


## Lets [param tics] tics pass; returns whether the step changed.
func advance(tics: int) -> bool:
	var changed := false
	var left := tics
	while left > 0 and not steps.is_empty():
		var step := current()
		if step.tics == 0:
			break
		var used := mini(left, step.tics - _elapsed)
		_elapsed += used
		left -= used
		if _elapsed >= step.tics:
			_next()
			changed = true
	return changed


## A key was pressed: a step that waits for one ends.
func press() -> bool:
	var step := current()
	if step == null or step.tics != 0:
		return false
	_next()
	return true


## Drops every step (and what comes after).
func clear() -> void:
	steps.clear()
	then = Callable()
	_elapsed = 0
	_started = false


func _next() -> void:
	steps.pop_front()
	_elapsed = 0
	_started = false
	if steps.is_empty():
		var after := then
		then = Callable()
		if after.is_valid():
			after.call()
	else:
		current()
