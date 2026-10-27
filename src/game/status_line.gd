class_name StatusLine
extends RefCounted
## The text of the help line at the top left of the screen in the original
## (4:3) picture, where there is no room for the [Hud]: what is on the
## screen, how the picture is drawn, and what Keen carries, in the language
## in use.

const GRAPHICS_TITLES: Array[String] = ["Original graphics", "xBRZ graphics", "HD graphics"]


## The line about the picture: "Level 1   widescreen 426 x 200, ..." with
## [param title] for what is on the screen.
static func picture_text(title: String, settings: DisplaySettings) -> String:
	var game_size := settings.game_size()
	return (
		(
			Lang.text("%s   %s %d x %d, %s pixels, %s")
			% [
				title,
				Lang.text(settings.aspect_name()),
				game_size.x,
				game_size.y,
				Lang.text("4:3 monitor" if settings.correct_pixel_aspect else "square"),
				Lang.text(GRAPHICS_TITLES[settings.graphics]).to_lower(),
			]
		)
		+ (Lang.text(", realistic lighting") if settings.realistic else "")
	)


## The line about [param inventory]: score, lives, ammo and the rest.
static func inventory_text(inventory: Inventory) -> String:
	var parts := PackedStringArray(
		[
			Lang.text("Score %d") % inventory.score,
			Lang.text("Lives %d") % inventory.lives,
			Lang.text("Ammo %d") % inventory.charges,
		]
	)
	if inventory.has_pogo:
		parts.append(Lang.text("Pogo"))
	var cards := PackedStringArray()
	for color: String in TileProperties.KeyColor.keys():
		if inventory.keycards[TileProperties.KeyColor[color]]:
			cards.append(Lang.text(color.capitalize()))
	if not cards.is_empty():
		parts.append(Lang.text("Keycards: %s") % ", ".join(cards))
	var parts_found := inventory.ship_parts.count(true)
	if parts_found > 0:
		parts.append(Lang.text("Ship parts %d/%d") % [parts_found, inventory.ship_parts.size()])
	return "   ".join(parts)
