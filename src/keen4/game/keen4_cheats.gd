class_name Keen4Cheats
extends RefCounted
## The original's two cheats, checked while Keen plays (Omni `ck_play.c`:
## CK_PlayLoop, CK_CheckKeys, CK_ItemCheat; facts only):
##   - E, N and D held: the end. The level counts as a rescue of the eighth
##     council member (the rescue's boxes for this map), then the end;
##   - B, A and T held: a box "Cheat Option! ..." until a key, then all four
##     gems, 99 charges and a life more.
## A cheat counts once while its keys stay held.
## Ours, as in Keen 1-3 (D13.2): Shift+I gives everything without a box
## ([method give_everything]); Shift+G is god mode ([Keen4View]).

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


## B+A+T's gifts.
static func give_items(inventory: GalaxyInventory) -> void:
	inventory.shots = ITEM_SHOTS
	inventory.lives += 1
	inventory.gems = PackedInt32Array([1, 1, 1, 1])


## Shift+I (ours, Keen 1-3's testing cheat): all four gems and at least
## 99 charges, no life more.
static func give_everything(inventory: GalaxyInventory) -> void:
	inventory.shots = maxi(inventory.shots, ITEM_SHOTS)
	inventory.gems = PackedInt32Array([1, 1, 1, 1])


## B+A+T's box, with the text of the player's program.
static func items_box(data: GalaxyData) -> Image:
	var window := GalaxyWindow.create(data.graphics, Keen4Episode.MENU_FONT)
	window.open_centred(BOX_CELLS)
	var texts := data.executable.texts(Keen4Episode.CHEAT_TEXTS)
	window.print_centred(texts[CHEAT_TEXT] if not texts.is_empty() else "")
	return window.image()


## Whether [param key] is held on the keyboard now.
static func is_key_held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)
