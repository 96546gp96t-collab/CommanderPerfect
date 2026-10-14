class_name Menu
extends RefCounted
## One menu: a few lines of text at the top, then a list of choices with a
## cursor. Choices that cannot be picked right now (such as an empty save
## slot) are skipped by the cursor. Only the logic; [MenuView] draws it.

## What the menu is for; the [MenuController] decides what a choice does.
var kind := &""
var header := PackedStringArray()
var items: Array[Item] = []
var cursor := 0


class Item:
	extends RefCounted
	var label := ""
	var id := &""
	## For the save slots: the slot number. For the controls: unused.
	var value := 0
	var enabled := true


static func create(menu_kind: StringName, lines: PackedStringArray = []) -> Menu:
	var menu := Menu.new()
	menu.kind = menu_kind
	menu.header = lines
	return menu


func add(label: String, id: StringName, value := 0, enabled := true) -> Menu:
	var item := Item.new()
	item.label = label
	item.id = id
	item.value = value
	item.enabled = enabled
	items.append(item)
	if not items[cursor].enabled and enabled:
		cursor = items.size() - 1
	return self


## Moves the cursor [param step] choices up (negative) or down, around the
## ends, over choices that cannot be picked.
func move(step: int) -> void:
	if items.is_empty():
		return
	var direction := signi(step)
	for count in absi(step):
		var next := cursor
		for attempt in items.size():
			next = posmod(next + direction, items.size())
			if items[next].enabled:
				break
		cursor = next


## Puts the cursor on the choice with [param id], if there is one.
func select(id: StringName) -> void:
	for index in items.size():
		if items[index].id == id and items[index].enabled:
			cursor = index
			return


## The choice under the cursor, or null when nothing can be picked.
func current() -> Item:
	if items.is_empty() or not items[cursor].enabled:
		return null
	return items[cursor]


## Width in characters of the widest line, choices included (with room for
## the cursor in front).
func width() -> int:
	var widest := 0
	for line in header:
		widest = maxi(widest, line.length())
	for item in items:
		widest = maxi(widest, MenuView.ITEM_INDENT + item.label.length())
	return widest
