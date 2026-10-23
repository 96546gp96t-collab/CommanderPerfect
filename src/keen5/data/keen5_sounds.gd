class_name Keen5Sounds
extends RefCounted
## Keen 5's sounds by the names the Galaxy and Keen 5 code play, and which
## song plays on which map (Omni `EPISODE.CK5`: the sound numbers,
## CK_LevelMusic, CK_EndingMusicLevel, CK_StarWarsMusicLevel; `ck_text.c`,
## `ck5_misc.c`: the help's map 19, game over's map 18). Where Omnispeak
## names a sound UNKNOWN, the name is Commander Genius's
## (`CAudioGalaxy.cpp`) or says what plays it; the numbers are Keen 5's own,
## not Keen 4's (the gem door is 60 here, 18 is the security door).
##
## AUDIO.CK5: chunks 0-63 are the PC speaker sounds, 64-127 the same sounds
## for the AdLib, 128-191 the (empty) digitised sounds, then the 14 songs,
## chunks 192-205 (docs/keen5/file-formats.md, "AUDIO.CK5").

const SOUND_COUNT := 64
const SONG_COUNT := 14
## The sound numbers (Omni names in lower case where it has one). Not
## played by Keen 5: 11, 22, 24, 26, 51 and 62 (Omni UNKNOWN), 43 and 44
## (the thrown flag's, CG; Keen 5's flags only wave), 56 (the elevator's
## ride, CG; Omnispeak plays only the door, 63), the Paddle War sounds
## 46-50 (E9).
const NUMBERS: Dictionary[StringName, int] = {
	&"keen_walk_1": 0,
	&"keen_walk_2": 1,
	&"keen_jump": 2,
	&"keen_land": 3,
	&"keen_shoot": 4,
	&"mine_explode": 5,
	&"slice_bump": 6,
	&"keen_pogo": 7,
	&"got_item": 8,
	&"got_stunner": 9,
	# The Vitalin (Omni SOUND_GOTCENTILIFE; Keen 4's drop).
	&"got_drop": 10,
	&"unknown_11": 11,
	# Omni UNKNOWN12, played when Keen enters a level on the map.
	&"enter_level": 12,
	&"level_exit": 13,
	&"need_keycard": 14,
	&"keen_hit_ceiling": 15,
	&"spindred_fly_up": 16,
	&"got_extra_life": 17,
	&"open_security_door": 18,
	&"got_gem": 19,
	&"keen_fall": 20,
	&"keen_out_of_ammo": 21,
	&"unknown_22": 22,
	&"keen_die": 23,
	&"unknown_24": 24,
	&"shot_hit": 25,
	&"unknown_26": 26,
	&"spiro_slam": 27,
	&"spindred_slam": 28,
	&"enemy_shoot": 29,
	&"enemy_shot_hit": 30,
	&"ampton_walk_1": 31,
	&"ampton_walk_2": 32,
	&"ampton_stun": 33,
	&"status_down": 34,
	&"status_up": 35,
	&"shelley_explode": 36,
	&"spindred_fly_down": 37,
	&"master_shot": 38,
	&"master_teleport": 39,
	&"pole_zap": 40,
	# Omni UNKNOWN41: the teleporters on the map and the lightning at the
	# door to Korath III.
	&"teleport": 41,
	&"shockshund_bark": 42,
	&"flag_flip": 43,
	&"flag_land": 44,
	&"bark_shot_die": 45,
	&"paddle_keen": 46,
	&"paddle_wall": 47,
	&"paddle_computer": 48,
	&"paddle_computer_scores": 49,
	&"paddle_keen_scores": 50,
	&"unknown_51": 51,
	# Omni UNKNOWN52: a fuse breaks (CK5_SpawnFuseExplosion).
	&"fuse_break": 52,
	&"galaxy_explode": 53,
	&"galaxy_explode_pre": 54,
	&"got_keycard": 55,
	&"elevating": 56,
	&"keen_land_on_fuse": 57,
	&"sparky_prepare_charge": 58,
	&"sphereful_ceiling": 59,
	&"open_gem_door": 60,
	&"spiro_fly": 61,
	&"unknown_62": 62,
	# Omni UNKNOWN63: the elevator's door opening and closing.
	&"elevator_door": 63,
}
## The song of every map 0-19 (Omni CK_LevelMusic). Maps 14 and 16-19 are
## no maps (14 is missing from GAMEMAPS) but name the songs of the screens:
## 14 the end (the Fanfare), 16 a song nothing plays, 17 the story, 18 game
## over, 19 the help.
const MAP_SONGS: PackedInt32Array = [
	11, 5, 7, 9, 10, 9, 10, 9, 10, 9, 10, 3, 13, 4, 12, 2, 6, 1, 0, 8
]
## The maps whose songs the screens between the games play (Omni): the
## end pages, the story, game over, the help.
const ENDING_MAP := 14
const STORY_MAP := 17
const GAME_OVER_MAP := 18
const HELP_MAP := 19
const NO_SONG := -1


## The song of map [param map]; [constant NO_SONG] for none.
static func song_for_map(map: int) -> int:
	if map < 0 or map >= MAP_SONGS.size():
		return NO_SONG
	return MAP_SONGS[map]
