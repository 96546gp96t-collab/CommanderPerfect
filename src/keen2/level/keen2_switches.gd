class_name Keen2Switches
extends RefCounted
## Keen 2's switches (docs/keen2/gameplay.md, "Switches"). Keen uses one with
## the pogo button: when a switch is in the column through his middle, from
## his feet up in steps of [constant SEARCH_STEP] pixels, the button presses
## it instead of taking out the pogo stick ([Keen2Body]). What a press does
## depends on the switch's info value and behaviour:
##   info not 0         lays out a bridge, or takes it in ([Keen2Bridge]); the
##                      value says where the bridge starts
##   0, behaviour 23    the lights go off or on
##   0, behaviour 25/26 the Tantalus Ray fires: the Earth explodes
## A lever (tiles 480 and 493) flips with every press, and every press
## clicks.

## Keen 2's tile behaviours of switches and the Vorticon Elder.
const BEHAVIOR_ELDER := 22
const BEHAVIOR_LIGHT_SWITCH := 23
const BEHAVIOR_SWITCH_UP := 25
const BEHAVIOR_SWITCH_DOWN := 26
const SWITCH_BEHAVIORS: PackedInt32Array = [
	BEHAVIOR_LIGHT_SWITCH, BEHAVIOR_SWITCH_UP, BEHAVIOR_SWITCH_DOWN
]
## The lever, up and down; a press turns one into the other.
const LEVER_UP := 480  # from Commander Genius, check with the real files
const LEVER_DOWN := 493  # from Commander Genius, check with the real files
## Pixels between the points that are checked for a switch.
const SEARCH_STEP := 8.0
## The two bytes of a bridge's info value: the low one is the column
## offset, the high one the row offset, both signed, in tiles.
const BYTE_MASK := 0xFF
const BYTE_BITS := 8
const SIGNED_BYTE_LIMIT := 0x80
const BYTE_RANGE := 0x100
const NO_CELL := Vector2i(-1, -1)

var session: Keen2LevelSession
## The bridges that have been used, by their first cell.
var bridges: Dictionary[Vector2i, Keen2Bridge] = {}


static func create(level_session: Keen2LevelSession) -> Keen2Switches:
	var switches := Keen2Switches.new()
	switches.session = level_session
	return switches


## Whether [param tile] is a switch.
static func is_switch(properties: TileProperties, tile: int) -> bool:
	return tile >= 0 and properties.behavior(tile) in SWITCH_BEHAVIORS


## Where the bridge of a switch with [param info] starts, counted from the
## switch.
static func bridge_offset(info: int) -> Vector2i:
	return Vector2i(_signed_byte(info & BYTE_MASK), _signed_byte((info >> BYTE_BITS) & BYTE_MASK))


## Presses the switch near [param body], if there is one. Returns whether
## there was (then the pogo button did nothing else).
func use_near(body: KeenBody) -> bool:
	var cell := find_switch(body.hitbox())
	if cell == NO_CELL:
		return false
	press(cell)
	return true


## The switch in the column through the middle of [param box], the lowest
## first, or [constant NO_CELL].
func find_switch(box: Rect2) -> Vector2i:
	var tile_size := float(EgaGraphics.TILE_SIZE)
	var column := floori(box.get_center().x / tile_size)
	# The last pixel row inside the box: the floor below Keen does not count.
	var y := box.end.y - KeenPhysics.SUBPIXEL
	while y >= box.position.y:
		var cell := Vector2i(column, floori(y / tile_size))
		if is_switch(session.properties, session.collision.tile_at(cell)):
			return cell
		y -= SEARCH_STEP
	return NO_CELL


## Presses the switch in [param cell].
func press(cell: Vector2i) -> void:
	var tile := session.level.tile_at(cell)
	var info := session.level.info_at(cell)
	session.play_sound(Sound.Id.CLICK)
	if tile == LEVER_UP or tile == LEVER_DOWN:
		session.set_tile(cell, LEVER_DOWN if tile == LEVER_UP else LEVER_UP)
	if info != 0:
		_use_bridge(cell + bridge_offset(info))
	elif session.properties.behavior(tile) == BEHAVIOR_LIGHT_SWITCH:
		session.set_dark(not session.is_dark())
	else:
		session.fire_tantalus_ray()


## Moves the bridges on by one tick.
func step() -> void:
	for bridge in bridges.values():
		bridge.step(session)


func _use_bridge(start: Vector2i) -> void:
	var bridge: Keen2Bridge = bridges.get(start)
	if bridge == null:
		bridges[start] = Keen2Bridge.at(session, start)
	else:
		bridge.reverse()


static func _signed_byte(value: int) -> int:
	return value - BYTE_RANGE if value >= SIGNED_BYTE_LIMIT else value
