class_name Keen3Sounds
extends Node
## The sounds that only Keen 3 has: ANKH, MEEP, MORTIMER and FOOTSLAM
## (entries 41-44 of the sound block in KEEN3.EXE). The shared [SoundPlayer]
## knows Keen 1's sounds by name ([Sound]); this plays the extra ones on a
## speaker of its own, as [Keen2Sounds] plays EARTHPOW, so that nothing of
## Keen 1 or Keen 2 changes. The entries are found with
## [method Keen2Sounds.find_entry]. The view stops the shared player first,
## so that the sound is heard alone, as on the single PC speaker.

const ANKH := "ANKH"
const MEEP := "MEEP"
const MORTIMER := "MORTIMER"
const FOOTSLAM := "FOOTSLAM"
const NAMES: PackedStringArray = [ANKH, MEEP, MORTIMER, FOOTSLAM]

var enabled := true
var _streams: Dictionary[String, AudioStreamWAV] = {}
var _speaker: AudioStreamPlayer


func _ready() -> void:
	_speaker = AudioStreamPlayer.new()
	add_child(_speaker)


## Renders the extra sounds in [param file]; a sound that is not there stays
## silent.
func load_sounds(file: SoundFile) -> void:
	_streams.clear()
	if file == null:
		return
	for sound_name in NAMES:
		var entry := Keen2Sounds.find_entry(file, sound_name)
		if entry != null and not entry.divisors.is_empty():
			_streams[sound_name] = SpeakerSynth.render(entry.divisors)


## Whether the sound [param sound_name] (one of [constant NAMES]) was found.
func has_sound(sound_name: String) -> bool:
	return _streams.has(sound_name)


func play(sound_name: String) -> void:
	if not enabled or _speaker == null or not _streams.has(sound_name):
		return
	_speaker.stream = _streams[sound_name]
	_speaker.play()
