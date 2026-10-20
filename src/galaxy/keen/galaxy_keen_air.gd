class_name GalaxyKeenAir
extends GalaxyKeenBody
## Keen in the air: jumping, falling, the pogo stick, shooting in the air,
## and grabbing a ledge, hanging and pulling himself up (Omni `ck_keen.c`:
## CK_KeenJumpThink, CK_KeenJumpDrawFunc, CK_KeenPogo*, CK_KeenHangThink,
## CK_KeenPullThink*; facts and numbers only; docs/keen4/research.md §5).
##
## - A jump keeps −40 units a tic for up to 18 tics while jump is held, then
##   gravity high takes over. In the air left/right accelerate him 2 every
##   odd tic up to 24; without them he slows down 1 a tic.
## - The pogo bounces with −48 for 24 tics (gravity low while jump is held
##   or for the last 9 tics, high otherwise); left/right accelerate him 1 up
##   to 24 and he keeps his speed without them. Pogo again: he falls.
## - Falling past the top of a wall with left or right held towards it, he
##   grabs the ledge when the tile above it is free.

## (Omni.)
const JUMP_SPEED := -40
const JUMP_TICS := 18
const AIR_ACCEL := 2
const AIR_MAX := 24
const POGO_SPEED := -48
const POGO_TICS := 24
## The pogo's first bounce from the ground lifts him this far at once.
const POGO_FIRST_LIFT := 6
## The pogo's gravity is low for the last tics of a bounce even without
## jump held.
const POGO_LOW_TICS := 9
const POGO_ACCEL := 1
## Bumping a sloped ceiling slows the upward speed by this much.
const CEILING_SLOW := 16
## Hitting a pole hole from below: Keen is put on the pole's column.
const POLE_HOLE_LIFT := 32
const POLE_HOLE_X := -32
## Ledges: where his box's top must pass (1.5 tiles under the ledge's top,
## Omni), and where he hangs.
const LEDGE_GRAB_OFFSET := 64
const TILE_MASK := ~0xFF
const HANG_LEFT_X := 128
const HANG_RIGHT_X := 256
## Pulling himself up: the steps of the four pulling actions (Omni).
const PULL_STEP := 128
const PULL_FIRST_RIGHT := -256
const PULL_FIRST_LEFT := -128
const FALL_SIDEWAYS := 8
const FLAT := 1

## On Easy he falls under gravity mid after a jump or a pogo bounce
## instead of high (Omni CK_KeenJumpThink, CK_KeenPogoThink).
var easy_jumps := false


## Think: jumping and falling (Omni CK_KeenJumpThink).
func _think_jump() -> void:
	if jump_timer > 0:
		if jump_timer <= world.tics:
			step.y = velocity.y * jump_timer
			jump_timer = 0
		else:
			step.y = velocity.y * world.tics
			jump_timer -= world.tics
		if not input.jump:
			jump_timer = 0
		if jump_timer == 0 and action.next != null:
			action = action.next
	else:
		_fall()
		if velocity.y > 0 and not _is_in([&"fall_1", &"fall_2"]):
			action = action.next
	if input.direction != 0:
		direction.x = input.direction
		GalaxyPhysics.accelerate_x(self, input.direction * AIR_ACCEL, AIR_MAX)
	else:
		GalaxyPhysics.damp_x(self)
	if bottom_hit == GalaxyTileKinds.POLE_HOLE:
		step.x = 0
		velocity.x = 0
	if _fire_pressed():
		_use_fire()
		_shoot_in_air()
		return
	if _pogo_pressed():
		_use_pogo()
		_continue_as(&"pogo_2")
		jump_timer = 0
		return
	if input.vertical == -1:
		_grab_pole()


## Gravity once the jump's or the bounce's push is over.
func _fall() -> void:
	if easy_jumps:
		GalaxyPhysics.gravity_mid(self)
	else:
		GalaxyPhysics.gravity_high(self)


## Think: a pogo bounce from the ground (Omni CK_KeenPogoBounceThink).
func _think_pogo_bounce() -> void:
	world.play_sound(&"keen_pogo")
	velocity.y = POGO_SPEED
	step.y = POGO_FIRST_LIFT * velocity.y
	jump_timer = POGO_TICS


## Think: on the pogo (Omni CK_KeenPogoThink).
func _think_pogo() -> void:
	if jump_timer == 0:
		_fall()
	else:
		if input.jump or jump_timer <= POGO_LOW_TICS:
			GalaxyPhysics.gravity_low(self)
		else:
			GalaxyPhysics.gravity_high(self)
		jump_timer = 0 if jump_timer <= world.tics else jump_timer - world.tics
		if jump_timer == 0 and action.next != null:
			action = action.next
	if input.direction != 0:
		if velocity.x == 0:
			direction.x = input.direction
		GalaxyPhysics.accelerate_x(self, input.direction * POGO_ACCEL, AIR_MAX)
	else:
		step.x += velocity.x * world.tics
		if velocity.x != 0:
			direction.x = signi(velocity.x)
	if bottom_hit == GalaxyTileKinds.POLE_HOLE:
		step.x = 0
		velocity.x = 0
	if _fire_pressed():
		_use_fire()
		_shoot_in_air()
		return
	if _pogo_pressed():
		_use_pogo()
		_continue_as(&"fall_1")


## React in the air: walls stop him, ceilings bounce him, the ground ends
## the jump, and ledges are grabbed (Omni CK_KeenJumpDrawFunc).
func _react_jump() -> void:
	_stop_at_walls()
	_bump_head()
	if top_hit != 0:
		moved.y = 0
		if GalaxyTileKinds.is_deadly_floor(top_hit):
			kill()
		elif top_hit != GalaxyObject.ON_PLATFORM or jump_timer == 0:
			idle_tics = 0
			idle_stage = 0
			if action == actions[&"jump_shoot_1"]:
				_become(&"shoot_1")
			elif action == actions[&"jump_shoot_up_1"]:
				_become(&"shoot_up_1")
			elif input.direction != 0:
				_become(&"run_1")
			else:
				_become(&"stand")
			world.play_sound(&"keen_land")
	elif moved.y > 0:
		_grab_ledge()


## React on the pogo: as in a jump, but the ground bounces him (Omni
## CK_KeenPogoDrawFunc).
func _react_pogo() -> void:
	_stop_at_walls()
	_bump_head()
	if top_hit == 0:
		return
	moved.y = 0
	if GalaxyTileKinds.is_deadly_floor(top_hit):
		kill()
	elif top_hit != GalaxyObject.ON_PLATFORM or jump_timer == 0:
		velocity.y = POGO_SPEED
		jump_timer = POGO_TICS
		world.play_sound(&"keen_pogo")
		_become(&"pogo_2")


## Think: hanging on a ledge: up or towards the wall pulls him up, down or
## away lets go (Omni CK_KeenHangThink).
func _think_hang() -> void:
	if input.vertical == -1 or input.direction == direction.x:
		_continue_as(&"pull_1")
		var column := box.tile_right if direction.x == 1 else box.tile_left
		step.y = PULL_FIRST_RIGHT if direction.x == 1 else PULL_FIRST_LEFT
		# Over the ledge's tile, unless that tile is drawn in front anyway.
		if not world.tile_info.is_in_front(world.fore_tile(column, box.tile_top - 1)):
			priority = GalaxyObjectLayer.TOP_PRIORITY
	elif input.vertical == 1 or (input.direction != 0 and input.direction != direction.x):
		_continue_as(&"fall_1")
		clip = Clip.NORMAL


## The first pull lifts him only when he faces left (whose hang lifted him
## half as far). Omnispeak moves him a step sideways when he faces right,
## which leaves him 128 units further on the ledge than the original
## (v1.0): there he stands one step from the edge, facing either way, and
## then walks on as ours now does (seen in the original twice, D13).
func _think_pull_1() -> void:
	if direction.x == -1:
		step.y = -PULL_STEP


func _think_pull_2() -> void:
	step.x = direction.x * PULL_STEP
	step.y = -PULL_STEP


func _think_pull_3() -> void:
	step.y = -PULL_STEP


func _think_pull_4() -> void:
	clip = Clip.NORMAL
	priority = 1
	step.y = PULL_STEP


## Running into a wall in the air ends the sideways speed.
func _stop_at_walls() -> void:
	if (right_hit != 0 and direction.x == -1) or (left_hit != 0 and direction.x == 1):
		velocity.x = 0


## A ceiling: a pole hole lets him onto the pole's column; anything else
## ends the upward move (a slope only slows it).
func _bump_head() -> void:
	if bottom_hit == 0:
		return
	if bottom_hit == GalaxyTileKinds.POLE_HOLE:
		position.y -= POLE_HOLE_LIFT
		box.top -= POLE_HOLE_LIFT
		velocity.x = 0
		position.x = GalaxyUnits.from_tile(box.tile_middle) + POLE_HOLE_X
		return
	world.play_sound(&"keen_hit_ceiling")
	if bottom_hit > FLAT:
		velocity.y = maxi(velocity.y + CEILING_SLOW, 0)
	else:
		velocity.y = 0
	jump_timer = 0


## Falling with left or right held past the top of a wall whose tile above
## is free: he hangs on its ledge (Omni, in CK_KeenJumpDrawFunc).
func _grab_ledge() -> void:
	var was_top := box.top - moved.y
	var line := ((box.top - LEDGE_GRAB_OFFSET) & TILE_MASK) + LEDGE_GRAB_OFFSET
	if not (was_top < line and box.top >= line) or input.direction == 0:
		return
	var row := GalaxyUnits.to_tile(line) - 1
	var right := input.direction == 1
	var column := 0
	if right:
		column = box.tile_right + (1 if left_hit != 0 else 0)
	else:
		column = box.tile_left - (1 if right_hit != 0 else 0)
	var clip_tiles := world.clip
	var upper := clip_tiles.tile_at(column, row)
	var lower := clip_tiles.tile_at(column, row + 1)
	var wall := clip_tiles.left_of(lower) if right else clip_tiles.right_of(lower)
	if clip_tiles.is_solid(upper) or wall == 0 or clip_tiles.top_of(lower) == 0:
		return
	direction.x = input.direction
	clip = Clip.NONE
	position.x = (position.x & TILE_MASK) + (HANG_RIGHT_X if right else HANG_LEFT_X)
	position.y = line - LEDGE_GRAB_OFFSET
	velocity.y = 0
	moved.y = 0
	_become(&"hang_1")


## Fire in the air: up, ahead or down by what is held (Omni).
func _shoot_in_air() -> void:
	match input.vertical:
		-1:
			_continue_as(&"jump_shoot_up_1")
		1:
			_continue_as(&"jump_shoot_down_1")
		_:
			_continue_as(&"jump_shoot_1")


## Walking off a ledge: he falls with a little sideways speed (Omni, in
## CK_KeenDrawFunc).
func _start_falling() -> void:
	velocity = Vector2i(direction.x * FALL_SIDEWAYS, 0)
	_become(&"fall_1")
	jump_timer = 0
