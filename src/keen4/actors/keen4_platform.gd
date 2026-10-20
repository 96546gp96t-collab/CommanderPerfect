class_name Keen4Platform
extends GalaxyPlatform
## A moving platform of Keen 4 (info 27-30: up, right, down, left): the
## Galaxy platform ([GalaxyPlatform]: 12 units a tic, turning at turn
## points) with Keen 4's thruster flames (Omni `ck4_obj2.c`,
## CK4_PlatformDraw, facts and numbers only):
##   - going right a side jet behind it, at its left (−16, 48 units);
##   - going left a side jet at its right (768, 80 units), in front of the
##     platform's own priority;
##   - going up two jets under it (32, 144 and 736, 128 units); going down
##     the same two, but only every other 4 tics (they flicker);
##   - the jets switch between their two sprites every 4 tics.

## (Omni CK_ACT_AxisPlatform.)
const ROWS: PackedStringArray = [
	"move PLATFORM PLATFORM think -- 0 0 0 axis - flames -",
]
## The jets' first sprites (the second follows) and where they are drawn,
## from the platform's position, in units (Omni).
const SIDE_JET := &"SIDE_JET_1"
const LEFT_BOTTOM_JET := &"LEFT_BOTTOM_JET_1"
const RIGHT_BOTTOM_JET := &"RIGHT_BOTTOM_JET_1"
const RIGHT_GOING_JET := Vector2i(-0x10, 0x30)
const LEFT_GOING_JET := Vector2i(0x300, 0x50)
const LEFT_JET := Vector2i(0x20, 0x90)
const RIGHT_JET := Vector2i(0x2E0, 0x80)
const JET_PRIORITY := 0
const LEFT_GOING_PRIORITY := 1
## The jets change their sprite every this many tics.
const FLICKER_TICS := 4


## A platform at [param cell] moving towards [param heading] (0 up,
## 1 right, 2 down, 3 left).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, heading: int, sprites: Dictionary[StringName, int]
) -> Keen4Platform:
	var platform := Keen4Platform.new()
	platform.place_moving(world, cell, heading, ROWS, sprites, &"move")
	return platform


## React: the jets for the way it goes now (Omni CK4_PlatformDraw).
func _react_flames() -> void:
	var flicker := (world.tic / FLICKER_TICS) & 1
	overlays.clear()
	if direction.x == 1:
		_jet(SIDE_JET, flicker, RIGHT_GOING_JET, JET_PRIORITY)
	elif direction.x == -1:
		_jet(SIDE_JET, flicker, LEFT_GOING_JET, LEFT_GOING_PRIORITY)
	elif direction.y == -1 or flicker == 1:
		_jet(LEFT_BOTTOM_JET, flicker, LEFT_JET, JET_PRIORITY)
		_jet(RIGHT_BOTTOM_JET, flicker, RIGHT_JET, JET_PRIORITY)


func _jet(first: StringName, flicker: int, offset: Vector2i, jet_priority: int) -> void:
	var jet := Overlay.new()
	jet.sprite = sprites.get(first, NO_SPRITE) + flicker
	jet.offset = offset
	jet.priority = jet_priority
	overlays.append(jet)
