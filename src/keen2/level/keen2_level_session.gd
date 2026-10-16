class_name Keen2LevelSession
extends LevelSession
## One attempt at a Keen 2 level. The generic rules are [LevelSession]'s,
## unchanged: points for items with behaviours 6-10 (500, 100, 200, 1000,
## 5000), the raygun (15, five charges), the keycards (18-21) and the doors
## they open (2-5; the door becomes tile 143), the exit (17), deadly tiles
## (1), an extra life every 20,000 points, and the background that a picked
## up item leaves (tile 276 for items from tile 305 on, otherwise 143).
##
## What Keen 2 does differently (docs/keen2/gameplay.md):
##   enemies    none yet; they come in milestone B4. The info layer spawns
##              nothing. Values from 0x100 on are never enemies anyway: at a
##              switch they point to the bridge it moves.
##   items      Keen 1's ship parts (behaviours 11-14) are no items: Keen 2
##              has none.
##   specials   behaviour 22 is the Vorticon Elder's message, not a statue;
##              23, 25 and 26 are switches; 24 is no teleporter. Touching
##              them does nothing yet (milestones B5 and B6).
##   shots      Keen's shots use Keen 2's sprites ([Keen2Shot]).
##   pogo       Keen has the pogo stick from the start.


## Starts an attempt at [param level_data] with Keen's sprite at
## [param start], carrying [param keen_inventory] (normally a
## [Keen2Inventory]).
static func begin(
	level_data: LevelData,
	tile_properties: TileProperties,
	keen_inventory: Inventory,
	start: Vector2,
) -> Keen2LevelSession:
	# Keen 2 has no pogo stick to find: Keen always has it.
	keen_inventory.has_pogo = true
	var session := Keen2LevelSession.new()
	session._set_up(level_data, tile_properties, keen_inventory, start)
	return session


## No enemies until milestone B4.
func _spawn_enemies(_has_commander: bool) -> void:
	pass


func _is_item(tile: int) -> bool:
	return properties.is_item(tile) and not is_ship_part(properties.behavior(tile))


## The Elder's message, the switches and Keen 1's teleporter and statues do
## nothing in Keen 2 yet.
func _touch_special_tile(_cell: Vector2i, _tile: int) -> void:
	pass


func _create_shot(start: Vector2, direction: int) -> RaygunShot:
	return Keen2Shot.fired(start, direction)


## Whether [param behavior] is one of Keen 1's ship parts.
static func is_ship_part(behavior: int) -> bool:
	return (
		behavior >= TileProperties.Behavior.SHIP_JOYSTICK
		and behavior <= TileProperties.Behavior.SHIP_WHISKEY
	)
