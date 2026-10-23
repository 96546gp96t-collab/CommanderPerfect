class_name GalaxyAudio
extends GalaxySoundPlayer
## A Galaxy episode's sounds and music on top of the [GalaxySoundPlayer]
## (made from Keen 4's [Keen4Audio], milestone E8): the episode's sound
## names and the song of every map from its [GalaxyGameRules], the songs
## rendered in the background into the episode's own cache folder
## ([method GalaxyGameRules.sound_cache_folder]), the player's settings
## (sound off / PC speaker / AdLib and music on or off, the shared
## [UserSettings]; the quiet AdLib sounds, the episode's [GalaxySettings]).
## Which song plays where is the screens' (Omni StartMusic takes a map:
## every map plays its own song, the screens between the games the song of
## a map named by the rules).

const SOUND_MODE_TITLES: Dictionary[Mode, String] = {
	Mode.OFF: "Sound off",
	Mode.PC: "Sound: PC speaker",
	Mode.ADLIB: "Sound: AdLib",
}
const MILLISECONDS_PER_TIC := MILLISECONDS / GalaxyClock.TICS_PER_SECOND

## The song of every map (-1: none).
var map_songs := PackedInt32Array()


## Reads the sounds of [param data] by [param game_rules] and starts
## rendering them into the episode's cache (the songs of
## [param first_maps] first, in their order), with [param settings]'
## choices.
func load_sounds(
	data: GalaxyData,
	game_rules: GalaxyGameRules,
	settings: UserSettings,
	first_maps := PackedInt32Array()
) -> void:
	var cache := GalaxySoundCache.new(game_rules.sound_cache_folder())
	var first := first_song(data.audio, game_rules.song_count)
	var sounds := GalaxySoundLibrary.create(
		data.audio, game_rules.sound_count, first, game_rules.song_count, cache
	)
	map_songs = game_rules.map_songs
	use_library(sounds, game_rules.sound_names)
	apply_settings(settings)
	var order := PackedInt32Array()
	for map in first_maps:
		order.append(song_for_map(map))
	sounds.start(order[0] if not order.is_empty() else 0, order.slice(1))


## The chunk of the first song in [param audio]: the last
## [param song_count] chunks are the songs.
static func first_song(audio: GalaxyAudioFile, song_count: int) -> int:
	return audio.chunk_count() - song_count


func apply_settings(settings: UserSettings) -> void:
	set_mode(mode_named(settings.sound_device))
	set_music(settings.music_enabled)


## The song of map [param map]; [constant GalaxySoundPlayer.NO_SONG] for
## none.
func song_for_map(map: int) -> int:
	if map < 0 or map >= map_songs.size():
		return NO_SONG
	return map_songs[map]


## The song of map [param map] from its start (Omni StartMusic); a map
## without one stops the music.
func play_map_song(map: int) -> void:
	start_song(song_for_map(map))


## How many tics the sound playing now still counts as playing (0 when
## none does): what the original waits for with SD_WaitSoundDone.
func remaining_tics() -> int:
	var left := _playing_until - Time.get_ticks_msec()
	if left <= 0:
		return 0
	return ceili(left / MILLISECONDS_PER_TIC)


## The next sound setting: AdLib, PC speaker, off, AdLib again (the
## Shift+S key); stored in [param settings]. Returns its title.
func next_mode(settings: UserSettings) -> String:
	var next: Mode = (mode + Mode.size() - 1) % Mode.size() as Mode
	settings.sound_device = mode_name(next)
	set_mode(next)
	return SOUND_MODE_TITLES[next]


## Music on or off (the Shift+M key); stored in [param settings]. Returns
## its title.
func toggle_music(settings: UserSettings) -> String:
	settings.music_enabled = not music_on
	set_music(settings.music_enabled)
	return "Music " + ("on" if music_on else "off")
