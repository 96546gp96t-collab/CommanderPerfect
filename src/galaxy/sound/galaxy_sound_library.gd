class_name GalaxySoundLibrary
extends RefCounted
## Every sound and song of a Galaxy episode as audio streams, made in the
## background: the PC speaker sounds through [SpeakerSynth], the AdLib
## sounds and the songs through our OPL2 synthesiser ([GalaxyOpl]), each
## as its own WorkerThreadPool task (as [GraphicsLoader] scales graphics).
## AdLib renderings are kept in a [GalaxySoundCache], so a second start
## only reads them. [method poll] (on the main thread) turns finished work
## into streams; until then [method stream] gives null and that sound or
## song stays silent.

enum Kind { PC, ADLIB, SONG }

const KIND_COUNT := 3

var cache: GalaxySoundCache
var pc_sounds: Array[GalaxyPcSound] = []
var adlib_sounds: Array[GalaxyAdlibSound] = []
var songs: Array[GalaxyMusic] = []
## How many AdLib sounds and songs were rendered, and how many read from
## the cache (for tests and the timings).
var rendered_count := 0
var loaded_count := 0
## The chunks of the AdLib sounds and songs, for the cache's names.
var _adlib_chunks: Array[PackedByteArray] = []
var _song_chunks: Array[PackedByteArray] = []
## Finished streams by kind and number (main thread only).
var _streams: Array[Dictionary] = [{}, {}, {}]
## Work finished by the tasks, waiting for [method poll].
var _results: Array[Dictionary] = []
var _mutex := Mutex.new()
var _tasks: Array[int] = []
var _cancelled := false


## The sounds of [param audio]: [param sound_count] PC sounds from chunk
## 0, as many AdLib sounds after them, and [param song_count] songs from
## chunk [param first_song].
static func create(
	audio: GalaxyAudioFile,
	sound_count: int,
	first_song: int,
	song_count: int,
	sound_cache := GalaxySoundCache.new()
) -> GalaxySoundLibrary:
	var library := GalaxySoundLibrary.new()
	library.cache = sound_cache
	for index in sound_count:
		library.pc_sounds.append(GalaxyPcSound.parse(audio.chunk(index)))
		var adlib := audio.chunk(sound_count + index)
		library._adlib_chunks.append(adlib)
		library.adlib_sounds.append(GalaxyAdlibSound.parse(adlib))
	for index in song_count:
		var chunk := audio.chunk(first_song + index)
		library._song_chunks.append(chunk)
		library.songs.append(GalaxyMusic.parse(chunk))
	return library


## Starts the background work: the sounds first, then the songs, song
## [param first_song] before the others, then [param next_songs] in their
## order (none by default), then the rest.
func start(first_song := 0, next_songs := PackedInt32Array()) -> void:
	for index in pc_sounds.size():
		_add_task(Kind.PC, index, true)
		_add_task(Kind.ADLIB, index, true)
	var order: Array[int] = []
	var wanted := PackedInt32Array([first_song])
	wanted.append_array(next_songs)
	for song in wanted:
		if song >= 0 and song < songs.size() and not order.has(song):
			order.append(song)
	for index in songs.size():
		if not order.has(index):
			order.append(index)
	for index in order:
		_add_task(Kind.SONG, index, false)


## Takes the finished work (main thread). Returns whether anything new
## became ready.
func poll() -> bool:
	_mutex.lock()
	var finished := _results.duplicate()
	_results.clear()
	_mutex.unlock()
	for result: Dictionary in finished:
		var kind: int = result["kind"]
		_streams[kind][result["index"]] = _stream_of(result)
	var waiting: Array[int] = []
	for task in _tasks:
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
		else:
			waiting.append(task)
	_tasks = waiting
	return not finished.is_empty()


## The stream of sound or song [param index], or null while it is not
## ready (or does not exist).
func stream(kind: Kind, index: int) -> AudioStreamWAV:
	return _streams[kind].get(index)


## How important sound [param index] is (the original's priority).
func priority(kind: Kind, index: int) -> int:
	var sound: RefCounted = _sound(kind, index)
	return sound.priority if sound != null else 0


## How long sound [param index] counts as playing, in seconds.
func duration(kind: Kind, index: int) -> float:
	var sound: RefCounted = _sound(kind, index)
	return sound.duration() if sound != null else 0.0


func sound_count() -> int:
	return pc_sounds.size()


## Whether all the background work is done.
func is_ready() -> bool:
	return _tasks.is_empty()


## Waits for all the work (for tests and tools).
func wait() -> void:
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()
	poll()


## Stops what has not been rendered yet and waits for the tasks to end.
func stop() -> void:
	_cancelled = true
	wait()


func _add_task(kind: Kind, index: int, high_priority: bool) -> void:
	if _sound(kind, index) == null:
		return
	_tasks.append(WorkerThreadPool.add_task(_render.bind(kind, index), high_priority))


func _sound(kind: Kind, index: int) -> RefCounted:
	var list: Array = [pc_sounds, adlib_sounds, songs][kind]
	return list[index] if index >= 0 and index < list.size() else null


## The work of one task (a worker thread): from the cache, or rendered
## and then stored in it.
func _render(kind: Kind, index: int) -> void:
	if _cancelled:
		return
	var result := {"kind": kind, "index": index, "loop_begin": -1, "loop_end": -1}
	if kind == Kind.PC:
		result["pcm"] = pc_sounds[index].render_samples()
		result["rate"] = SpeakerSynth.MIX_RATE
	else:
		var chunk: PackedByteArray = (
			_adlib_chunks[index] if kind == Kind.ADLIB else _song_chunks[index]
		)
		var name := GalaxySoundCache.key(chunk)
		var entry := cache.load_entry(name)
		var loaded := not entry.is_empty()
		if not loaded:
			entry = _render_opl(kind, index)
			if entry.is_empty():
				return
			cache.save_entry(name, entry["pcm"], entry["loop_begin"], entry["loop_end"])
		_mutex.lock()
		if loaded:
			loaded_count += 1
		else:
			rendered_count += 1
		_mutex.unlock()
		result.merge(entry, true)
		result["rate"] = GalaxyOpl.CHIP_RATE
	_mutex.lock()
	_results.append(result)
	_mutex.unlock()


func _render_opl(kind: Kind, index: int) -> Dictionary:
	if kind == Kind.ADLIB:
		var samples := adlib_sounds[index].render_samples()
		return {"pcm": GalaxyOpl.to_pcm16(samples), "loop_begin": -1, "loop_end": -1}
	var song := songs[index].render(func() -> bool: return _cancelled)
	if song.is_empty():
		return {}
	return {
		"pcm": GalaxyOpl.to_pcm16(song["samples"]),
		"loop_begin": song["loop_begin"],
		"loop_end": song["loop_end"],
	}


static func _stream_of(result: Dictionary) -> AudioStreamWAV:
	var stream := GalaxyOpl.make_stream(result["pcm"], result["loop_begin"], result["loop_end"])
	stream.mix_rate = result["rate"]
	return stream
