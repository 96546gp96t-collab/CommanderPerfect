class_name Keen2Sounds
extends Node
## The sounds that only Keen 2 has: EARTHPOW, the Earth exploding. The
## shared [SoundPlayer] knows Keen 1's sounds by name ([Sound]); this plays
## the extra one on a speaker of its own, so that nothing of Keen 1 changes.
## [Keen2View] stops the shared player first, so that it sounds alone, as
## on the single PC speaker of the original.

## The name of the sound in the sound block of KEEN2.EXE. Chocolate Keen's
## list spells it "earthpow"; it is compared without case and may have a
## suffix such as SND.
const EARTH_POW_NAME := "EARTHPOW"

var enabled := true
var _earth_pow: AudioStreamWAV
var _speaker: AudioStreamPlayer


func _ready() -> void:
	_speaker = AudioStreamPlayer.new()
	add_child(_speaker)


## Renders the extra sounds in [param file]; without them the game stays
## silent there.
func load_sounds(file: SoundFile) -> void:
	_earth_pow = null
	if file == null:
		return
	var entry := find_entry(file, EARTH_POW_NAME)
	if entry != null and not entry.divisors.is_empty():
		_earth_pow = SpeakerSynth.render(entry.divisors)


## Whether there is an EARTHPOW sound to play.
func has_earth_pow() -> bool:
	return _earth_pow != null


func play_earth_pow() -> void:
	if not enabled or _earth_pow == null or _speaker == null:
		return
	_speaker.stream = _earth_pow
	_speaker.play()


## The entry of [param file] whose name starts with [param sound_name],
## ignoring case; null when there is none.
static func find_entry(file: SoundFile, sound_name: String) -> SoundFile.Entry:
	for key in file.sounds:
		if key.to_upper().begins_with(sound_name):
			return file.sounds[key]
	return null
