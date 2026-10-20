class_name GalaxyStunnerShot
extends GalaxyObject
## A shot of Keen's neural stunner (Omni `ck_keen.c:CK_SpawnShot`,
## CK_ShotThink, CK_ShotDrawFunc; docs/keen4/research.md §5): it flies 64
## units a tic in one of four directions, four frames of 6 tics, and stops
## at the first solid tile side, except a pole hole, which it passes (it is
## moved into the hole's column first). Where it stops it shows two frames
## of 12 tics. Off the screen it still stuns what is asleep in its way; it
## is removed 10 tiles beside or 6 tiles above or below the view.
## Sprites by name: STUN_1..4, STUN_HIT_1..2.

## (Omni CK_ACT_keenShot*, CK_ACT_keenShotHit*.)
const ROWS: PackedStringArray = [
	"fly_1 STUN_1 STUN_1 slide -- 6 64 64 fly - fly fly_2",
	"fly_2 STUN_2 STUN_2 slide -- 6 64 64 fly - fly fly_3",
	"fly_3 STUN_3 STUN_3 slide -- 6 64 64 fly - fly fly_4",
	"fly_4 STUN_4 STUN_4 slide -- 6 64 64 fly - fly fly_1",
	"hit_1 STUN_HIT_1 STUN_HIT_1 step -- 12 0 0 - - - hit_2",
	"hit_2 STUN_HIT_2 STUN_HIT_2 step -- 12 0 0 - - - -",
]
## Shots fly behind everything (Omni zLayer 0).
const PRIORITY := 0
## Removed this many tiles beside / above or below the view (Omni).
const KEEP_SIDEWAYS := 10
const KEEP_UPRIGHT := 6
const TILE := GalaxyUnits.PER_TILE
const TILE_MASK := 0xFF
const FLAT := 1

## It hit something and only shows where: it stuns nothing any more.
var spent := false
var _actions: Dictionary[StringName, GalaxyAction]


## The actions with the sprites of [param sprites].
static func actions_for(
	sprites: Dictionary[StringName, int]
) -> Dictionary[StringName, GalaxyAction]:
	return GalaxyAction.table_from(ROWS, sprites)


## A shot at [param at] (units) flying in [param heading] (one of the four
## directions).
static func fire(
	world: GalaxyWorld,
	at: Vector2i,
	heading: Vector2i,
	actions: Dictionary[StringName, GalaxyAction]
) -> GalaxyStunnerShot:
	var shot := GalaxyStunnerShot.new()
	shot._actions = actions
	shot.position = at
	shot.priority = PRIORITY
	shot.activity = Activity.ALWAYS
	shot.direction = heading
	world.add(shot)
	shot.start(actions[&"fly_1"])
	return shot


## It hits something: it stops and shows where (Omni CK_ShotHit).
func hit() -> void:
	world.play_sound(&"shot_hit")
	spent = true
	set_action(_actions[&"hit_1"])


## Think: far from the view it is removed; off the screen it stuns what
## sleeps in its way (Omni CK_ShotThink).
func _think_fly() -> void:
	if world.on_screen(self):
		return
	var view := Rect2i(
		GalaxyUnits.to_tile(world.camera.scroll.x),
		GalaxyUnits.to_tile(world.camera.scroll.y),
		GalaxyWorld.VIEW_TILES.x,
		GalaxyWorld.VIEW_TILES.y
	)
	if (
		box.tile_right + KEEP_SIDEWAYS < view.position.x
		or box.tile_left - KEEP_SIDEWAYS > view.end.x
		or box.tile_bottom + KEEP_UPRIGHT < view.position.y
		or box.tile_top - KEEP_UPRIGHT > view.end.y
	):
		world.remove(self)
		return
	for other in world.objects:
		if other == self or GalaxyWorld.is_awake(other) or not box.overlaps(other.box):
			continue
		if other.action != null and not other.action.contact.is_empty():
			other.call(other.action.contact, self)
			other.needs_react = true
			other.activity = Activity.ACTIVE
		if spent:
			return


## React: through a pole hole, or stop at what it hit (Omni
## CK_ShotDrawFunc).
func _react_fly() -> void:
	var clip_tiles := world.clip
	var narrow := box.tile_left == box.tile_right
	if top_hit == FLAT and not narrow:
		# Going down onto a floor beside a pole hole: into the hole.
		var above := clip_tiles.tile_at(box.tile_right, box.tile_top - 1)
		if clip_tiles.top_of(above) == GalaxyTileKinds.POLE_HOLE:
			top_hit = GalaxyTileKinds.POLE_HOLE
			position.x += TILE - (position.x & TILE_MASK)
	elif top_hit == GalaxyTileKinds.POLE_HOLE and not narrow:
		position.x &= ~TILE_MASK
	if bottom_hit == FLAT and not narrow:
		var below := clip_tiles.tile_at(box.tile_right, box.tile_bottom + 1)
		if clip_tiles.bottom_of(below) == GalaxyTileKinds.POLE_HOLE:
			bottom_hit = GalaxyTileKinds.POLE_HOLE
			position.x += TILE - (position.x & TILE_MASK)
	elif bottom_hit == GalaxyTileKinds.POLE_HOLE and not narrow:
		position.x &= ~TILE_MASK
	if top_hit != GalaxyTileKinds.POLE_HOLE and bottom_hit != GalaxyTileKinds.POLE_HOLE:
		if top_hit != 0 or bottom_hit != 0 or left_hit != 0 or right_hit != 0:
			hit()
		return
	# Through the hole: on as far as it would have flown.
	var dy := action.velocity.y * world.tics * direction.y
	position.y += dy
	box.top += dy
	box.bottom += dy
	box.tile_top = GalaxyUnits.to_tile(box.top)
	box.tile_bottom = GalaxyUnits.to_tile(box.bottom)
