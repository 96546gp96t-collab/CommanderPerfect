class_name Keen4NamedBoxes
extends Keen4GameBoxes
## Keen 4's boxes ([Keen4GameBoxes]), each picture named in [member names]
## for the player who joins online (milestone D12; [Keen4BoxNames]).

var names := Keen4BoxNames.new()


static func create_named(data: GalaxyData, box_names: Keen4BoxNames) -> Keen4NamedBoxes:
	var boxes := Keen4NamedBoxes.new()
	Keen4GameBoxes.create(data, null, boxes)
	boxes.names = box_names
	return boxes


func entering(map: int) -> Array[Image]:
	return names.name_all(super(map), [Keen4BoxNames.Kind.ENTERING, map])


func demo_entering() -> Array[Image]:
	return names.name_all(super(), [Keen4BoxNames.Kind.DEMO_ENTERING])


func paused() -> Image:
	return names.name(super(), [Keen4BoxNames.Kind.PAUSED])


func one_moment() -> Image:
	return names.name(super(), [Keen4BoxNames.Kind.ONE_MOMENT])


func cant_swim() -> Image:
	return names.name(super(), [Keen4BoxNames.Kind.CANT_SWIM])


func try_again(map: int, choice: int, tic: int) -> Image:
	return names.name(super(map, choice, tic), [Keen4BoxNames.Kind.TRY_AGAIN, map, choice, tic])


func game_over() -> Image:
	return names.name(super(), [Keen4BoxNames.Kind.GAME_OVER])
