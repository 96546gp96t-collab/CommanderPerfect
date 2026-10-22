class_name Keen5Keen
extends GalaxyKeen
## Keen in a Keen 5 level: the Galaxy Keen ([GalaxyKeen]) with what Keen 5
## adds (Omni `ck_keen.c`, the Keen 5 branches; docs/keen5/research.md §1,
## §4, §5; docs/keen5/gameplay.md):
##   - the keycard (item 12) with its own sound and shadow;
##   - the security door (misc 32): up at it without the keycard plays the
##     "need keycard" sound and nothing happens; with it the card is used,
##     the door opens in three steps ([Keen5SecurityDoor], at Keen's middle
##     column − 2 and bottom row − 4) while he steps in for 45 tics, then he
##     goes through as through a normal door;
##   - the doors' special targets: 0xB1B1 ends the level (the exit door),
##     0x0000 is the way to Korath III (the level ends with the ending
##     [constant KORATH_ENDING]); he is gone from sight for 9 tics first;
##   - the Vitalin splash has four pictures of 8 tics (Keen 4's lifewater
##     three of 10);
##   - no moon (misc 16 is on two tiles but means nothing in Keen 5);
##   - the creatures that push him (the Little Ampton, the Korath, the
##     Shelley) push him only sideways ([method push_sideways]), and those
##     that knock him off a pole or ledge do not push him as well
##     ([method knock_off_pole]; E4).

## Misc kind of the security door (Omni MISCFLAG_SECURITYDOOR).
const SECURITY_DOOR := 32
## Door targets with a meaning of their own (Omni CK_KeenEnterDoor).
const EXIT_TARGET := 0xB1B1
const KORATH_TARGET := 0x0000
## How a level left by the door to Korath III ends ([method
## GalaxyLevelSession.ending]; Omni LS_TeleportToKorath).
const KORATH_ENDING := &"korath"
## Where the door opener starts, from Keen's middle column and bottom row
## (Omni).
const DOOR_FROM_KEEN := Vector2i(-2, -4)
## Keen 5's own actions (Omni CK_ACT_keenEnterSecurityDoor,
## CK_ACT_keenEnteredDoor), with Keen's.
const ROWS: PackedStringArray = [
	"enter_security_door ENTER_1 ENTER_1 step -- 45 0 -64 - - - enter_door_1",
	"entered_door x x step -- 9 0 -64 enter_door - - stand",
]
## Keen 4's actions Keen 5 has no sprites for.
const LEFT_OUT_PREFIX := "moon_"
## The items' actions (Omni CK_ACT_item, CK_ACT_itemNotify,
## CK_ACT_CentilifeNotify1-4).
const ITEM_ROWS: PackedStringArray = [
	"lying_1 - - step -- 20 0 0 lying - - lying_2",
	"lying_2 - - step -- 20 0 0 lying - - lying_1",
	"rising - - slide -- 40 0 8 - - - -",
	"splash_1 SPLASH_1 SPLASH_1 step -- 8 0 0 - - - splash_2",
	"splash_2 SPLASH_2 SPLASH_2 step -- 8 0 0 - - - splash_3",
	"splash_3 SPLASH_3 SPLASH_3 step -- 8 0 0 - - - splash_4",
	"splash_4 SPLASH_4 SPLASH_4 step -- 8 0 0 - - - -",
]
## The sound of each item (Omni EPISODE.CK5 ck_itemSounds): Keen 4's
## twelve and the keycard's.
const ITEM_SOUNDS_KEEN_5: Array[StringName] = [
	&"got_gem",
	&"got_gem",
	&"got_gem",
	&"got_gem",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_extra_life",
	&"got_stunner",
	&"got_keycard",
]


## Keen's actions and Keen 5's, the items' with the four splash pictures,
## the keycard's sound.
func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	super(episode_sprites)
	item_sounds = ITEM_SOUNDS_KEEN_5


## Keen's rows ([GalaxyKeenActions]) without the moon, and Keen 5's.
func _action_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	for row in GalaxyKeenActions.ROWS:
		if not row.begins_with(LEFT_OUT_PREFIX):
			rows.append(row)
	rows.append_array(ROWS)
	return rows


func _item_rows() -> PackedStringArray:
	return ITEM_ROWS


## [param pusher] pushes him out of its way sideways, when it moved into
## him (Omni CK_PhysPushX): he is moved with the normal clipping and stands
## against it.
func push_sideways(pusher: GalaxyObject) -> void:
	var dx := pusher.moved.x - moved.x
	var from_left := pusher.box.right - box.left
	var from_right := box.right - pusher.box.left
	if from_left > 0 and from_left <= dx:
		_shove(from_left)
		right_hit = 1
	elif from_right > 0 and -dx >= from_right:
		_shove(-from_right)
		left_hit = 1


## [param pusher] knocks him off a pole or ledge: he falls where he is, in
## front of nothing (Omni CK_KeenSpecialColFunc, Keen 5: no push; the
## pole-door glitch of the original is kept, his vertical facing stays).
func knock_off_pole(_pusher: GalaxyObject) -> void:
	priority = 1
	clip = Clip.NORMAL
	_become(&"fall_1")
	jump_timer = 0
	velocity = Vector2i.ZERO


func _shove(distance: int) -> void:
	step = Vector2i(distance, 0)
	world.clip.update_normal(self)


## The keycard he holds.
func has_keycard() -> bool:
	var carried := inventory as Keen5Inventory
	return carried != null and carried.keycard


func _is_door(kind: int) -> bool:
	return kind == SECURITY_DOOR or super(kind)


## At a security door the keycard decides (Omni CK_KeenPressUp); other
## doors as in every episode.
func _enter_door(kind: int) -> bool:
	if kind != SECURITY_DOOR:
		return super(kind)
	if not has_keycard():
		world.play_sound(&"need_keycard")
		_continue_as(&"stand")
		return false
	(inventory as Keen5Inventory).keycard = false
	world.play_sound(&"open_security_door")
	var door := Vector2i(box.tile_middle, box.tile_bottom) + DOOR_FROM_KEEN
	Keen5SecurityDoor.open_at(world, door)
	_continue_as(&"enter_security_door")
	priority = 0
	return true


## At the end of a door: the exit door and the door to Korath III end the
## level, he is gone from sight; any other target as in every episode
## (Omni CK_KeenEnterDoor).
func _think_enter_door() -> void:
	var target := world.info_at(box.tile_left, box.tile_bottom)
	if target == EXIT_TARGET:
		world.complete(&"")
	elif target == KORATH_TARGET:
		world.complete(KORATH_ENDING)
	else:
		super()
		return
	_continue_as(&"entered_door")
