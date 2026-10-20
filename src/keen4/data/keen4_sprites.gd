class_name Keen4Sprites
extends RefCounted
## Keen 4's sprites by the names the Galaxy code asks for: Keen's
## ([GalaxyKeenActions]), the items' ([GalaxyItem]), the stunner shot's
## ([GalaxyStunnerShot]), the score box and the creatures'
## ([Keen4CreatureSprites]). The numbers are sprite indices
## (Omni `GFXCHUNK.CK4` chunk − 124 in v1.4); the same in the user's v1.0
## (files: checked on a sheet of all sprites, D4).

const KEEN: Dictionary[StringName, int] = {
	&"SWIM_L_1": 185,
	&"SWIM_L_2": 186,
	&"SWIM_R_1": 187,
	&"SWIM_R_2": 188,
	&"SUIT_DIE_1": 189,
	&"SUIT_DIE_2": 190,
	&"STAND_R": 6,
	&"RUN_R_1": 7,
	&"RUN_R_2": 8,
	&"RUN_R_3": 9,
	&"RUN_R_4": 10,
	&"JUMP_R_1": 11,
	&"JUMP_R_2": 12,
	&"JUMP_R_3": 13,
	&"STAND_L": 14,
	&"RUN_L_1": 15,
	&"RUN_L_2": 16,
	&"RUN_L_3": 17,
	&"RUN_L_4": 18,
	&"JUMP_L_1": 19,
	&"JUMP_L_2": 20,
	&"JUMP_L_3": 21,
	&"LOOK_UP": 22,
	&"WAIT_1": 23,
	&"WAIT_2": 24,
	&"WAIT_3": 25,
	&"SIT_1": 26,
	&"SIT_2": 27,
	&"SIT_3": 28,
	&"SIT_4": 29,
	&"READ_1": 30,
	&"READ_2": 31,
	&"READ_3": 32,
	&"STOW_1": 33,
	&"STOW_2": 34,
	&"LOOK_DOWN_1": 36,
	&"LOOK_DOWN_2": 37,
	&"DIE_1": 38,
	&"DIE_2": 39,
	&"SHOOT_L": 43,
	&"JSHOOT_L": 44,
	&"JSHOOT_DOWN": 45,
	&"JSHOOT_UP": 46,
	&"SHOOT_UP": 47,
	&"SHOOT_R": 48,
	&"JSHOOT_R": 49,
	&"POLE_R_1": 56,
	&"POLE_R_2": 57,
	&"POLE_R_3": 58,
	&"SLIDE_1": 59,
	&"SLIDE_2": 60,
	&"SLIDE_3": 61,
	&"SLIDE_4": 62,
	&"POLE_L_1": 63,
	&"POLE_L_2": 64,
	&"POLE_L_3": 65,
	&"PSHOOT_UP_L": 66,
	&"PSHOOT_UP_R": 67,
	&"PSHOOT_DOWN_R": 68,
	&"PSHOOT_DOWN_L": 69,
	&"PSHOOT_L": 70,
	&"PSHOOT_R": 71,
	&"ENTER_1": 72,
	&"ENTER_2": 73,
	&"ENTER_3": 74,
	&"ENTER_4": 75,
	&"ENTER_5": 76,
	&"HANG_L": 77,
	&"HANG_R": 78,
	&"CLIMB_L_1": 79,
	&"CLIMB_L_2": 80,
	&"CLIMB_L_3": 81,
	&"CLIMB_L_4": 82,
	&"CLIMB_R_1": 83,
	&"CLIMB_R_2": 84,
	&"CLIMB_R_3": 85,
	&"CLIMB_R_4": 86,
	&"POGO_R_1": 87,
	&"POGO_R_2": 88,
	&"POGO_L_1": 89,
	&"POGO_L_2": 90,
	&"MOON_1": 395,
	&"MOON_2": 396,
}
const OBJECTS: Dictionary[StringName, int] = {
	&"STUN_1": 50,
	&"STUN_2": 51,
	&"STUN_3": 52,
	&"STUN_4": 53,
	&"STUN_HIT_1": 54,
	&"STUN_HIT_2": 55,
	&"SPLASH_1": 91,
	&"SPLASH_2": 92,
	&"SPLASH_3": 93,
	&"EXTRA_LIFE_SPLASH": 94,
	&"SCOREBOX": 129,
}
## Items 0-11 ([GalaxyInventory]): the first of their two frames, and the
## shadow that rises when Keen takes one (Omni CK_ItemSpriteChunks,
## ck_itemShadows): four gems (red, yellow, blue, green), the 100 … 5000
## point items, the lifewater flask (1UP), the stunner.
const ITEM_FIRST_FRAMES: PackedInt32Array = [
	118, 120, 122, 124, 103, 105, 107, 109, 111, 113, 115, 127
]
const ITEM_SHADOWS: PackedInt32Array = [126, 126, 126, 126, 95, 96, 97, 98, 99, 100, 101, 102]


## All of them in one list, by name.
static func all() -> Dictionary[StringName, int]:
	var sprites: Dictionary[StringName, int] = KEEN.duplicate()
	sprites.merge(OBJECTS)
	sprites.merge(Keen4CreatureSprites.SPRITES)
	for item in ITEM_FIRST_FRAMES.size():
		sprites[StringName("ITEM_%d" % item)] = ITEM_FIRST_FRAMES[item]
		sprites[StringName("SHADOW_%d" % item)] = ITEM_SHADOWS[item]
	return sprites
