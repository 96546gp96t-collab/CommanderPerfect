class_name GalaxyKeen
extends GalaxyKeenAir
## Keen in a Galaxy level, on the ground and on poles; the air is
## [GalaxyKeenAir]'s, dying, shooting and touching [GalaxyKeenBody]'s. The
## facts and numbers are Omnispeak's (`ck_keen.c`, marked (Omni);
## docs/keen4/research.md §5); the actions are [GalaxyKeenActions].
##
## - Standing: after 200 tics without input he looks up, after 300 more he
##   is bored (or, in Keen 4 on the moon spot, shows the moon), after 700
##   more he sits down and reads.
## - Walking: 24 units a tic, frames of 6 tics; on a slope the slope adds
##   to his move (down to the right +4 / +8, up to the right −4 / −8).
## - Up: a switch or door in front of him (he first walks to its spot), a
##   pole, or he looks up; down: a pole, or he looks down, and with jump
##   drops through a thin floor.
## - Poles: up or down grabs one; climbing 8 units a tic, sliding 24; jump
##   leaps off (−20 for 10 tics); a pole cannot be grabbed for 19 tics after.
## - A door (misc 2) takes him to the info plane's target under it: x in the
##   high byte, y in the low byte.

## (Omni.) He starts this far above the info tile's corner, so that his
## feet rest on the tile below.
const START_RISE := 241
## A gem holder with its gem is this many tiles further on.
const GEM_HOLDER_STEP := 18
const WALK_JUMP_SPEED_X := 16
const POGO_SPEED_X := 16
## Added to his move per tic on a floor side 0-7 (Omni ck_KeenRunXVels).
const SLOPE_PUSH: PackedInt32Array = [0, 0, 4, 4, 8, -4, -4, -8]
const SLOPE_MASK := 7
## Running starts at a quarter of the run's speed in its first frame.
const RUN_START_DIVISOR := 4
const IDLE_LOOK_TICS := 200
const IDLE_BORED_TICS := 300
const IDLE_READ_TICS := 700
const PLATFORM_TOP_MASK := ~7
const PLATFORM_TOP := 0x18
## Dropping through a thin floor: at least this many pixels down at once.
const DROP_MIN_TICS := 4
## Walking to a door, switch or gem holder: a pixel a tic.
const SLIDE_SPEED := 16
## Where he stands for a switch (from its tile) and a door (Omni).
const SWITCH_SPOT := -64
const DOOR_SPOT := 96
const TILE := GalaxyUnits.PER_TILE
## A door's target: x in the high byte, y in the low one; he arrives one
## tile above it (+ 15 units) (Omni).
const BYTE_SHIFT := 8
const BYTE_MASK := 0xFF
const DOOR_ARRIVAL := -TILE + 15
## Switches turn a platform's turn point on or off by this (Omni).
const TURN_POINT_TOGGLE := 0x1F
## A bridge switch moves the bridge's two rows (the second from one tile
## further left) on by their animation offset.
const BRIDGE_ROWS := 2
## Poles (Omni): grabbing looks this far down from his top for one above
## him; on the pole his position is this far into the column left of it.
const POLE_REACH_UP := 96
const POLE_X := 128
const POLE_GRAB_STEP := 32
const POLE_REGRAB_TICS := 19
const POLE_LEAP_SPEED := -20
const POLE_LEAP_TICS := 10
## Sideways speed jumping or falling off a pole, by left / none / right.
const POLE_LEAP_X: PackedInt32Array = [-8, 0, 8]
## Sliding down: the pole must go on this far above his feet.
const POLE_FEET_MARGIN := 64

## The episode shows the moon (Keen 4).
var shows_moon := false
## Set when he went through a door: the view is put on him again.
var went_through_door := false


## Keen of [param world] at the start of a level: info 1 or 2 at
## [param cell], facing [param facing] (Omni CK_SpawnKeen: x = tile, y =
## tile − 241 units).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, facing: int, episode_sprites: Dictionary[StringName, int]
) -> GalaxyKeen:
	var keen := GalaxyKeen.new()
	keen.position = Vector2i(cell.x * TILE, cell.y * TILE - START_RISE)
	keen.direction = Vector2i(facing, 1)
	world.add(keen)
	keen.use_sprites(episode_sprites)
	keen.start(keen.actions[&"stand"])
	return keen


## Think while standing: input, or the idle animations (Omni
## CK_KeenStandingThink).
func _think_standing() -> void:
	if input.direction != 0 or input.vertical != 0 or input.jump or input.pogo or input.fire:
		idle_tics = 0
		idle_stage = 0
		_continue_as(&"stand")
		_handle_ground_input()
		return
	if top_hit & PLATFORM_TOP_MASK != PLATFORM_TOP:
		idle_tics += world.tics
	if idle_stage == 0 and idle_tics > IDLE_LOOK_TICS:
		_next_idle(&"idle")
	elif idle_stage == 1 and idle_tics > IDLE_BORED_TICS:
		if shows_moon and moon == 1:
			moon = 2
			_next_idle(&"moon_1")
		else:
			_next_idle(&"bored_1")
	elif idle_stage == 2 and idle_tics > IDLE_READ_TICS:
		_next_idle(&"open_book_1")


func _next_idle(name: StringName) -> void:
	idle_stage += 1
	idle_tics = 0
	_continue_as(name)


## What the buttons start on the ground (Omni CK_HandleInputOnGround).
func _handle_ground_input() -> void:
	if input.direction != 0:
		_continue_as(&"run_1")
		_think_run()
		step.x = direction.x * action.velocity.x * world.tics / RUN_START_DIVISOR
		return
	if _fire_pressed():
		_use_fire()
		_continue_as(&"shoot_up_1" if input.vertical == -1 else &"shoot_1")
		return
	if _jump_pressed():
		_use_jump()
		_start_jump(0)
		return
	if _pogo_pressed():
		_use_pogo()
		_start_pogo(0)
		step.y = 0
		return
	if input.vertical == -1:
		if _grab_pole() or (not sliding and _press_up()):
			return
		_continue_as(&"look_up_1")
	elif input.vertical == 1:
		if not _grab_pole():
			_continue_as(&"look_down_1")


## Think while walking (Omni CK_KeenRunningThink).
func _think_run() -> void:
	if input.direction == 0:
		_continue_as(&"stand")
		_handle_ground_input()
		return
	direction.x = input.direction
	if input.vertical == -1:
		if _grab_pole() or sliding or _press_up():
			return
	elif input.vertical == 1 and _grab_pole():
		return
	if _fire_pressed():
		_use_fire()
		_continue_as(&"shoot_up_1" if input.vertical == -1 else &"shoot_1")
		return
	if _jump_pressed():
		_use_jump()
		_start_jump(direction.x * WALK_JUMP_SPEED_X)
	if _pogo_pressed():
		_use_pogo()
		_start_pogo(direction.x * POGO_SPEED_X)
		step.x = 0
		return
	step.x += SLOPE_PUSH[top_hit & SLOPE_MASK] * world.tics


func _start_jump(speed_x: int) -> void:
	velocity = Vector2i(speed_x, GalaxyKeenAir.JUMP_SPEED)
	step = Vector2i.ZERO
	jump_timer = GalaxyKeenAir.JUMP_TICS
	_continue_as(&"jump_1")


func _start_pogo(speed_x: int) -> void:
	_continue_as(&"pogo_1")
	velocity = Vector2i(speed_x, GalaxyKeenAir.POGO_SPEED)
	jump_timer = GalaxyKeenAir.POGO_TICS


## React on the ground: no floor makes him fall, a deadly one kills (Omni
## CK_KeenDrawFunc).
func _react_ground() -> void:
	if top_hit == 0:
		_start_falling()
	elif GalaxyTileKinds.is_deadly_floor(top_hit):
		kill()


## React while walking: as standing, and a wall ahead stops him (Omni
## CK_KeenRunDrawFunc).
func _react_run() -> void:
	_react_ground()
	if (right_hit != 0 and direction.x == -1) or (left_hit != 0 and direction.x == 1):
		action_timer = 0
		_continue_as(&"stand")
		sprite = action.sprite_facing(direction.x, sprite)


func _think_look_up() -> void:
	if (
		input.vertical != -1
		or input.direction != 0
		or _jump_pressed()
		or _pogo_pressed()
		or input.fire
	):
		_continue_as(&"stand")
		_handle_ground_input()


## Think while looking down: jump drops him through a thin floor (Omni
## CK_KeenLookDownThink).
func _think_look_down() -> void:
	if _jump_pressed() and top_hit & SLOPE_MASK == FLAT:
		_use_jump()
		var clip_tiles := world.clip
		for row in [box.tile_bottom, box.tile_bottom + 1]:
			var tile := clip_tiles.tile_at(box.tile_middle, row)
			var sides := clip_tiles.left_of(tile) + clip_tiles.bottom_of(tile)
			if sides + clip_tiles.right_of(tile) != 0:
				return
		var drop := maxi(world.tics, DROP_MIN_TICS) * GalaxyUnits.PER_PIXEL
		if platform != null:
			drop += platform.moved.y
		platform = null
		box.bottom += drop
		position.y += drop
		step = Vector2i.ZERO
		_continue_as(&"fall_1")
		velocity = Vector2i.ZERO
		return
	if input.vertical != 1 or input.direction != 0 or _jump_pressed() or _pogo_pressed():
		_continue_as(&"look_down_4")


func _think_reading() -> void:
	if input.direction != 0 or input.jump or input.pogo:
		_continue_as(&"stow_book_1")
		idle_tics = 0
		idle_stage = 0


## Up in front of a switch or a door: he walks to its spot, then presses or
## enters (Omni CK_KeenPressUp). Returns whether there was one.
func _press_up() -> bool:
	var misc := world.tile_info.fore(GalaxyTileInfo.Fore.MISC, _tile_at_head())
	if GalaxyTileKinds.is_switch(misc):
		var spot := box.tile_middle * TILE + SWITCH_SPOT
		if position.x == spot:
			_continue_as(&"press_switch_1")
		else:
			_slide_to(spot)
		sliding = true
		return true
	if misc != GalaxyTileKinds.DOOR:
		return false
	var spot := box.tile_middle * TILE + DOOR_SPOT
	var left := world.fore_tile(box.tile_middle - 1, box.tile_top)
	if world.tile_info.fore(GalaxyTileInfo.Fore.MISC, left) == GalaxyTileKinds.DOOR:
		spot -= TILE
	if position.x == spot:
		safe_tics = DOOR_SAFE_TICS
		_continue_as(&"enter_door_1")
		priority = 0
	else:
		_slide_to(spot)
	sliding = true
	return true


func _slide_to(spot: int) -> void:
	slide_target = spot
	_continue_as(&"slide")


## Think: walking to a door, switch or gem holder (Omni CK_KeenSlide).
func _think_slide() -> void:
	var distance := slide_target - position.x
	if distance < 0:
		step.x -= world.tics * SLIDE_SPEED
		if step.x > distance:
			return
	elif distance > 0:
		step.x += world.tics * SLIDE_SPEED
		if step.x < distance:
			return
	step.x = distance
	slide_target = 0
	if not _press_up():
		_continue_as(&"stand")


## Think at the end of entering a door: he is put at its target (Omni
## CK_KeenEnterDoor).
func _think_enter_door() -> void:
	var target := world.info_at(box.tile_left, box.tile_bottom)
	position = Vector2i((target >> BYTE_SHIFT) * TILE, (target & BYTE_MASK) * TILE + DOOR_ARRIVAL)
	priority = 1
	clip = Clip.NONE
	set_action(action.next)
	clip = Clip.NORMAL
	went_through_door = true


## Think: the gem goes in; the holder changes (tile + 18) and the door at
## its target opens (Omni CK_KeenPlaceGem).
func _think_place_gem() -> void:
	var cell := Vector2i(box.tile_middle, box.tile_bottom)
	world.set_fore_tile(cell, world.fore_tile(cell.x, cell.y) + GEM_HOLDER_STEP)
	var target := world.info_at(cell.x, cell.y)
	var door := Vector2i(target >> BYTE_SHIFT, target & BYTE_MASK)
	if door.x < 2 or door.y < 2 or door.x > world.map.width or door.y > world.map.height:
		push_error("A gem holder points at %s, outside the level." % door)
		return
	GalaxyGemDoor.open_at(world, door)


## Think: the switch flips; a bridge switch moves its bridge on, another
## switch turns its turn point on or off (Omni CK_KeenPressSwitchThink).
func _think_press_switch() -> void:
	var cell := Vector2i(box.tile_middle, box.tile_top)
	var target := world.info_at(cell.x, cell.y)
	var at := Vector2i(target >> BYTE_SHIFT, target & BYTE_MASK)
	var tile := world.fore_tile(cell.x, cell.y)
	world.set_fore_tile(cell, world.tile_info.next_fore_tile(tile))
	if world.tile_info.fore(GalaxyTileInfo.Fore.MISC, tile) != GalaxyTileKinds.BRIDGE_SWITCH:
		world.set_info(at, world.info_at(at.x, at.y) ^ TURN_POINT_TOGGLE)
		return
	for row in BRIDGE_ROWS:
		var x := at.x - (0 if row == 0 else 1)
		while x < world.map.width:
			var bridge := world.fore_tile(x, at.y + row)
			var next := world.tile_info.next_fore_tile(bridge)
			if next == bridge:
				break
			world.set_fore_tile(Vector2i(x, at.y + row), next)
			x += 1


func _tile_at_head() -> int:
	return world.fore_tile(box.tile_middle, box.tile_top)


## Grabs a pole above him (up held) or below him (down held) (Omni
## CK_KeenTryClimbPole).
func _grab_pole() -> bool:
	if world.tic < pole_jump_tic:
		pole_jump_tic = 0
	elif world.tic - pole_jump_tic < POLE_REGRAB_TICS:
		return false
	var row := box.tile_bottom + 1
	if input.vertical == -1:
		row = GalaxyUnits.to_tile(box.top + POLE_REACH_UP)
	if world.misc_of(world.fore_tile(box.tile_middle, row)) != GalaxyTileKinds.POLE:
		return false
	position.x = POLE_X + (box.tile_middle - 1) * TILE
	step = Vector2i(0, input.vertical * POLE_GRAB_STEP)
	clip = Clip.NONE
	_continue_as(&"pole")
	return true


## Think on a pole, holding still (Omni CK_KeenPoleSitThink).
func _think_pole() -> void:
	if input.vertical == 1:
		_climb(&"pole_down_1", 1)
		_think_pole_down()
		return
	if input.vertical == -1:
		_climb(&"pole_up_1", -1)
		return
	if input.direction != 0:
		var ground := world.fore_tile(box.tile_middle, box.tile_bottom + 1)
		if world.clip.top_of(ground) != 0:
			velocity = Vector2i.ZERO
			clip = Clip.NORMAL
			jump_timer = 0
			_continue_as(&"fall_1")
			direction.y = 1
			return
	_pole_input()


func _think_pole_up() -> void:
	if world.misc_of(_tile_at_head()) != GalaxyTileKinds.POLE:
		step.y = 0
		_continue_as(&"pole")
		_pole_input()
		return
	if input.vertical == 0:
		_climb(&"pole", 0)
	elif input.vertical == 1:
		_climb(&"pole_down_1", 1)
		_think_pole_down()
	_pole_input()


func _think_pole_down() -> void:
	var under := world.fore_tile(
		box.tile_middle, GalaxyUnits.to_tile(box.bottom - POLE_FEET_MARGIN)
	)
	if world.misc_of(under) != GalaxyTileKinds.POLE:
		_continue_as(&"fall_1")
		jump_timer = 0
		velocity = Vector2i(POLE_LEAP_X[input.direction + 1], 0)
		clip = Clip.NORMAL
		box.tile_bottom -= 1
		return
	if input.vertical == 0:
		_climb(&"pole", 0)
	elif input.vertical == -1:
		_climb(&"pole_up_1", -1)
	_pole_input()


## React sliding down: reaching a floor he stands on it, looking down (Omni
## CK_KeenPoleDownDrawFunc).
func _react_pole_down() -> void:
	var ground := world.fore_tile(box.tile_middle, box.tile_bottom)
	if world.clip.top_of(ground) != FLAT:
		return
	var lift := -(box.bottom & BYTE_MASK) - 1
	position.y += lift
	box.bottom += lift
	box.tile_bottom -= 1
	clip = Clip.NORMAL
	_become(&"look_down_1")


func _climb(name: StringName, vertical: int) -> void:
	_continue_as(name)
	direction.y = vertical


## Turning, shooting and leaping off on a pole (Omni
## CK_KeenPoleHandleInput).
func _pole_input() -> void:
	if input.direction != 0:
		direction.x = input.direction
	if _fire_pressed():
		_use_fire()
		match input.vertical:
			-1:
				_continue_as(&"pole_shoot_up_1")
			1:
				_continue_as(&"pole_shoot_down_1")
			_:
				_continue_as(&"pole_shoot_1")
	if _jump_pressed():
		_use_jump()
		velocity = Vector2i(POLE_LEAP_X[input.direction + 1], POLE_LEAP_SPEED)
		clip = Clip.NORMAL
		jump_timer = POLE_LEAP_TICS
		_continue_as(&"jump_1")
		direction.y = 1
		pole_jump_tic = world.tic
