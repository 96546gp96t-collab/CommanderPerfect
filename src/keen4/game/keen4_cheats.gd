class_name Keen4Cheats
extends GalaxyCheats
## The original's two cheats, checked while Keen plays (Omni `ck_play.c`:
## CK_PlayLoop, CK_CheckKeys, CK_ItemCheat; facts only), the shared
## [GalaxyCheats] by Keen 4's rules (since milestone E13):
##   - E, N and D held: the end. The level counts as a rescue of the eighth
##     council member (the rescue's boxes for this map), then the end;
##   - B, A and T held: a box "Cheat Option! ..." until a key, then all four
##     gems, 99 charges and a life more.
## A cheat counts once while its keys stay held.
## Ours, as in Keen 1-3 (D13.2): Shift+I gives everything without a box
## ([method give_everything]); Shift+G is god mode ([Keen4View]).


## Shift+I (ours, Keen 1-3's testing cheat): all four gems and at least
## 99 charges, no life more.
static func give_everything(inventory: GalaxyInventory) -> void:
	inventory.shots = maxi(inventory.shots, ITEM_SHOTS)
	inventory.gems = PackedInt32Array([1, 1, 1, 1])


## B+A+T's box by Keen 4's rules (or [param game_rules]), with the text of
## the player's program.
static func items_box(data: GalaxyData, game_rules: GalaxyGameRules = null) -> Image:
	return GalaxyCheats.items_box(
		data, game_rules if game_rules != null else Keen4Episode.game_rules()
	)
