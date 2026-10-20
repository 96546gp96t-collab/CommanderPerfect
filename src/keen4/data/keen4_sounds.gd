class_name Keen4Sounds
extends RefCounted
## Keen 4's sounds by the names the Galaxy and Keen 4 code play, and which
## song plays where (Omni `EPISODE.CK4`: the sound numbers, CK_LevelMusic,
## ck4_specialMusic, CK_EndingMusicLevel, CK_StarWarsMusicLevel). The
## songs' titles name the series: they are never shown.
##
## AUDIO: chunks 0-51 are the PC speaker sounds, 52-103 the same sounds
## for the AdLib, then the (absent) digitised sounds, then the six songs
## (docs/keen4/file-formats.md, "AUDIO.CK4").

const SOUND_COUNT := 52
const SONG_COUNT := 6
## The sound numbers (Omni names in lower case). Some are not played by
## Keen 4: 11, 12's twin 24, and the Paddle War sounds 47-51 (D11).
const NUMBERS: Dictionary[StringName, int] = {
	&"keen_walk_1": 0,
	&"keen_walk_2": 1,
	&"keen_jump": 2,
	&"keen_land": 3,
	&"keen_shoot": 4,
	&"wormmouth_bite": 5,
	&"slice_bump": 6,
	&"keen_pogo": 7,
	&"got_item": 8,
	&"got_stunner": 9,
	&"got_drop": 10,
	&"unknown_11": 11,
	&"enter_level": 12,
	&"level_exit": 13,
	&"need_key": 14,
	&"keen_hit_ceiling": 15,
	&"mushroom_leap": 16,
	&"got_extra_life": 17,
	&"open_gem_door": 18,
	&"got_gem": 19,
	&"keen_fall": 20,
	&"keen_out_of_ammo": 21,
	&"skypest_squish": 22,
	&"keen_die": 23,
	&"unknown_24": 24,
	&"shot_hit": 25,
	&"keen_swim_high": 26,
	&"keen_swim_low": 27,
	&"mushroom_hop": 28,
	&"smirky_steal": 29,
	&"smirky_teleport": 30,
	&"council_saved": 31,
	&"lick_flame": 32,
	&"berkeloid_throw": 33,
	&"status_down": 34,
	&"status_up": 35,
	&"keen_bubble": 36,
	&"mine_explode": 37,
	&"sprite_shoot": 38,
	&"lightning_bolt": 39,
	&"fireball_land": 40,
	&"dart_shoot": 41,
	&"dopefish_burp": 42,
	&"flag_flip": 43,
	&"flag_land": 44,
	&"foot_appear": 45,
	&"slug_slime": 46,
	&"paddle_keen": 47,
	&"paddle_wall": 48,
	&"paddle_computer": 49,
	&"paddle_computer_scores": 50,
	&"paddle_keen_scores": 51,
}
## The Mimrock's jump is the sound of Keen hitting the ceiling (Omni).
const MIMROCK_JUMP := &"keen_hit_ceiling"
## The song of every map 0-19 (Omni CK_LevelMusic); -1: none (the
## high-score map).
const MAP_SONGS: PackedInt32Array = [0, 4, 3, 3, 2, 2, 4, 3, 1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 3, -1]
## The song of the council's and the janitor's messages (Omni
## ck4_specialMusic).
const COUNCIL_SONG := 5
## The end pages play map 7's song, the story map 12's (Omni).
const ENDING_MAP := 7
const STORY_MAP := 12
const NO_SONG := -1


## The song of map [param map]; [constant NO_SONG] for none.
static func song_for_map(map: int) -> int:
	if map < 0 or map >= MAP_SONGS.size():
		return NO_SONG
	return MAP_SONGS[map]


## The chunk of the first song in [param audio]: the last
## [constant SONG_COUNT] chunks are the songs (the same in 1.0 and 1.4).
static func first_song(audio: GalaxyAudioFile) -> int:
	return audio.chunk_count() - SONG_COUNT


## Every sound and song of Keen 4 in [param audio], not started yet.
static func library(audio: GalaxyAudioFile, cache := GalaxySoundCache.new()) -> GalaxySoundLibrary:
	return GalaxySoundLibrary.create(audio, SOUND_COUNT, first_song(audio), SONG_COUNT, cache)
