class_name Keen4Audio
extends GalaxyAudio
## Keen 4's sounds and music: the shared [GalaxyAudio] (since milestone
## E13) with Keen 4's songs from the start, so it picks a song before the
## sounds are read (Omni `ck_play.c`:StartMusic, CK_PlayLoop, `ck4_misc.c`,
## `ck_text.c`, `ck_inter.c`; facts only):
##   - every map plays its own song from its start (the high-score map
##     none);
##   - the council's and the janitor's messages play the council song;
##   - the end pages play map 7's song, the story map 12's;
##   - the help stops the music; afterwards the map's song starts again.
## The Keen 4 screen plays the council song itself
## ([method GalaxyAudio.start_song] with [constant Keen4Sounds.COUNCIL_SONG]).


func _init() -> void:
	map_songs = Keen4Sounds.MAP_SONGS


## The council's (and the janitor's) song (Omni ck4_specialMusic).
func play_council_song() -> void:
	start_song(Keen4Sounds.COUNCIL_SONG)


func play_ending_song() -> void:
	play_map_song(Keen4Sounds.ENDING_MAP)


func play_story_song() -> void:
	play_map_song(Keen4Sounds.STORY_MAP)
