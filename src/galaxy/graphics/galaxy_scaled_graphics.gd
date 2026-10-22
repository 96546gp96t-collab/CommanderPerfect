class_name GalaxyScaledGraphics
extends RefCounted
## xBRZ versions of a Galaxy episode's 16×16 tiles and sprites, made with
## the shared [XbrzScaler] on worker threads (as [GraphicsLoader] does for
## Keen 1-3) and kept once made. [ScaledGraphics] and [GraphicsLoader] are
## typed on Keen 1-3's [EgaGraphics], hence this small class.
##
## Keen 4 has 1296 + 2916 tiles and 397 sprites: scaling them all takes
## about ten seconds of processor time, and their atlas would not fit in
## memory well. So only what a level shows is scaled ([method prepare]: its
## tiles with their animation loops, and the sprites drawn), a few hundred
## images, and what was made stays for the next level.

## The kinds of image this class scales.
enum Kind { BACK_TILE, FORE_TILE, SPRITE }

## As large as Keen 1-3's xBRZ graphics.
const FACTOR := GraphicsLoader.XBRZ_FACTOR

var factor := FACTOR
var _graphics: GalaxyGraphics
var _made: Dictionary[Kind, Dictionary] = {Kind.BACK_TILE: {}, Kind.FORE_TILE: {}, Kind.SPRITE: {}}
var _task := -1
## The images being scaled, what they are, and the results at the same place;
## the results are written by the worker threads.
var _jobs: Array[Vector2i] = []
var _sources: Array[Image] = []
var _results: Array[Image] = []
var _lock := Mutex.new()


static func create(graphics: GalaxyGraphics) -> GalaxyScaledGraphics:
	var scaled := GalaxyScaledGraphics.new()
	scaled._graphics = graphics
	return scaled


## Starts scaling what is missing of [param back_tiles], [param fore_tiles]
## and [param sprites] (indices), unless scaling is already going on.
## Returns whether all of them are there now.
func prepare(
	back_tiles: PackedInt32Array, fore_tiles: PackedInt32Array, sprites: PackedInt32Array
) -> bool:
	var wanted: Dictionary[Kind, PackedInt32Array] = {
		Kind.BACK_TILE: back_tiles, Kind.FORE_TILE: fore_tiles, Kind.SPRITE: sprites
	}
	var jobs: Array[Vector2i] = []
	for kind: Kind in wanted:
		for index in wanted[kind]:
			if not _made[kind].has(index) and _original(kind, index) != null:
				jobs.append(Vector2i(kind, index))
	if jobs.is_empty():
		return true
	if is_busy():
		return false
	_jobs = jobs
	_sources.clear()
	# The originals are decoded here: GalaxyGraphics decodes lazily and is
	# not made for several threads.
	for job in jobs:
		_sources.append(_original(job.x as Kind, job.y))
	_results.resize(jobs.size())
	_task = WorkerThreadPool.add_group_task(_scale_one, jobs.size(), OS.get_processor_count(), true)
	return false


func is_busy() -> bool:
	return _task >= 0


## Checks whether the workers are done; returns true once, when they just
## finished.
func poll() -> bool:
	if _task < 0 or not WorkerThreadPool.is_group_task_completed(_task):
		return false
	finish()
	return true


## Waits for the workers (also when the game quits) and keeps their work.
func finish() -> void:
	if _task < 0:
		return
	WorkerThreadPool.wait_for_group_task_completion(_task)
	_task = -1
	for index in _jobs.size():
		if _results[index] != null:
			_made[_jobs[index].x][_jobs[index].y] = _results[index]
	_jobs.clear()
	_sources.clear()
	_results.clear()


## The scaled background tile [param index], or null when it is not made.
func back_tile(index: int) -> Image:
	return _made[Kind.BACK_TILE].get(index)


## The scaled foreground tile [param index], or null.
func fore_tile(index: int) -> Image:
	return _made[Kind.FORE_TILE].get(index)


## The scaled sprite [param index], or null.
func sprite(index: int) -> Image:
	return _made[Kind.SPRITE].get(index)


func _original(kind: Kind, index: int) -> Image:
	match kind:
		Kind.BACK_TILE:
			return _graphics.back_tile(index)
		Kind.FORE_TILE:
			return _graphics.fore_tile(index)
	return _graphics.sprite(index)


## Runs on a worker thread: scales job [param index].
func _scale_one(index: int) -> void:
	var scaled := XbrzScaler.scale(_sources[index], factor)
	_lock.lock()
	_results[index] = scaled
	_lock.unlock()
