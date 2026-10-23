class_name Keen5MapKeen
extends GalaxyMapKeen
## Keen on Keen 5's world map (milestone E6): the [GalaxyMapKeen] walk, and
## the Omegamatic's teleporters and elevators (Omni `ck5_map.c`:
## CK5_MapMiscFlagsCheck, CK5_MapKeenElevator; facts and numbers only;
## docs/keen5/research.md §8):
##   - after the contacts, the tile under the middle of his box asks for a
##     ride: a teleporter (misc 20), the left (33) or the right (34) half
##     of an elevator ([member ride], taken by [Keen5MapSession], which
##     runs it with [Keen5MapRide]);
##   - in the elevator he flies, unseen and not clipped, 64 units a tic up
##     or down and 12 a tic sideways until he is above or below the target
##     column, to the target ([method fly_to]); when he passes its row he
##     stands there facing south ([member arrived]) and the ride goes on.

## What the tile under him asks for.
enum Ride { NONE, TELEPORTER, LEFT_ELEVATOR, RIGHT_ELEVATOR }

## The misc kinds of the tiles (Omni MISCFLAG_TELEPORT, LEFTELEVATOR,
## RIGHTELEVATOR).
const TELEPORTER_TILE := 20
const LEFT_ELEVATOR_TILE := 33
const RIGHT_ELEVATOR_TILE := 34
## (Omni CK5_ACT_MapKeenElevator: think every frame, no picture.)
const ELEVATOR_ROWS: PackedStringArray = ["elevator x x think p 6 16 16 elevator - - -"]
## The flight's speeds, units a tic (Omni).
const FLY_VERTICAL := 64
const FLY_SIDEWAYS := 12
## While he flies his box is one tile from his place (Omni).
const FLIGHT_BOX := 0xFF
const SOUTH := 4

## The ride the tile under him asks for, until the session takes it.
var ride := Ride.NONE
## The tile of that ride (teleporter or elevator half).
var ride_cell := Vector2i.ZERO
## Where the elevator takes him (units; Omni user2, user1).
var flight_target := Vector2i.ZERO
## Set when the flight has reached its target; the session takes it.
var arrived := false
## His box in the last frame of the flight, one step beyond the target:
## the view follows it once more when he arrives (Omni CK_MapCamera in
## CK5_MapKeenElevator).
var flight_box: Box


func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	super(episode_sprites)
	actions.merge(GalaxyAction.table_from(ELEVATOR_ROWS, episode_sprites))


## Whether he flies in the elevator.
func is_flying() -> bool:
	return action == actions[&"elevator"]


## Starts the flight to [param target] (units) from where he is, unseen
## and not clipped (Omni CK5_AnimateMapElevator's end).
func fly_to(target: Vector2i) -> void:
	flight_target = target
	direction = Vector2i(-1 if target.x < position.x else 1, -1 if target.y < position.y else 1)
	clip = Clip.NONE
	sprite = NO_SPRITE
	_continue_as(&"elevator")


## The sprite of direction [param way] (0-7), step [param frame] of the
## three pictures the original cycles through in its rides: walking 1,
## walking 2, standing (Omni SPR_MAPKEEN_WALK1_x + 0-2).
func ride_picture(way: int, frame: int) -> int:
	return picture(way, ["WALK_1", "WALK_2", STAND][frame % 3])


## Think every frame of the flight (Omni CK5_MapKeenElevator): up or down
## at full speed, sideways until the target column; past the target's
## row he stands there.
func _think_elevator() -> void:
	step.y = direction.y * FLY_VERTICAL * world.tics
	if position.x != flight_target.x:
		step.x = direction.x * FLY_SIDEWAYS * world.tics
		var beyond := position.x + step.x
		if (
			(direction.x > 0 and beyond > flight_target.x)
			or (direction.x < 0 and beyond < flight_target.x)
		):
			step.x = flight_target.x - position.x
	box.left = position.x + step.x
	box.right = box.left + FLIGHT_BOX
	box.top = position.y + step.y
	box.bottom = box.top + FLIGHT_BOX
	var next_y := position.y + step.y
	var short := next_y < flight_target.y if direction.y > 0 else next_y > flight_target.y
	if not short:
		flight_box = box.copy()
		_land()


## Arrived: he stands at the target facing south (Omni, the end of
## CK5_MapKeenElevator before the doors open). He is clipped again only
## once the door is open and he has walked out ([Keen5MapRide]): the
## original clips him after its loop, when the closed door's tiles above
## the target are gone.
func _land() -> void:
	step = Vector2i.ZERO
	position = flight_target
	facing = SOUTH
	walk_step = 3
	forced_tics = 0
	direction = Vector2i.ZERO
	_continue_as(&"stand")
	sprite = picture(SOUTH, STAND)
	arrived = true


## After the contacts: a teleporter or an elevator under the middle of his
## box (Omni CK5_MapMiscFlagsCheck); not while he goes on by himself, flies
## or a ride waits.
func _touch_tiles() -> void:
	if forced_tics > 0 or is_flying() or ride != Ride.NONE or arrived:
		return
	var middle := Vector2i(
		box.tile_middle, GalaxyUnits.to_tile(box.top + (box.bottom - box.top) / 2)
	)
	match world.misc_of(world.fore_tile(middle.x, middle.y)):
		TELEPORTER_TILE:
			ride = Ride.TELEPORTER
		LEFT_ELEVATOR_TILE:
			ride = Ride.LEFT_ELEVATOR
		RIGHT_ELEVATOR_TILE:
			ride = Ride.RIGHT_ELEVATOR
		_:
			return
	ride_cell = middle
