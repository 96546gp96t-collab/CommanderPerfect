class_name GalaxySoundPlayer
extends Node
## Plays a Galaxy episode's sounds and music as the original does (Omni
## `id_sd.c`, facts only):
##   - one sound at a time, from the PC speaker or the AdLib (the sound
##     mode); a new sound only starts when its priority is at least that
##     of the sound still playing, and a sound counts as playing for the
##     length of its notes (afterwards its priority is 0);
##   - one song at a time, AdLib only, looping; starting a song starts it
##     from its beginning; music off is silence.
## The streams come from a [GalaxySoundLibrary] that renders them in the
## background: a sound that is not ready is skipped, a song that is not
## ready starts as soon as it is.

enum Mode { OFF, PC, ADLIB }

## The setting's names (stored by the shared [UserSettings]).
const MODE_NAMES: Dictionary[String, Mode] = {"off": Mode.OFF, "pc": Mode.PC, "adlib": Mode.ADLIB}
const DEFAULT_MODE := Mode.ADLIB
const NO_SONG := -1
const MILLISECONDS := 1000.0

var mode := DEFAULT_MODE
var music_on := true
var library: GalaxySoundLibrary
## The episode's sound names to their numbers.
var names: Dictionary[StringName, int] = {}
var _sound_player := AudioStreamPlayer.new()
var _music_player := AudioStreamPlayer.new()
var _playing_priority := 0
## The number of the sound that counts as playing (-1: none).
var _playing_sound := -1
## Until when (in milliseconds since the start) the sound counts as playing.
var _playing_until := 0
## The song that should play (also while it is still being rendered).
var _song := NO_SONG
var _song_started := false
var _paused := false


func _ready() -> void:
	add_child(_sound_player)
	add_child(_music_player)


func _process(_delta: float) -> void:
	if library != null and library.poll() and not _song_started:
		_begin_song()


func _exit_tree() -> void:
	if library != null:
		library.stop()


## Uses [param sounds] (started here) with the sound names [param sound_names].
func use_library(sounds: GalaxySoundLibrary, sound_names: Dictionary[StringName, int]) -> void:
	library = sounds
	names = sound_names


## The mode named [param name] in the settings; AdLib for an unknown name.
static func mode_named(name: String) -> Mode:
	return MODE_NAMES.get(name, DEFAULT_MODE)


static func mode_name(value: Mode) -> String:
	return MODE_NAMES.find_key(value)


func set_mode(value: Mode) -> void:
	if value != mode:
		stop_sound()
	mode = value


func set_music(on: bool) -> void:
	music_on = on
	if on:
		_begin_song()
	else:
		_music_player.stop()
		_song_started = false


## Plays the sound named [param name] (unknown names are silent); with
## [param interrupt] whatever plays is stopped first (Omni SD_StopSound).
func play(name: StringName, interrupt := false) -> void:
	if interrupt:
		stop_sound()
	play_number(names.get(name, -1))


## Plays sound [param number] when its priority allows it.
func play_number(number: int) -> void:
	if mode == Mode.OFF or library == null or number < 0:
		return
	var kind := GalaxySoundLibrary.Kind.PC if mode == Mode.PC else GalaxySoundLibrary.Kind.ADLIB
	var priority := library.priority(kind, number)
	if is_sound_playing() and priority < _playing_priority:
		return
	_playing_priority = priority
	_playing_sound = number
	_playing_until = Time.get_ticks_msec() + roundi(library.duration(kind, number) * MILLISECONDS)
	var stream := library.stream(kind, number)
	_sound_player.stop()
	if stream != null:
		_sound_player.stream = stream
		_sound_player.play()


## Whether a sound still counts as playing (its notes are not over).
func is_sound_playing() -> bool:
	return Time.get_ticks_msec() < _playing_until


## The sound that counts as playing, or -1.
func current_sound() -> int:
	return _playing_sound if is_sound_playing() else -1


## The priority of the sound that counts as playing (0 when none does).
func current_priority() -> int:
	return _playing_priority if is_sound_playing() else 0


## The sound's notes are over (as when its time has passed): a sound of
## any priority may play again.
func sound_finished() -> void:
	_playing_until = 0
	_playing_priority = 0
	_playing_sound = -1


func stop_sound() -> void:
	_sound_player.stop()
	sound_finished()


## Starts song [param song] from its beginning; [constant NO_SONG] stops
## the music.
func start_song(song: int) -> void:
	_song = song
	_music_player.stop()
	_song_started = false
	_begin_song()


func stop_music() -> void:
	start_song(NO_SONG)


## The song that plays (or waits to be ready); [constant NO_SONG] for none.
func song() -> int:
	return _song


func is_music_playing() -> bool:
	return _music_player.playing and not _paused


## Holds the music where it is (a pause), or lets it go on.
func pause_music(paused: bool) -> void:
	_paused = paused
	_music_player.stream_paused = paused


func _begin_song() -> void:
	if not music_on or _song == NO_SONG or library == null or _song_started:
		return
	var stream := library.stream(GalaxySoundLibrary.Kind.SONG, _song)
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.stream_paused = _paused
	_music_player.play()
	_song_started = true
