class_name Keen4NamedMessages
extends Keen4Messages
## Keen 4's messages ([Keen4Messages]), each picture named in
## [member names] for the player who joins online (milestone D12;
## [Keen4BoxNames]).

var names := Keen4BoxNames.new()


static func create_named(data: GalaxyData, box_names: Keen4BoxNames) -> Keen4NamedMessages:
	var messages := Keen4NamedMessages.new()
	Keen4Messages.create(data, messages)
	messages.names = box_names
	return messages


func council(level: int, rescued_before: int) -> Array[Image]:
	return names.name_all(
		super(level, rescued_before), [Keen4BoxNames.Kind.COUNCIL, level, rescued_before]
	)


func janitor() -> Array[Image]:
	return names.name_all(super(), [Keen4BoxNames.Kind.JANITOR])


func lindsey(level: int) -> Array[Image]:
	return names.name_all(super(level), [Keen4BoxNames.Kind.LINDSEY, level])


func wetsuit() -> Array[Image]:
	return names.name_all(super(), [Keen4BoxNames.Kind.WETSUIT])
