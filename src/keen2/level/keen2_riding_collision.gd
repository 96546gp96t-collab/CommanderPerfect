class_name Keen2RidingCollision
extends LevelCollision
## How Keen moves through a Keen 2 level: the tiles exactly as in Keen 1
## ([LevelCollision]), plus the tops of the carriers ([Keen2Carrier]: the
## moving platforms and the Scrubs) as floors that he can land and stand on.
##
## Only Keen's [KeenBody] gets this collision; the enemies and shots keep the
## session's own [member LevelSession.collision], so a carrier never stands
## on itself. A carrier top works like a one-way floor: Keen jumps up
## through it and lands on it from above. Moving him along with the carrier
## is [Keen2LevelSession]'s job. Keen 1 has no carriers and never makes this
## class, so [KeenBody] and [LevelCollision] stay as they are.

## Returns the carriers that are in the level now, as an
## Array[Keen2Carrier]; set by the session.
var carriers := Callable()


## The collision of [param level_data] with the carriers that
## [param carrier_list] returns.
static func with_carriers(
	level_data: LevelData, tile_properties: TileProperties, carrier_list: Callable
) -> Keen2RidingCollision:
	var collision := Keen2RidingCollision.new()
	collision.level = level_data
	collision.properties = tile_properties
	collision.carriers = carrier_list
	return collision


## The tiles' floor under [param box]; a normal floor when there is no tile
## floor but a carrier.
func floor_under(box: Rect2) -> TileProperties.Floor:
	var tiles := super.floor_under(box)
	if tiles == TileProperties.Floor.NONE and carrier_under(box) != null:
		return TileProperties.Floor.SOLID
	return tiles


## As for the tiles, but moving down, [param box] also stops on a carrier.
func sweep_y(box: Rect2, distance: float) -> float:
	var moved := super.sweep_y(box, distance)
	if distance <= 0.0:
		return moved
	for carrier in _carriers():
		if carrier.can_land_on(box):
			moved = minf(moved, maxf(0.0, carrier.top() - box.end.y))
	return moved


## The carrier that [param box] stands on, or null.
func carrier_under(box: Rect2) -> Keen2Carrier:
	for carrier in _carriers():
		if carrier.carries(box):
			return carrier
	return null


func _carriers() -> Array[Keen2Carrier]:
	var found: Array[Keen2Carrier] = []
	if carriers.is_valid():
		found.assign(carriers.call())
	return found
