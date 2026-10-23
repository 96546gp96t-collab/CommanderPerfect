class_name GalaxyCheats
extends RefCounted
## The original's two cheats of a Galaxy episode, checked while Keen plays
## (made from Keen 4's [Keen4Cheats], milestone E7; Omni `ck_play.c`:
## CK_PlayLoop, CK_CheckKeys, CK_ItemCheat; facts only):
##   - E, N and D held: the end (Keen 4: the eighth rescue; Keen 5: the QED
##     destroyed);
##   - B, A and T held: a box "Cheat Option! ..." until a key, then all four
##     gems, 99 charges and a life more (Keen 5: and the keycard; the
##     episode adds its own).
## A cheat counts once while its keys stay held.

enum Cheat { NONE, END, ITEMS }

const END_KEYS: Array[Key] = [KEY_E, KEY_N, KEY_D]
const ITEM_KEYS: Array[Key] = [KEY_B, KEY_A, KEY_T]
## The box: a window of 20 × 7 cells, the text centred from its top (Omni).
const BOX_CELLS := Vector2i(20, 7)
const CHEAT_TEXT := 0
const ITEM_SHOTS := 99

var _held := Cheat.NONE


## The cheat whose keys [param is_held] (a function of a [enum Key]) says
## are all held now, when they were not all held the frame before.
func check(is_held: Callable) -> Cheat:
	var now := Cheat.NONE
	if END_KEYS.all(is_held):
		now = Cheat.END
	elif ITEM_KEYS.all(is_held):
		now = Cheat.ITEMS
	var fresh := now if now != _held else Cheat.NONE
	_held = now
	return fresh


## B+A+T's gifts that every episode gives.
static func give_items(inventory: GalaxyInventory) -> void:
	inventory.shots = ITEM_SHOTS
	inventory.lives += 1
	inventory.gems = PackedInt32Array([1, 1, 1, 1])


## B+A+T's box, with the text of the player's program.
static func items_box(data: GalaxyData, game_rules: GalaxyGameRules) -> Image:
	var window := GalaxyWindow.create(data.graphics, game_rules.menu_font)
	window.open_centred(BOX_CELLS)
	var texts := data.executable.texts(game_rules.cheat_texts)
	window.print_centred(texts[CHEAT_TEXT] if not texts.is_empty() else "")
	return window.image()


## Whether [param key] is held on the keyboard now.
static func is_key_held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)
