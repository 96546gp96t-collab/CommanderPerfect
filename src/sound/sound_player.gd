class_name SoundPlayer
extends Node
## Plays the sounds of the game through one channel, like the single PC
## speaker of the original: a new sound only cuts off the one that is
## playing when its priority is at least as high (see [SoundFile]).
##
## Without SOUNDS.CK1 the game simply stays silent.

## Whether sounds are played at all (the "Sound (Y/N)?" setting).
var enabled := true
var _streams: Dictionary[Sound.Id, AudioStreamWAV] = {}
var _priorities: Dictionary[Sound.Id, int] = {}
var _speaker: AudioStreamPlayer
var _playing_priority := 0


func _ready() -> void:
	_speaker = AudioStreamPlayer.new()
	add_child(_speaker)


## Renders every known sound in [param file]. Sounds that the file lacks
## stay silent.
func load_sounds(file: SoundFile) -> void:
	_streams.clear()
	_priorities.clear()
	if file == null:
		return
	for id: Sound.Id in Sound.FILE_NAMES:
		var entry: SoundFile.Entry = file.sounds.get(Sound.FILE_NAMES[id])
		if entry != null and not entry.divisors.is_empty():
			_streams[id] = SpeakerSynth.render(entry.divisors)
			_priorities[id] = entry.priority


func play(id: Sound.Id) -> void:
	if not enabled or not _streams.has(id):
		return
	if not should_replace(_speaker.playing, _playing_priority, _priorities[id]):
		return
	_playing_priority = _priorities[id]
	_speaker.stream = _streams[id]
	_speaker.play()


func stop() -> void:
	_speaker.stop()


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		stop()


## Whether a sound of [param new_priority] may cut off what is playing.
static func should_replace(is_playing: bool, playing_priority: int, new_priority: int) -> bool:
	return not is_playing or new_priority >= playing_priority
