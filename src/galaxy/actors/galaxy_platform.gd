class_name GalaxyPlatform
extends GalaxyCreature
## A platform of a Galaxy level that moves along one axis (Omni `ck_obj.c`,
## CK_SpawnAxisPlatform and CK_AxisPlatform, facts and numbers only;
## docs/keen4/research.md §7, §9):
##   - it moves 12 units a tic up, right, down or left (seen in the
##     original, D6: 52 pixels a second);
##   - when its leading edge is about to enter a tile whose info value is a
##     **turn point** (0x1F, the "B-block"), it stops on that tile's edge
##     and turns round;
##   - moving up or down, a second turn point two tiles back from the one
##     ahead (two tiles below it going up, above it going down) stops it
##     instead: a switch that adds that turn point holds it;
##   - Keen landing on it rides it ([GalaxyKeenBody.land_on]); one that
##     touches him on a pole or a ledge makes him fall onto it.
## A switch turns a turn point on or off (info XOR 0x1F, [GalaxyKeen]), so
## the platform's way changes at once. The episode gives the action rows
## and draws what goes with it (Keen 4: the thruster flames,
## [Keen4Platform]); the mines of Keen 4 move by the same rule.

## The info value of a turn point (Omni).
const TURN_POINT := 0x1F
## Units a tic (Omni; seen in the original, D6).
const SPEED := 12
## The four directions of the info values, in their order: up, right,
## down, left (Omni).
const HEADINGS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## A vertical platform stops when there is a turn point this many tiles
## back from the one ahead (Omni).
const STOP_DISTANCE := 2
const TILE := GalaxyUnits.PER_TILE
const TILE_MASK := 0xFF


## A platform at [param cell] moving towards [param heading] (0 up,
## 1 right, 2 down, 3 left) with the actions of [param rows], starting
## with [param first]: at the tile's corner, always awake, behind
## everything (Omni).
func place_moving(
	world: GalaxyWorld,
	cell: Vector2i,
	heading: int,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName
) -> void:
	activity = Activity.ALWAYS
	priority = 0
	direction = HEADINGS[heading]
	var at := Vector2i(GalaxyUnits.from_tile(cell.x), GalaxyUnits.from_tile(cell.y))
	enter(world, at, rows, episode_sprites, first)


## Keen touches it: standing, walking or jumping he lands on it when he
## comes from above; on a pole or a ledge he falls onto it (Omni
## CK_KeenColFunc, CK_KeenSpecialColFunc).
func touched_by_player(player: GalaxyObject, holding: bool) -> void:
	var keen := player as GalaxyKeenBody
	if keen == null:
		return
	if holding:
		keen.fall_onto(self)
	elif keen.platform == null:
		keen.land_on(self)


## Think: one move along its axis, turning (or stopping) at turn points
## (Omni CK_AxisPlatform).
func _think_axis() -> void:
	if step != Vector2i.ZERO:
		return
	step = direction * SPEED * world.tics
	if direction.x == 1:
		var edge := box.right + step.x
		if _turn_point_entered(GalaxyUnits.to_tile(edge), box.tile_right, true):
			direction.x = -1
			step.x -= edge & TILE_MASK
	elif direction.x == -1:
		var edge := box.left + step.x
		if _turn_point_entered(GalaxyUnits.to_tile(edge), box.tile_left, true):
			direction.x = 1
			step.x += (TILE - edge) & TILE_MASK
	elif direction.y == 1:
		var edge := box.bottom + step.y
		var row := GalaxyUnits.to_tile(edge)
		if _turn_point_entered(row, box.tile_bottom, false):
			if _is_turn_point(box.tile_left, row - STOP_DISTANCE):
				_hold()
			else:
				direction.y = -1
				step.y -= edge & TILE_MASK
	elif direction.y == -1:
		var edge := box.top + step.y
		var row := GalaxyUnits.to_tile(edge)
		if _turn_point_entered(row, box.tile_top, false):
			if _is_turn_point(box.tile_left, row + STOP_DISTANCE):
				_hold()
			else:
				direction.y = 1
				step.y += TILE - (edge & TILE_MASK)


## Whether the leading edge goes from tile [param now] into tile
## [param entered] (a column, or a row when not [param columns]) and that
## tile is a turn point on the box's first row (column).
func _turn_point_entered(entered: int, now: int, columns: bool) -> bool:
	if entered == now:
		return false
	if columns:
		return _is_turn_point(entered, box.tile_top)
	return _is_turn_point(box.tile_left, entered)


func _is_turn_point(x: int, y: int) -> bool:
	return world.info_at(x, y) == TURN_POINT


## Stops where it is this frame; it is drawn again (Omni).
func _hold() -> void:
	step.y = 0
	needs_react = true
