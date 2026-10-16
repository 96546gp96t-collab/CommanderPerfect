extends SceneTree


func _initialize() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files)
	var props := TileProperties.load_from(files, graphics.tiles.size())
	var level := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	var counts := {}
	var rect := level.playable_rect()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var t := level.tile_at(Vector2i(x, y))
			counts[t] = counts.get(t, 0) + 1
	var bg: Image = graphics.tiles[143]
	print("143 color ", bg.get_pixel(0, 0), " uniform ", _uniform(bg))
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for t in keys:
		var img: Image = graphics.tiles[t]
		var n := 0
		for py in 16:
			for px in 16:
				if img.get_pixel(px, py).is_equal_approx(bg.get_pixel(0, 0)):
					n += 1
		print(
			(
				"tile %d x%d gray=%d solid_top=%s fg=%s beh=%d"
				% [
					t,
					counts[t],
					n,
					props.is_solid(t, 0) if props.has_method("is_solid") else "?",
					props.is_foreground(t),
					props.behavior(t)
				]
			)
		)
	quit()


func _uniform(img: Image) -> bool:
	var c := img.get_pixel(0, 0)
	for y in 16:
		for x in 16:
			if not img.get_pixel(x, y).is_equal_approx(c):
				return false
	return true
