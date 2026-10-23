class_name GalaxyNamedBoxes
extends GalaxyGameBoxes
## A Galaxy episode's boxes ([GalaxyGameBoxes]), each picture named in
## [member names] for the player who joins online (made from Keen 4's
## [Keen4NamedBoxes], milestone E11; [GalaxyBoxNames]).

var names := GalaxyBoxNames.new()


static func create_named(
	data: GalaxyData, game_rules: GalaxyGameRules, box_names: GalaxyBoxNames
) -> GalaxyNamedBoxes:
	var boxes := GalaxyNamedBoxes.new()
	GalaxyGameBoxes.create(data, game_rules, boxes)
	boxes.names = box_names
	return boxes


func entering(map: int) -> Array[Image]:
	return names.name_all(super(map), [GalaxyBoxNames.Kind.ENTERING, map])


func demo_entering() -> Array[Image]:
	return names.name_all(super(), [GalaxyBoxNames.Kind.DEMO_ENTERING])


func loading_game_text(index: int) -> Array[Image]:
	return names.name_all(super(index), [GalaxyBoxNames.Kind.LOADING, index])


func paused() -> Image:
	return names.name(super(), [GalaxyBoxNames.Kind.PAUSED])


func one_moment() -> Image:
	return names.name(super(), [GalaxyBoxNames.Kind.ONE_MOMENT])


func try_again(map: int, choice: int, tic: int) -> Image:
	return names.name(super(map, choice, tic), [GalaxyBoxNames.Kind.TRY_AGAIN, map, choice, tic])


func game_over() -> Image:
	return names.name(super(), [GalaxyBoxNames.Kind.GAME_OVER])
