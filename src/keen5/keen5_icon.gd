class_name Keen5Icon
extends RefCounted
## The pictures on Keen 5's icon on the start screen: Keen walking, from the
## player's own Keen 5 sprites, and the name in Keen 5's own font. The
## shared icon code reads Keen 1-3's graphics only, so [GameCatalog] asks
## this class through [member GameCatalog.Game.icon_picture] and
## [member GameCatalog.Game.icon_title]. Only the tables, one sprite and one
## font are decoded, a few hundredths of a second.

const TITLE_COLOR := GameIcon.TEXT_COLOR

## The data read for the icon, by folder, so the two pictures read it once.
static var _loaded: Dictionary[String, GalaxyData] = {}


## Keen from the files in [param files]; null when they cannot be read.
static func picture(files: GameFiles) -> Texture2D:
	var data := _data(files)
	if data == null:
		return null
	return _texture(data.graphics.sprite(Keen5Episode.KEEN_WALK_RIGHT_SPRITE))


## [param text] in Keen 5's menu font; null when the files cannot be read.
static func title(files: GameFiles, text: String) -> Texture2D:
	var data := _data(files)
	var font := data.graphics.font(Keen5Episode.MENU_FONT) if data != null else null
	return _texture(font.render(text, TITLE_COLOR)) if font != null else null


static func _data(files: GameFiles) -> GalaxyData:
	if files == null:
		return null
	if not _loaded.has(files.directory):
		_loaded[files.directory] = Keen5Episode.load_data(files)
	return _loaded[files.directory]


static func _texture(image: Image) -> Texture2D:
	return ImageTexture.create_from_image(image) if image != null else null
