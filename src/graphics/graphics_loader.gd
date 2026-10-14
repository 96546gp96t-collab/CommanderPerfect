class_name GraphicsLoader
extends RefCounted
## Makes the xBRZ graphics, or reads the player's HD graphics, on worker
## threads: that takes a moment, and the game keeps running in the
## meantime. xBRZ is spread over all processor cores, one image per job.
## What it made is kept, so switching back and forth is instant.

## How many times larger xBRZ makes the graphics: as far as xBRZ goes, and
## about what a full HD screen needs (200 lines times 6 is 1200).
const XBRZ_FACTOR := 6

var _files: GameFiles
var _graphics: EgaGraphics
var _finale: Image
var _made: Dictionary[DisplaySettings.Graphics, ScaledGraphics] = {}
var _failed: Dictionary[DisplaySettings.Graphics, bool] = {}
var _task := -1
var _task_style := DisplaySettings.Graphics.ORIGINAL
## The images to scale and, at the same place, the result; written by the
## worker threads, read once the task is done.
var _sources: Array[Image] = []
var _results: Array[Image] = []
var _hd: ScaledGraphics
var _lock := Mutex.new()


static func create(files: GameFiles, graphics: EgaGraphics, finale: Image) -> GraphicsLoader:
	var loader := GraphicsLoader.new()
	loader._files = files
	loader._graphics = graphics
	loader._finale = finale
	return loader


## The graphics for [param style], or null when they are not there (yet).
## Starts making them when that has not happened, unless another style is
## being made right now.
func fetch(style: DisplaySettings.Graphics) -> ScaledGraphics:
	if _made.has(style) or _failed.has(style) or is_busy():
		return _made.get(style)
	_task_style = style
	_hd = null
	if style == DisplaySettings.Graphics.XBRZ:
		_sources = ScaledGraphics.originals(_graphics, _finale)
		_results.resize(_sources.size())
		_task = WorkerThreadPool.add_group_task(
			_scale_one, _sources.size(), OS.get_processor_count(), true
		)
	else:
		_task = WorkerThreadPool.add_group_task(_read_hd, 1)
	return null


## Whether making [param style] failed (the HD graphics are missing or do
## not fit the game files).
func has_failed(style: DisplaySettings.Graphics) -> bool:
	return _failed.has(style)


func is_busy() -> bool:
	return _task >= 0


## Checks whether the workers are done; returns true once, when they just
## finished.
func poll() -> bool:
	if _task < 0 or not WorkerThreadPool.is_group_task_completed(_task):
		return false
	finish()
	return true


## Waits for the workers, for example when the game quits.
func finish() -> void:
	if _task < 0:
		return
	WorkerThreadPool.wait_for_group_task_completion(_task)
	_task = -1
	var made := _hd
	if _task_style == DisplaySettings.Graphics.XBRZ:
		made = ScaledGraphics.from_images(_graphics, _finale, _results, XBRZ_FACTOR)
	if made != null and made.matches(_graphics):
		_made[_task_style] = made
	else:
		_failed[_task_style] = true
	_sources.clear()
	_results.clear()
	_hd = null


## Runs on a worker thread: scales image [param index].
func _scale_one(index: int) -> void:
	var scaled := XbrzScaler.scale(_sources[index], XBRZ_FACTOR)
	_lock.lock()
	_results[index] = scaled
	_lock.unlock()


## Runs on a worker thread.
func _read_hd(_index: int) -> void:
	_hd = HdPack.load_from(_files, _graphics, _finale)
