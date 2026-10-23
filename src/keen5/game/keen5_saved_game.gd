class_name Keen5SavedGame
extends GalaxySavedGame
## A saved game of Keen 5 ([GalaxySavedGame], milestone E9) with Keen 5's
## own game state (Omni ck_gameState.ep.ck5; docs/keen5/research.md §1):
## the keycard and the fuses still to break ([Keen5Inventory]), the levels
## done with 1 or 14 and the arrival on Korath III ([Keen5Progress]). The
## keycard is lost at every level's end and death, so a game saved on the
## world map never has it, and a level saved halfway gets it back from its
## frames; the fuses are counted again when the level starts, and the
## frames break the same ones again, so the count is the saved one. B+A+T
## and Shift+I among a saved level's frames give the keycard too.

const KEYCARD_KEY := "keycard"
const FUSES_KEY := "fuses_remaining"


func _new_inventory() -> GalaxyInventory:
	return Keen5Inventory.new_game()


func _new_progress() -> GalaxyProgress:
	return Keen5Progress.new()


func give_items(carried: GalaxyInventory) -> void:
	super(carried)
	(carried as Keen5Inventory).keycard = true


func give_everything(carried: GalaxyInventory) -> void:
	super(carried)
	(carried as Keen5Inventory).keycard = true


func _extra_inventory_to_dictionary(carried: GalaxyInventory) -> Dictionary:
	var keen_5 := carried as Keen5Inventory
	if keen_5 == null:
		return {}
	return {KEYCARD_KEY: keen_5.keycard, FUSES_KEY: keen_5.fuses_remaining}


func _extra_inventory_from_dictionary(carried: GalaxyInventory, saved: Dictionary) -> void:
	var keen_5 := carried as Keen5Inventory
	keen_5.keycard = bool(saved.get(KEYCARD_KEY, false))
	keen_5.fuses_remaining = int(saved.get(FUSES_KEY, 0))
