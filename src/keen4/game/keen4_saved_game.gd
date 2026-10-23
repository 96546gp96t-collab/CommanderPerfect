class_name Keen4SavedGame
extends GalaxySavedGame
## A saved game of Keen 4. The original saves anywhere through its menu,
## on the world map and in a level, and a loaded level goes on exactly as
## it was (Omni `ck_game.c`: CK_SaveGame writes the game state, the three
## planes and every object). Ours keeps the same promise another way:
##   - on the world map: what Keen carries, the progress (rescues, wetsuit,
##     levels done) and his place on the map;
##   - in a level: the same as it was when Keen entered the level, the place
##     the random table started, and every logic frame since (the keys held
##     and its tics, plus the cheats and god mode as events). Loading starts
##     the level again and plays those frames at once: the engine is
##     deterministic (the five demos play frame for frame as the original),
##     so every creature, tile and item is where it was.
## Stored as a dictionary in a [GalaxySaveSlots] slot. The shared
## [GalaxySavedGame] (since milestone E13) with Keen 4's inventory and
## progress ([Keen4Progress]: its own format), and the static functions
## Keen 4's code and tests use.


func _init(game_rules: GalaxyGameRules = null) -> void:
	super(game_rules if game_rules != null else Keen4Episode.game_rules())


## The game kept in [param saved]; null (and says why) when it is not one.
static func from_dictionary(saved: Dictionary) -> Keen4SavedGame:
	var game := Keen4SavedGame.new()
	if not game.load_dictionary(saved):
		return null
	return game


static func inventory_to_dictionary(carried: GalaxyInventory) -> Dictionary:
	return Keen4SavedGame.new().save_inventory(carried)


static func inventory_from_dictionary(saved: Dictionary) -> Keen4Inventory:
	return Keen4SavedGame.new().load_inventory(saved) as Keen4Inventory


## A replay of [param recorded] on [param session] (a level just started).
static func replay_on(
	session: GalaxyLevelSession, recorded: PackedByteArray, each_frame := Callable()
) -> Replay:
	return Keen4SavedGame.new().begin_replay(session, recorded, each_frame)


## Plays all of [param recorded] on [param session] at once; returns the
## absolute tic of its last frame.
static func replay(session: GalaxyLevelSession, recorded: PackedByteArray) -> int:
	return Keen4SavedGame.new().replay_all(session, recorded)


static func _input_of(bits: int) -> KeenInput:
	return input_of(bits)


static func _apply(session: GalaxyLevelSession, event: int) -> void:
	Keen4SavedGame.new().apply(session, event)


func _new_inventory() -> GalaxyInventory:
	return Keen4Inventory.new_game()


func _new_progress() -> GalaxyProgress:
	return Keen4Progress.new()
