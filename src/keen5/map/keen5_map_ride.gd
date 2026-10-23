class_name Keen5MapRide
extends RefCounted
## The parts of a teleporter or elevator ride on Keen 5's world map during
## which the original stops the game and runs a loop of its own (Omni
## `ck_map.c:CK_AnimateMapTeleporter`, `ck5_map.c:CK5_AnimateMapElevator`,
## `CK5_MapKeenElevator`; facts and numbers only; docs/keen5/research.md
## §8). Each frame the [Keen5MapSession] runs [method advance] instead of
## the world, so nothing else moves:
##   - **teleporter**: sound 41; Keen walks onto the tile, 2 units a tic on
##     each axis, for at most 130 tics, showing his walking north pictures
##     (by the clock, a picture every 8 tics), while the tile flashes
##     (0xA7F and 0xA80 every 4 tics); the tile becomes the teleporter
##     again (0x427) and he stands at the target the tile's info word names
##     (x the high byte, y the low byte & 0x7F), facing south; the view is
##     put on him, objects in it wake up, sound 41; he walks out south, 3
##     units a tic for 90 tics, while the target tile flashes; then it is
##     cleared (tile 0);
##   - **elevator, going in** (misc 33 the left half, 34 the right): Keen
##     walks onto the tile as onto a teleporter, the view following him;
##     sound 63; the door (2 × 2 tiles, one up and, from the right half,
##     one left) closes in six pictures of 8 tics taken from the map's
##     top-left corner (picture n at (2n, 0)-(2n + 1, 1); 5 open, 0
##     closed); then he flies ([method Keen5MapKeen.fly_to]) to the column
##     of the info word's high byte, the row below its low byte & 0x7F;
##   - **elevator, coming out**: the view follows Keen's last box of the
##     flight (a step beyond the target) once more; the door above the
##     target (two rows up) opens in the same pictures, 0 to 5, after sound
##     63, with Keen a tile up in it, facing south; he walks out south, 8
##     units a frame for 32 frames, back to the target.

enum Phase { WALK_IN, TELEPORT_OUT, DOOR_CLOSING, DOOR_OPENING, WALK_OUT, DONE }

## Walking onto the tile: 2 units a tic on each axis, at most 130 tics
## (Omni).
const WALK_IN_SPEED := 2
const WALK_IN_TICS := 130
## Walking out of a teleporter: 3 units a tic south for 90 tics (Omni).
const TELEPORT_OUT_SPEED := 3
const TELEPORT_OUT_TICS := 90
## The tiles (Omni, Keen 5): the flashing bolt (two tiles, every 4 tics),
## the teleporter put back, the target cleared.
const BOLT_TILE := 0xA7F
const BOLT_SHIFT := 2
const TELEPORTER_TILE := 0x427
const CLEARED_TILE := 0
## The pictures of the rides change every 8 tics of the clock (Omni
## SD_GetTimeCount() >> 3), or every 4 frames walking out of an elevator.
const PICTURE_SHIFT := 3
const WALK_OUT_FRAMES := 32
const WALK_OUT_STEP := 8
const WALK_OUT_FRAMES_PER_PICTURE := 4
## The door: six pictures of 2 × 2 tiles in the map's top-left corner,
## each 8 tics.
const DOOR_PICTURES := 6
const DOOR_OPEN := 5
const DOOR_SIZE := Vector2i(2, 2)
const DOOR_TICS := 8
## The target's row is one below the info word's (Omni).
const TARGET_ROW_MASK := 0x7F
const TILE := 256
const NORTH := 0
const SOUTH := 4

var phase := Phase.DONE
var keen: Keen5MapKeen
var world: GalaxyWorld
var camera: GalaxyCamera
## The ride's tile (the teleporter, the elevator half), then the target's.
var cell := Vector2i.ZERO
## The door's top-left tile.
var door := Vector2i.ZERO
## The door's picture shown now.
var door_picture := 0
var _teleporter := false
var _tics := 0
var _frames := 0


## Keen walks into the teleporter or elevator half at [param tile_cell]
## (his [member Keen5MapKeen.ride]); [param view] is the map's camera.
static func going_in(walker: Keen5MapKeen, view: GalaxyCamera, tile_cell: Vector2i) -> Keen5MapRide:
	var ride := Keen5MapRide._made(walker, view)
	ride.cell = tile_cell
	ride._teleporter = walker.ride == Keen5MapKeen.Ride.TELEPORTER
	ride.phase = Phase.WALK_IN
	if ride._teleporter:
		ride.world.play_sound(&"teleport")
	return ride


## Keen has flown to [member Keen5MapKeen.flight_target]: the door above
## it opens and he walks out (Omni CK5_MapKeenElevator).
static func coming_out(walker: Keen5MapKeen, view: GalaxyCamera) -> Keen5MapRide:
	var ride := Keen5MapRide._made(walker, view)
	var target := Vector2i(
		GalaxyUnits.to_tile(walker.position.x), GalaxyUnits.to_tile(walker.position.y)
	)
	ride.cell = target
	ride.door = target - Vector2i(0, DOOR_SIZE.y)
	var last := walker.flight_box if walker.flight_box != null else walker.box
	view.follow_map(last.left, last.top, last.right, last.bottom)
	walker.position.y -= TILE
	ride.world.play_sound(&"elevator_door")
	ride._start_door(Phase.DOOR_OPENING, 0)
	return ride


static func _made(walker: Keen5MapKeen, view: GalaxyCamera) -> Keen5MapRide:
	var ride := Keen5MapRide.new()
	ride.keen = walker
	ride.world = walker.world
	ride.camera = view
	return ride


func is_done() -> bool:
	return phase == Phase.DONE


## One frame of [param tics] tics, ending on clock tic [param tic].
func advance(tics: int, tic: int) -> void:
	match phase:
		Phase.WALK_IN:
			_walk_in(tics, tic)
		Phase.TELEPORT_OUT:
			_teleport_out(tics, tic)
		Phase.DOOR_CLOSING, Phase.DOOR_OPENING:
			_advance_door(tics)
		Phase.WALK_OUT:
			_walk_out()


## Onto the tile, at most [constant WALK_IN_TICS] (Omni: the move after the
## check whether he is there).
func _walk_in(tics: int, tic: int) -> void:
	_tics += tics
	var target := cell * TILE
	if keen.position != target:
		var speed := WALK_IN_SPEED * tics
		keen.position.x = _towards(keen.position.x, target.x, speed)
		keen.position.y = _towards(keen.position.y, target.y, speed)
		keen.sprite = keen.ride_picture(NORTH, tic >> PICTURE_SHIFT)
		if _teleporter:
			_flash(cell, tic)
		else:
			_follow()
		if _tics < WALK_IN_TICS:
			return
	if _teleporter:
		_jump()
	else:
		world.play_sound(&"elevator_door")
		var side := -1 if keen.ride == Keen5MapKeen.Ride.RIGHT_ELEVATOR else 0
		door = cell + Vector2i(side, -1)
		_start_door(Phase.DOOR_CLOSING, DOOR_OPEN)


## The teleporter is itself again; Keen stands at its target (Omni).
func _jump() -> void:
	world.set_fore_tile(cell, TELEPORTER_TILE)
	cell = _target_cell(world.info_at(cell.x, cell.y), 0)
	keen.position = cell * TILE
	keen.direction = Vector2i(0, 1)
	keen.facing = SOUTH
	keen.start(keen.action)
	camera.centre_on(keen.position.x, 0, true, keen.position.y)
	_wake_objects()
	world.play_sound(&"teleport")
	_tics = 0
	phase = Phase.TELEPORT_OUT


## Out of the teleporter southwards, the target tile flashing; then it is
## cleared and Keen goes on (Omni).
func _teleport_out(tics: int, tic: int) -> void:
	_tics += tics
	keen.position.y += TELEPORT_OUT_SPEED * tics
	keen.sprite = keen.ride_picture(SOUTH, tic >> PICTURE_SHIFT)
	_flash(cell, tic)
	if _tics < TELEPORT_OUT_TICS:
		return
	world.set_fore_tile(cell, CLEARED_TILE)
	_finish()


func _start_door(door_phase: Phase, first_picture: int) -> void:
	phase = door_phase
	door_picture = first_picture
	_tics = 0
	_show_door()


## The door's next picture every [constant DOOR_TICS]; closed, Keen flies;
## open, he walks out.
func _advance_door(tics: int) -> void:
	_tics += tics
	var step := -1 if phase == Phase.DOOR_CLOSING else 1
	while _tics >= DOOR_TICS:
		_tics -= DOOR_TICS
		var next := door_picture + step
		if next < 0 or next >= DOOR_PICTURES:
			_door_done()
			return
		door_picture = next
		_show_door()


func _door_done() -> void:
	if phase == Phase.DOOR_OPENING:
		phase = Phase.WALK_OUT
		_frames = 0
		return
	keen.fly_to(_target_cell(world.info_at(cell.x, cell.y), 1) * TILE)
	phase = Phase.DONE


## Out of the elevator: a step south each frame (Omni: 32 frames of 8).
func _walk_out() -> void:
	keen.position.y += WALK_OUT_STEP
	keen.sprite = keen.ride_picture(SOUTH, _frames / WALK_OUT_FRAMES_PER_PICTURE)
	_frames += 1
	if _frames >= WALK_OUT_FRAMES:
		_finish()


## Keen goes on where he stands, clipped again (Omni
## CK_PhysUpdateNormalObj with no move).
func _finish() -> void:
	keen.clip = GalaxyObject.Clip.NORMAL
	keen.step = Vector2i.ZERO
	world.clip.update_normal(keen)
	phase = Phase.DONE


## The door's picture [member door_picture] from the map's top-left corner.
func _show_door() -> void:
	for y in DOOR_SIZE.y:
		for x in DOOR_SIZE.x:
			var tile := world.fore_tile(door_picture * DOOR_SIZE.x + x, y)
			world.set_fore_tile(door + Vector2i(x, y), tile)


## The bolt at [param at], by the clock's tic [param tic].
func _flash(at: Vector2i, tic: int) -> void:
	world.set_fore_tile(at, BOLT_TILE + ((tic >> BOLT_SHIFT) & 1))


## The view follows Keen's box where he is (Omni CK_ResetClipRects,
## CK_MapCamera).
func _follow() -> void:
	keen.reset_box()
	var box := keen.box
	camera.follow_map(box.left, box.top, box.right, box.bottom)


## Objects asleep in the view wake up (Omni: those within a tile of it).
func _wake_objects() -> void:
	var view := camera.view_tiles()
	for object in world.objects:
		if object.activity != GalaxyObject.Activity.INACTIVE:
			continue
		var box := object.box
		if (
			box.tile_right >= view.position.x - GalaxyWorld.WAKE_MARGIN
			and box.tile_left <= view.end.x + GalaxyWorld.WAKE_MARGIN
			and box.tile_bottom >= view.position.y - GalaxyWorld.WAKE_MARGIN
			and box.tile_top <= view.end.y + GalaxyWorld.WAKE_MARGIN
		):
			object.activity = GalaxyObject.Activity.ACTIVE


## The tile an info [param word] names: the column in its high byte, the
## row in its low byte & 0x7F, plus [param rows_down].
static func _target_cell(word: int, rows_down: int) -> Vector2i:
	return Vector2i(word >> 8, (word & TARGET_ROW_MASK) + rows_down)


## [param from] moved [param speed] towards [param to], not beyond.
static func _towards(from: int, to: int, speed: int) -> int:
	if from < to:
		return mini(from + speed, to)
	return maxi(from - speed, to)
