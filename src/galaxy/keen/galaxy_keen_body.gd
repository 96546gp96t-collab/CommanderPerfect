class_name GalaxyKeenBody
extends GalaxyObject
## The base of Keen in a Galaxy level ([GalaxyKeen] is the whole of him;
## his states are split over three files by topic): what he carries and
## holds down, his timers, how he dies, shoots, and what he does with the
## tiles and objects he touches. The facts and numbers are Omnispeak's
## (`ck_keen.c`, marked (Omni); docs/keen4/research.md §5).
##
## Buttons: a press of jump, pogo or fire counts once; it is "used" by the
## move it starts and only counts again after it is let go (Omni
## jumpIsPressed / jumpWasPressed).

## How long nothing hurts him after going through a door, and after a
## death started (Omni ck_invincibilityTimer).
const DOOR_SAFE_TICS := 110
const DEATH_SAFE_TICS := 30
## Dying: he flies up and sideways under gravity mid (Omni CK_KillKeen).
const DEATH_SPEED := Vector2i(16, -40)
## Half the random range: which of the two death sprites.
const RANDOM_HALF := 0x80
## The sound of each item (Omni ck_itemSounds): the gems, the points, the
## extra life, the stunner.
const ITEM_SOUNDS: Array[StringName] = [
	&"got_gem",
	&"got_gem",
	&"got_gem",
	&"got_gem",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_item",
	&"got_extra_life",
	&"got_stunner",
]
## Where his shots start, from his position, in units (Omni
## CK_KeenSpawnShot).
const SHOT_STANDING_RIGHT := Vector2i(256, 64)
const SHOT_STANDING_LEFT := Vector2i(-128, 64)
const SHOT_AIR_RIGHT := Vector2i(256, 32)
const SHOT_AIR_LEFT := Vector2i(0, 32)
const SHOT_DOWN := Vector2i(128, 288)
const SHOT_UP := Vector2i(80, -160)
const SHOT_POLE_UP_RIGHT := Vector2i(96, 64)
const SHOT_POLE_UP_LEFT := Vector2i(192, 64)
const SHOT_POLE_DOWN_RIGHT := Vector2i(96, 384)
const SHOT_POLE_DOWN_LEFT := Vector2i(192, 384)
## A gem goes in when he stands this far left of the holder's tile (Omni).
const GEM_SPOT := -64
## Riding, he stands this far above the platform's box, and his x keeps
## the platform's lowest bits, so the two move as one (Omni
## CK_KeenRidePlatform).
const RIDE_GAP := 16
const RIDE_X_BITS := 0x1F

## His actions by name ([GalaxyKeenActions]).
var actions: Dictionary[StringName, GalaxyAction] = {}
## The episode's sprites by name (Keen's, the items', the shot's).
var sprites: Dictionary[StringName, int] = {}
var inventory := GalaxyInventory.new()
## The buttons held in this frame.
var input := KeenInput.new()
## Nothing kills him (the original's debug key F10+G).
var god_mode := false
var safe_tics := 0
## Set once he dies: the camera stops, so he falls out of the view.
var scroll_disabled := false
## Tics the jump (or pogo) keeps its upward speed (Omni jumpTimer).
var jump_timer := 0
## When he last jumped off a pole: he cannot grab one for 19 tics.
var pole_jump_tic := -1000
## Walking to a door, switch or gem holder; pressing up again does nothing
## until up is let go (Omni keenSliding).
var sliding := false
## Where the slide ends, in units.
var slide_target := 0
## Standing: tics without input, and which idle animation is next (Omni
## user1, user2).
var idle_tics := 0
var idle_stage := 0
## 1 while he stands on the moon spot (Keen 4), 2 once he showed it.
var moon := 0
## What he stands on and rides (a platform, a Bounder), or null (Omni
## ck_keenState.platform).
var platform: GalaxyObject
var _item_actions: Dictionary[StringName, GalaxyAction] = {}
var _shot_actions: Dictionary[StringName, GalaxyAction] = {}
var _jump_used := false
var _pogo_used := false
var _fire_used := false


## Sets up the actions of Keen, his shots and the items with
## [param episode_sprites].
func use_sprites(episode_sprites: Dictionary[StringName, int]) -> void:
	sprites = episode_sprites
	actions = GalaxyKeenActions.create(episode_sprites)
	_item_actions = GalaxyItem.actions_for(episode_sprites)
	_shot_actions = GalaxyStunnerShot.actions_for(episode_sprites)
	clips_like_keen = true
	activity = Activity.ALWAYS
	priority = 1


## The actions the items use (for placing them).
func item_actions() -> Dictionary[StringName, GalaxyAction]:
	return _item_actions


## Before a frame: the buttons held now (Omni CK_HandleInput), and the
## safe time of the last frame gone.
func begin_frame(held: KeenInput) -> void:
	input = held
	if input.vertical != -1:
		sliding = false
	if not input.jump:
		_jump_used = false
	if not input.pogo:
		_pogo_used = false
	if not input.fire:
		_fire_used = false
	safe_tics = maxi(safe_tics - world.tics, 0)


## Kills him, unless something keeps him safe (Omni CK_KillKeen).
func kill() -> void:
	if safe_tics > 0 or god_mode or is_dying():
		return
	moon = 0
	safe_tics = DEATH_SAFE_TICS
	scroll_disabled = true
	clip = Clip.NONE
	priority = GalaxyObjectLayer.TOP_PRIORITY
	set_action(actions[&"die_1" if world.random() < RANDOM_HALF else &"die_2"])
	velocity = DEATH_SPEED
	world.play_sound(&"keen_die")


func is_dying() -> bool:
	return action == actions.get(&"die_1") or action == actions.get(&"die_2")


## Switches to his action [param name] at once (Omni CK_SetAction2).
func _become(name: StringName) -> void:
	set_action(actions[name])


## Continues with action [param name] (Omni: obj->currentAction = ...).
func _continue_as(name: StringName) -> void:
	action = actions[name]


func _is_in(names: Array[StringName]) -> bool:
	for name in names:
		if action == actions[name]:
			return true
	return false


## Grabs a pole above or below him when there is one; returns whether he
## did ([GalaxyKeen] knows poles).
func _grab_pole() -> bool:
	return false


func _jump_pressed() -> bool:
	return input.jump and not _jump_used


func _pogo_pressed() -> bool:
	return input.pogo and not _pogo_used


func _fire_pressed() -> bool:
	return input.fire and not _fire_used


func _use_jump() -> void:
	_jump_used = true


func _use_pogo() -> void:
	_pogo_used = true


func _use_fire() -> void:
	_fire_used = true


## Think: the shot of the shooting action he is in (Omni
## CK_KeenSpawnShot).
func _think_shoot() -> void:
	var right := direction.x == 1
	match action.name:
		&"shoot_1", &"pole_shoot_1":
			_shoot(SHOT_STANDING_RIGHT if right else SHOT_STANDING_LEFT, Vector2i(direction.x, 0))
		&"jump_shoot_2":
			_shoot(SHOT_AIR_RIGHT if right else SHOT_AIR_LEFT, Vector2i(direction.x, 0))
		&"jump_shoot_down_2":
			_shoot(SHOT_DOWN, Vector2i.DOWN)
		&"jump_shoot_up_2", &"shoot_up_1":
			_shoot(SHOT_UP, Vector2i.UP)
		&"pole_shoot_up_1":
			_shoot(SHOT_POLE_UP_RIGHT if right else SHOT_POLE_UP_LEFT, Vector2i.UP)
		&"pole_shoot_down_1":
			_shoot(SHOT_POLE_DOWN_RIGHT if right else SHOT_POLE_DOWN_LEFT, Vector2i.DOWN)


## A shot from [param offset] (from his position), if he has a charge.
func _shoot(offset: Vector2i, heading: Vector2i) -> void:
	if inventory.shots <= 0:
		world.play_sound(&"keen_out_of_ammo")
		return
	inventory.shots -= 1
	world.play_sound(&"keen_shoot")
	GalaxyStunnerShot.fire(world, position + offset, heading, _shot_actions)


## Think while dying: he flies on under gravity mid; once out of the view
## (his own, when two play) the level is lost (Omni CK_KeenDeathThink).
func _think_dying() -> void:
	GalaxyPhysics.gravity_mid(self)
	step.x = velocity.x * world.tics
	if not world.on_own_screen(self):
		world.state = GalaxyWorld.LevelState.DIED


## After the contacts: what he does with the tiles under his box: deadly
## tiles, drops, items, gem holders, the moon spot (Omni
## CK_KeenCheckSpecialTileInfo).
func _touch_tiles() -> void:
	if moon == 1:
		moon = 0
	for y in range(box.tile_top, box.tile_bottom + 1):
		for x in range(box.tile_left, box.tile_right + 1):
			var kind := world.misc_of(world.fore_tile(x, y))
			if kind == GalaxyTileKinds.DEADLY:
				kill()
			elif kind == GalaxyTileKinds.DROP:
				_take_drop(Vector2i(x, y))
			elif GalaxyTileKinds.is_gem_holder(kind):
				_reach_gem_holder(x, y, kind - GalaxyTileKinds.FIRST_GEM_HOLDER)
				return
			elif kind == GalaxyTileKinds.MOON and moon == 0:
				moon = 1
			elif GalaxyTileKinds.is_item(kind):
				_take_item_tile(Vector2i(x, y), kind - GalaxyTileKinds.ITEM_TILE_OFFSET)


func _take_drop(cell: Vector2i) -> void:
	world.set_fore_tile(cell, GalaxyTileKinds.EMPTY_TILE)
	world.play_sound(&"got_drop")
	var life := inventory.add_drop()
	if life:
		world.play_sound(&"got_extra_life")
	GalaxyItem.splash_at(world, cell, life, sprites, _item_actions)


func _take_item_tile(cell: Vector2i, item: int) -> void:
	world.set_fore_tile(cell, GalaxyTileKinds.EMPTY_TILE)
	_collect(item, true)
	GalaxyItem.rise_from(world, cell, item, sprites, _item_actions)


## Standing on a gem holder with a gem of its colour: he walks to its spot
## and puts the gem in.
func _reach_gem_holder(x: int, y: int, colour: int) -> void:
	if y != box.tile_bottom or top_hit == 0 or action == actions[&"place_gem"]:
		return
	if not inventory.has_gem(colour):
		return
	var spot := GalaxyUnits.from_tile(x) + GEM_SPOT
	if position.x == spot:
		inventory.use_gem(colour)
		_become(&"place_gem")
	else:
		slide_target = spot
		_continue_as(&"slide")


## Contact while walking, jumping or standing: items, and what the other
## object does to him (Omni CK_KeenColFunc).
func _contact_normal(other: GalaxyObject) -> void:
	var item := other as GalaxyItem
	if item != null:
		if not item.taken:
			_collect(item.collect(sprites))
		return
	other.touched_by_player(self, false)


## Takes item [param item] with its sound, and the extra life's sound
## when its points give one (Omni CK_KeenColFunc, CK_IncreaseScore).
func _collect(item: int, as_tile := false) -> void:
	world.play_sound(ITEM_SOUNDS[mini(item, ITEM_SOUNDS.size() - 1)])
	if inventory.collect(item, as_tile):
		world.play_sound(&"got_extra_life")


## Contact while on a pole, hanging or looking (Omni CK_KeenSpecialColFunc).
func _contact_special(other: GalaxyObject) -> void:
	other.touched_by_player(self, true)


## [param pusher] pushes him out sideways, or he lands on it and rides it,
## or it bumps his head (Omni CK_PhysPushXY, without squashing).
func push_out(pusher: GalaxyObject) -> void:
	var dx := pusher.moved.x - moved.x
	step = Vector2i.ZERO
	var from_left := pusher.box.right - box.left
	var from_right := box.right - pusher.box.left
	if from_left > 0 and dx + 1 >= from_left:
		_pushed_sideways(from_left)
		right_hit = 1
		return
	if from_right > 0 and -dx + 1 >= from_right:
		_pushed_sideways(-from_right)
		left_hit = 1
		return
	var dy := moved.y - pusher.moved.y
	var onto := box.bottom - pusher.box.top
	var under := pusher.box.bottom - box.top
	if onto >= 0 and onto <= dy:
		platform = pusher
		step.y = -onto
		world.clip.update_simple(self)
		if bottom_hit == 0:
			top_hit = ON_PLATFORM
	elif under >= 0 and under <= dy:
		step.y = under
		world.clip.update_normal(self)
		bottom_hit = ON_PLATFORM


## He lands on [param pusher] from above and rides it (Omni CK_PhysPushY).
func land_on(pusher: GalaxyObject) -> void:
	var onto := box.bottom - pusher.box.top
	if onto < 0 or onto > moved.y - pusher.moved.y:
		return
	platform = pusher
	step = Vector2i(0, -onto)
	# Not pushed down onto the ground in this move (Omni).
	var sticks := action.stick_to_ground
	action.stick_to_ground = false
	world.clip.update_normal(self)
	action.stick_to_ground = sticks
	if bottom_hit == 0:
		top_hit = ON_PLATFORM


## [param pusher] knocks him off a pole or ledge: he falls, pushed out of
## its way (Omni CK_KeenSpecialColFunc).
func knock_off(pusher: GalaxyObject) -> void:
	priority = 1
	clip = Clip.NORMAL
	_become(&"fall_1")
	jump_timer = 0
	velocity = Vector2i.ZERO
	push_out(pusher)


## A platform [param carrier] touches him on a pole or ledge: he falls and
## lands on it (Omni CK_KeenSpecialColFunc; Keen 4 keeps his drawing
## priority, the bug only Keen 6 fixed).
func fall_onto(carrier: GalaxyObject) -> void:
	clip = Clip.NORMAL
	_become(&"fall_1")
	jump_timer = 0
	velocity = Vector2i.ZERO
	land_on(carrier)


## After everything moved: he moves with what he stands on, or leaves it
## (Omni CK_KeenRidePlatform).
func _ride_platform() -> void:
	if platform == null:
		return
	var carrier := platform
	if carrier.removed or box.right < carrier.box.left or box.left > carrier.box.right:
		platform = null
		return
	if moved.y < 0:
		# He jumped off.
		platform = null
		if carrier.moved.y < 0:
			step = Vector2i(0, carrier.moved.y)
			world.clip.update_simple(self)
		return
	step = Vector2i(carrier.moved.x, carrier.box.top - box.bottom - RIDE_GAP)
	world.clip.update_simple(self)
	position.x |= carrier.position.x & RIDE_X_BITS
	if bottom_hit != 0:
		platform = null
		return
	top_hit = ON_PLATFORM


func _pushed_sideways(distance: int) -> void:
	step.x = distance
	velocity.x = 0
	world.clip.update_simple(self)
