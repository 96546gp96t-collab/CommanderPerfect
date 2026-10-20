class_name GalaxyEnemyShot
extends GalaxyCreature
## A shot of a creature or a gun in a Galaxy level (Keen 4's darts, later
## Keen 5 and 6's shots): it flies by its action's velocity, kills the
## player it touches, and is gone at the first side of a tile it touches
## or once it leaves the screen (Omni CK4_ProjectileDraw, CK_LethalCol,
## OBJ_EXISTS_ONLY_ONSCREEN; facts only). The episode gives the rows: the
## react [code]fly[/code] removes it, the contact [code]lethal[/code]
## kills.


## A shot at [param at] (units) flying in [param heading], with the
## actions of [param rows], starting with [param first].
static func fire(
	world: GalaxyWorld,
	at: Vector2i,
	heading: Vector2i,
	rows: PackedStringArray,
	episode_sprites: Dictionary[StringName, int],
	first: StringName
) -> GalaxyEnemyShot:
	var shot := GalaxyEnemyShot.new()
	shot.activity = Activity.ON_SCREEN_ONLY
	shot.direction = heading
	shot.enter(world, at, rows, episode_sprites, first)
	return shot


## React: any side of a tile ends it (Omni CK4_ProjectileDraw).
func _react_fly() -> void:
	if top_hit != 0 or right_hit != 0 or bottom_hit != 0 or left_hit != 0:
		world.remove(self)
