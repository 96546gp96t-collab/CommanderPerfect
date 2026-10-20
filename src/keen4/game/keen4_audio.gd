class_name Keen4Audio
extends GalaxySoundPlayer
## Keen 4's sounds and music on top of the Galaxy [GalaxySoundPlayer]: its
## sound names ([Keen4Sounds]), its songs rendered in the background into
## user://keen4/cache, the player's settings (sound off / PC speaker /
## AdLib, music on or off; AdLib with music unless he chose otherwise), and
## which song plays where (Omni `ck_play.c`:StartMusic, CK_PlayLoop,
## `ck4_misc.c`, `ck_text.c`, `ck_inter.c`; facts only):
##   - every map plays its own song from its start (the high-score map
##     none);
##   - the council's and the janitor's messages play the council song;
##   - the end pages play map 7's song, the story map 12's;
##   - the help stops the music; afterwards the map's song starts again.

const SOUND_MODE_TITLES: Dictionary[Mode, String] = {
	Mode.OFF: "Sound off",
	Mode.PC: "Sound: PC speaker",
	Mode.ADLIB: "Sound: AdLib",
}


## Reads the sounds of [param data] and starts rendering them (map 0's
## song first, the one a new game needs), with [param settings]' choices.
func load_sounds(data: GalaxyData, settings: UserSettings, cache := GalaxySoundCache.new()) -> void:
	var sounds := Keen4Sounds.library(data.audio, cache)
	use_library(sounds, Keen4Sounds.NUMBERS)
	apply_settings(settings)
	sounds.start(Keen4Sounds.song_for_map(Keen4Episode.WORLD_MAP))


func apply_settings(settings: UserSettings) -> void:
	set_mode(mode_named(settings.sound_device))
	set_music(settings.music_enabled)


## The song of map [param map] from its start (Omni CK_PlayLoop).
func play_map_song(map: int) -> void:
	start_song(Keen4Sounds.song_for_map(map))


## The council's (and the janitor's) song (Omni ck4_specialMusic).
func play_council_song() -> void:
	start_song(Keen4Sounds.COUNCIL_SONG)


func play_ending_song() -> void:
	play_map_song(Keen4Sounds.ENDING_MAP)


func play_story_song() -> void:
	play_map_song(Keen4Sounds.STORY_MAP)


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
