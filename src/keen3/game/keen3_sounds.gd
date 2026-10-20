class_name Keen3Sounds
extends Node
## The sounds that only Keen 3 has: ANKH, MEEP, MORTIMER and FOOTSLAM
## (entries 41-44 of the sound block in KEEN3.EXE). The shared [SoundPlayer]
## knows Keen 1's sounds by name ([Sound]); this plays the extra ones on a
## speaker of its own, as [Keen2Sounds] plays EARTHPOW, so that nothing of
## Keen 1 or Keen 2 changes. The entries are found with
## [method Keen2Sounds.find_entry].
##
## The original has one speaker, and a sound only cuts off the one that
## plays when its priority is at least as high (Choco
## `CVort_engine_setCurSound`). The two speakers act as one: the view stops
## the shared player before one of these starts, and asks
## [method give_way_to] before a shared sound starts, which stops this
## speaker when the new sound may cut it off. One of these sounds does not
## look at the priority of a shared sound that plays: theirs are 200 and
## up, so only MEEP could cut off a more important one.
##
## The view also reads the length of any sound here ([method seconds_of]):
## Mortimer waits for his sound, and the end text starts MORTIMER after
## keensleft.

const ANKH := "ANKH"
const MEEP := "MEEP"
const MORTIMER := "MORTIMER"
const FOOTSLAM := "FOOTSLAM"
const NAMES: PackedStringArray = [ANKH, MEEP, MORTIMER, FOOTSLAM]

var enabled := true
var _streams: Dictionary[String, AudioStreamWAV] = {}
var _file: SoundFile
var _speaker: AudioStreamPlayer
var _playing_priority := 0


func _ready() -> void:
	_speaker = AudioStreamPlayer.new()
	add_child(_speaker)


## Renders the extra sounds in [param file]; a sound that is not there stays
## silent.
func load_sounds(file: SoundFile) -> void:
	_streams.clear()
	_file = file
	if file == null:
		return
	for sound_name in NAMES:
		var entry := Keen2Sounds.find_entry(file, sound_name)
		if entry != null and not entry.divisors.is_empty():
			_streams[sound_name] = SpeakerSynth.render(entry.divisors)


## Whether the sound [param sound_name] (one of [constant NAMES]) was found.
func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)


## Plays [param sound_name] (one of [constant NAMES]), unless one of these
## with a higher priority is still playing. Returns whether it started.
func play(sound_name: String) -> bool:
	if not enabled or _speaker == null or not _streams.has(sound_name):
		return false
	var priority := priority_of(sound_name)
	if not SoundPlayer.should_replace(_speaker.playing, _playing_priority, priority):
		return false
	_playing_priority = priority
	_speaker.stream = _streams[sound_name]
	_speaker.play()
	return true


func stop() -> void:
	if _speaker != null:
		_speaker.stop()


## Whether one of these sounds is playing.
func is_playing() -> bool:
	return _speaker != null and _speaker.playing


## Whether the shared sound [param file_name] (a name of the sound block,
## such as [code]SHOTHIT[/code]) may sound now. When it may, the sound of
## this speaker stops, as on the single speaker; when one of these plays
## with a higher priority, it may not.
func give_way_to(file_name: String) -> bool:
	if not is_playing():
		return true
	if not SoundPlayer.should_replace(true, _playing_priority, priority_of(file_name)):
		return false
	stop()
	return true


## The priority of the sound [param sound_name] in the sound block; -1 when
## there is no such sound.
func priority_of(sound_name: String) -> int:
	var entry := Keen2Sounds.find_entry(_file, sound_name) if _file != null else null
	return entry.priority if entry != null else -1


## How long the sound [param sound_name] of the sound block lasts, in
## seconds (one value per tick of the sound timer); 0 when it was not found.
## Mortimer waits for his sound to end, also with the sound off.
func seconds_of(sound_name: String) -> float:
	var entry := Keen2Sounds.find_entry(_file, sound_name) if _file != null else null
	return entry.divisors.size() / SoundFile.STEPS_PER_SECOND if entry != null else 0.0


## How long the sound [param sound_name] (one of [constant NAMES]) lasts;
## see [method seconds_of].
func seconds(sound_name: String) -> float:
	return seconds_of(sound_name) if _streams.has(sound_name) else 0.0
