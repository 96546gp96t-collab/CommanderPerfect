class_name Keen5Progress
extends GalaxyProgress
## How far a game of Keen 5 has come ([GalaxyProgress], milestone E6; Omni
## `ck_def.h` ck_gameState.levelsDone, `ck_game.c:CK_GameLoop`,
## `ck5_misc.c:CK5_ScanInfoLayer`; docs/keen5/research.md §1, §8): a level
## left by a door counts 1, one ended by breaking its fuse 14
## (LS_KorathFuse); the four fuse levels done open the upper shaft on the
## world map ([method shaft_fuses_broken]); the Korath III fuse decides the
## secret end ([method korath_fuse_broken], milestone E7); and the door to
## Korath III in level 11 puts Keen on Korath III the next time the map is
## shown ([member korath_arrival], LS_TeleportToKorath).

## A level ended by breaking its fuse (Omni LS_KorathFuse).
const DONE_BY_FUSE := 14
## The four levels whose fuses guard the elevator shaft (Omni
## CK5_ScanInfoLayer), and Korath III's base.
const SHAFT_FUSE_LEVELS: PackedInt32Array = [4, 6, 8, 10]
const KORATH_LEVEL := 13
## The arrival's name in a saved game (milestone E9).
const KORATH_ARRIVAL_KEY := "korath_arrival"

## The last level was left by the door to Korath III: the map puts Keen
## there once (Omni levelState LS_TeleportToKorath).
var korath_arrival := false


## Whether the four fuse levels that guard the shaft are done (any value,
## as the original checks).
func shaft_fuses_broken() -> bool:
	for level in SHAFT_FUSE_LEVELS:
		if not is_done(level):
			return false
	return true


## Whether the fuse of Korath III's base was broken (the secret end).
func korath_fuse_broken() -> bool:
	return done_value(KORATH_LEVEL) == DONE_BY_FUSE


func map_shown() -> void:
	super()
	korath_arrival = false


## A saved game keeps the arrival on Korath III (milestone E9).
func _extra_to_dictionary() -> Dictionary:
	return {KORATH_ARRIVAL_KEY: korath_arrival}


func _extra_from_dictionary(saved: Dictionary) -> void:
	korath_arrival = bool(saved.get(KORATH_ARRIVAL_KEY, false))
