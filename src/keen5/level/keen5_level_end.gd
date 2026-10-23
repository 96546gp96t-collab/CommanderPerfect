class_name Keen5LevelEnd
extends GalaxyCreature
## The unseen object that ends a Keen 5 level 60 tics after its last fuse
## broke or its QED was destroyed (Omni `ck5_misc.c` CK5_SpawnLevelEnd,
## CK5_LevelEnd; facts and numbers only; docs/keen5/research.md §4): always
## awake, never clipped; on map 12 the level ends as the QED's
## ([constant QED_ENDING], the end of the game), on every other map as a
## fuse's ([constant FUSE_ENDING]: the level counts as done with 14).

## (Omni CK5_ACT_LevelEnd.)
const ROWS: PackedStringArray = [
	"wait x x step -- 60 0 0 end - - -",
]
## How the level ends ([method GalaxyLevelSession.ending]; Omni
## LS_KorathFuse, LS_DestroyedQED).
const FUSE_ENDING := &"fuse"
const QED_ENDING := &"qed"
## The map of the QED (Omni).
const QED_MAP := 12


## The object, placed in [param world].
static func spawn(world: GalaxyWorld, sprites: Dictionary[StringName, int]) -> Keen5LevelEnd:
	var end := Keen5LevelEnd.new()
	end.activity = Activity.ALWAYS
	end.clip = Clip.NONE
	end.direction = Vector2i.ZERO
	end.enter(world, Vector2i.ZERO, ROWS, sprites, &"wait")
	return end


## Think after its 60 tics: the level ends (Omni CK5_LevelEnd).
func _think_end() -> void:
	world.complete(QED_ENDING if world.map_number == QED_MAP else FUSE_ENDING)
