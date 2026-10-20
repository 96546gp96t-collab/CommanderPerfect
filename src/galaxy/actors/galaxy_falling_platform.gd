class_name GalaxyFallingPlatform
extends GalaxyPlatform
## The falling platform of a Galaxy level (Omni `ck_obj.c`, CK_SpawnFallPlat,
## CK_FallPlatSit, CK_FallPlatFall, CK_FallPlatRise, facts and numbers
## only; docs/keen4/research.md §7):
##   - it floats where it was placed until Keen stands on it; then it sinks
##     16 units a tic, and once it is half a tile (128 units) below its
##     place it falls under gravity high;
##   - falling, its bottom stops on the edge of a turn point (info 0x1F)
##     below it; when Keen is not (or no longer) on it, it rises back 32
##     units a tic to its place and floats there again; Keen landing on it
##     while it rises makes it fall again;
##   - it is not clipped by the tiles, always awake and behind everything.
## Riding it is as on any platform ([GalaxyPlatform]).

## (Omni CK_ACT_FallPlat0-2.) Rising: 32 units a tic upwards.
const ROWS: PackedStringArray = [
	"float PLATFORM PLATFORM think -- 0 0 0 float - - -",
	"fall PLATFORM PLATFORM think -- 0 0 0 fall_down - - -",
	"rise PLATFORM PLATFORM slide+ -- 0 0 -32 rise - - -",
]
## Sinking under Keen: units a tic, and how far before it falls (Omni).
const SINK_SPEED := 16
const SINK_DEPTH := 0x80
## The last unit of a tile: the bottom stops there over a turn point.
const TILE_END := 0xFF

## Where it floats (its y, in units).
var home := 0


## A falling platform at [param cell] (Keen 4: info 32).
static func spawn(
	world: GalaxyWorld, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyFallingPlatform:
	var platform := GalaxyFallingPlatform.new()
	platform.clip = Clip.NONE
	platform.place_moving(world, cell, 2, ROWS, sprites, &"float")
	platform.home = platform.position.y
	return platform


## Whether Keen (either, when two play) stands on it now.
func carries_player() -> bool:
	for player in world.players():
		var keen := player as GalaxyKeenBody
		if keen != null and keen.platform == self:
			return true
	return false


## Think while floating: under Keen it sinks, and past half a tile it
## falls (Omni CK_FallPlatSit).
func _think_float() -> void:
	if not carries_player():
		return
	step.y = world.tics * SINK_SPEED
	velocity.y = 0
	if position.y + step.y - home >= SINK_DEPTH:
		_continue_as(&"fall")


## Think while falling: gravity high; a turn point below stops it, and
## without Keen it rises again (Omni CK_FallPlatFall).
func _think_fall_down() -> void:
	GalaxyPhysics.gravity_high(self)
	var row := GalaxyUnits.to_tile(box.bottom + step.y)
	if row != box.tile_bottom and _is_turn_point(box.tile_left, row):
		step.y = TILE_END - (box.bottom & TILE_END)
		if not carries_player():
			_continue_as(&"rise")


## Think while rising: Keen landing on it makes it fall again; at its
## place it floats (Omni CK_FallPlatRise).
func _think_rise() -> void:
	if carries_player():
		velocity.y = 0
		_continue_as(&"fall")
	elif position.y <= home:
		step.y = home - position.y
		_continue_as(&"float")
