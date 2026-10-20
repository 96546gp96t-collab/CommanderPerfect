class_name GalaxyItem
extends GalaxyObject
## An item in a Galaxy level and what is left when Keen takes it (Omni
## `ck_obj.c`, `ck_keen.c`; docs/keen4/research.md §5):
##   - an item lying as a sprite (placed by the info plane) shows its two
##     frames 20 tics each, until Keen touches it ([method collect]);
##   - then, and when Keen takes an item lying as a tile, the item's
##     "shadow" (the points, a gem, 1UP, the stunner) rises 8 units a tic
##     for 40 tics in front of everything, and is gone;
##   - a lifewater drop taken shows a splash (three frames of 10 tics), and
##     the 100th drop the 1UP rising as above.
## The items are numbered as [GalaxyInventory] numbers them. Sprites by
## name from the episode: ITEM_n (the first of the two frames of item n),
## SHADOW_n, SPLASH_1..3, EXTRA_LIFE_SPLASH.

## (Omni CK_ACT_item, CK_ACT_itemNotify, CK_ACT_CentilifeNotify*.)
const ROWS: PackedStringArray = [
	"lying_1 - - step -- 20 0 0 lying - - lying_2",
	"lying_2 - - step -- 20 0 0 lying - - lying_1",
	"rising - - slide -- 40 0 8 - - - -",
	"splash_1 SPLASH_1 SPLASH_1 step -- 10 0 0 - - - splash_2",
	"splash_2 SPLASH_2 SPLASH_2 step -- 10 0 0 - - - splash_3",
	"splash_3 SPLASH_3 SPLASH_3 step -- 10 0 0 - - - -",
]
## Items lie behind Keen (priority 2); what rises is in front (3) (Omni).
const LYING_PRIORITY := 2
const RISING_PRIORITY := 3
## The two frames of a lying item follow each other.
const FRAMES := 2

## The item's number (see the class description).
var kind := 0
## Taken by Keen: no contact any more.
var taken := false
var _first_frame := 0
var _actions: Dictionary[StringName, GalaxyAction]


## The actions with the sprites of [param sprites].
static func actions_for(
	sprites: Dictionary[StringName, int]
) -> Dictionary[StringName, GalaxyAction]:
	return GalaxyAction.table_from(ROWS, sprites)


## Item [param item] lying at [param cell] (Omni CK_SpawnItem).
static func place(
	world: GalaxyWorld,
	cell: Vector2i,
	item: int,
	sprites: Dictionary[StringName, int],
	actions: Dictionary[StringName, GalaxyAction]
) -> GalaxyItem:
	var object := GalaxyItem.new()
	object._actions = actions
	object.kind = item
	object.clip = Clip.NONE
	object.priority = LYING_PRIORITY
	object.position = cell * GalaxyUnits.PER_TILE
	object.direction.y = -1
	object._first_frame = sprites.get(StringName("ITEM_%d" % item), NO_SPRITE)
	object.sprite = object._first_frame
	world.add(object)
	object.start(actions[&"lying_1"])
	return object


## The shadow of item [param item] rising from [param cell], where Keen took
## it as a tile.
static func rise_from(
	world: GalaxyWorld,
	cell: Vector2i,
	item: int,
	sprites: Dictionary[StringName, int],
	actions: Dictionary[StringName, GalaxyAction]
) -> GalaxyObject:
	return _riser(world, cell, sprites.get(StringName("SHADOW_%d" % item), NO_SPRITE), actions)


## A drop's splash at [param cell]; with [param extra_life] the 1UP too.
static func splash_at(
	world: GalaxyWorld,
	cell: Vector2i,
	extra_life: bool,
	sprites: Dictionary[StringName, int],
	actions: Dictionary[StringName, GalaxyAction]
) -> void:
	var splash := GalaxyObject.new()
	splash.clip = Clip.NONE
	splash.priority = RISING_PRIORITY
	splash.position = cell * GalaxyUnits.PER_TILE
	world.add(splash)
	splash.start(actions[&"splash_1"])
	if extra_life:
		_riser(world, cell, sprites.get(&"EXTRA_LIFE_SPLASH", NO_SPRITE), actions)


## Keen takes this item: it becomes its shadow, rising (Omni
## CK_KeenColFunc). Returns the item's number.
func collect(sprites: Dictionary[StringName, int]) -> int:
	taken = true
	priority = RISING_PRIORITY
	sprite = sprites.get(StringName("SHADOW_%d" % kind), NO_SPRITE)
	set_action(_actions[&"rising"])
	return kind


## Think: the next of its two frames (Omni CK_PointItem).
func _think_lying() -> void:
	needs_react = true
	sprite += 1
	if sprite == _first_frame + FRAMES:
		sprite = _first_frame


static func _riser(
	world: GalaxyWorld, cell: Vector2i, shown: int, actions: Dictionary[StringName, GalaxyAction]
) -> GalaxyObject:
	var riser := GalaxyObject.new()
	riser.priority = RISING_PRIORITY
	riser.position = cell * GalaxyUnits.PER_TILE
	riser.direction.y = -1
	riser.sprite = shown
	world.add(riser)
	riser.start(actions[&"rising"])
	riser.clip = Clip.NONE
	return riser
