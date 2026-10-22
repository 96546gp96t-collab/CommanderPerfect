class_name Keen5Sprites
extends RefCounted
## Keen 5's sprites by the names the Galaxy code asks for: Keen's
## ([GalaxyKeenActions], [Keen5Keen]), the items' ([GalaxyItem]), the
## stunner shot's ([GalaxyStunnerShot]) and the score box. The numbers are
## sprite indices (Omni `data/keen5/GFXCHUNK.CK5`: chunk − 102 in v1.4;
## Keen standing matched the original's frame in js-dos, E3). Keen's
## sprites up to putting the book away are Keen 4's numbers; looking down
## is one earlier, KEENONPLAT follows, dying is at Keen 4's numbers, and
## from shooting on every picture is one further than Keen 4's.

const KEEN: Dictionary[StringName, int] = {
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
	&"LOOK_DOWN_1": 35,
	&"LOOK_DOWN_2": 36,
	# Standing on a platform (Omni SPR_KEENONPLAT; used from E5).
	&"ON_PLATFORM": 37,
	&"DIE_1": 38,
	&"DIE_2": 39,
	&"SHOOT_L": 44,
	&"JSHOOT_L": 45,
	&"JSHOOT_DOWN": 46,
	&"JSHOOT_UP": 47,
	&"SHOOT_UP": 48,
	&"SHOOT_R": 49,
	&"JSHOOT_R": 50,
	&"POLE_R_1": 57,
	&"POLE_R_2": 58,
	&"POLE_R_3": 59,
	&"SLIDE_1": 60,
	&"SLIDE_2": 61,
	&"SLIDE_3": 62,
	&"SLIDE_4": 63,
	&"POLE_L_1": 64,
	&"POLE_L_2": 65,
	&"POLE_L_3": 66,
	&"PSHOOT_UP_L": 67,
	&"PSHOOT_UP_R": 68,
	&"PSHOOT_DOWN_R": 69,
	&"PSHOOT_DOWN_L": 70,
	&"PSHOOT_L": 71,
	&"PSHOOT_R": 72,
	&"ENTER_1": 73,
	&"ENTER_2": 74,
	&"ENTER_3": 75,
	&"ENTER_4": 76,
	&"ENTER_5": 77,
	&"HANG_L": 78,
	&"HANG_R": 79,
	&"CLIMB_L_1": 80,
	&"CLIMB_L_2": 81,
	&"CLIMB_L_3": 82,
	&"CLIMB_L_4": 83,
	&"CLIMB_R_1": 84,
	&"CLIMB_R_2": 85,
	&"CLIMB_R_3": 86,
	&"CLIMB_R_4": 87,
	&"POGO_R_1": 88,
	&"POGO_R_2": 89,
	&"POGO_L_1": 90,
	&"POGO_L_2": 91,
}
## The shot, the Vitalin splash (four pictures; Keen 4's lifewater has
## three), the 1UP over the hundredth Vitalin, the score box.
const OBJECTS: Dictionary[StringName, int] = {
	&"STUN_1": 51,
	&"STUN_2": 52,
	&"STUN_3": 53,
	&"STUN_4": 54,
	&"STUN_HIT_1": 55,
	&"STUN_HIT_2": 56,
	&"EXTRA_LIFE_SPLASH": 92,
	&"SPLASH_1": 101,
	&"SPLASH_2": 102,
	&"SPLASH_3": 103,
	&"SPLASH_4": 104,
	&"SCOREBOX": 133,
}
## The machinery of the levels (milestone E5; Omni GFXCHUNK.CK5, chunk −
## 102): the fuse's explosion, the teleport lightning at the door to
## Korath III, the red platform (every kind but the purple ones) and the
## purple platform's two pictures.
const MACHINERY: Dictionary[StringName, int] = {
	&"FUSEFLASH1": 181,
	&"FUSEFLASH2": 182,
	&"FUSEFLASH3": 183,
	&"TELEPORTSPARK1": 188,
	&"TELEPORTSPARK2": 189,
	&"TELEPORTZAP1": 190,
	&"TELEPORTZAP2": 191,
	&"PURPLEPLAT1": 320,
	&"PURPLEPLAT2": 321,
	&"PLATFORM": 344,
}
## Items 0-12 ([GalaxyInventory], [Keen5Inventory]): the first of their two
## frames, and the shadow that rises when Keen takes one (Omni
## CK_ItemSpriteChunks, ck_itemShadows): four gems (red, yellow, blue,
## green), the 100 … 5000 point items, the Keg o' Vitalin (1UP), the
## stunner, the keycard.
const ITEM_FIRST_FRAMES: PackedInt32Array = [
	122, 124, 126, 128, 108, 110, 112, 114, 116, 118, 120, 131, 105
]
const ITEM_SHADOWS: PackedInt32Array = [130, 130, 130, 130, 93, 94, 95, 96, 97, 98, 99, 100, 107]


## All of them in one list, by name, with the creatures'
## ([Keen5CreatureSprites], E4) and the machinery's (E5).
static func all() -> Dictionary[StringName, int]:
	var sprites: Dictionary[StringName, int] = KEEN.duplicate()
	sprites.merge(OBJECTS)
	sprites.merge(Keen5CreatureSprites.SPRITES)
	sprites.merge(MACHINERY)
	for item in ITEM_FIRST_FRAMES.size():
		sprites[StringName("ITEM_%d" % item)] = ITEM_FIRST_FRAMES[item]
		sprites[StringName("SHADOW_%d" % item)] = ITEM_SHADOWS[item]
	return sprites
