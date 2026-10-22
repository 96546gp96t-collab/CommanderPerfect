# Keen 5: the rules of a level in our engine

What a Keen 5 level does in CommanderPerfect so far, and where its numbers
come from. Started in milestone E3 (the shared Galaxy game, a level played
without creatures); later milestones add to it, as
[../keen4/gameplay.md](../keen4/gameplay.md) grew from D3 on. Everything
that is the same as in Keen 4 (Keen's moves, the camera, the score box,
drawing, widescreen) is described there and not repeated here. The facts
and their sources are in [research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.4 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The flow for now (E3)

As Keen 4 had it in D4; the original's flow (the world map, the boxes,
the title, the menus) comes in E6-E9.

| What | Then |
|---|---|
| Keen 5 picked on the start screen, or `-- --game=5` | Level 1 at once (a new game: 3 lives, 5 charges, the first extra life at 20,000) |
| `-- --game=5 --level=N` | Map N at once: 1-13 and 15 (the high-score map) played; 0 (the world map) shown with Keen standing, the arrows look around (E6 plays it); 14 does not exist: a message |
| The exit door (target 0xB1B1), the door to Korath III (0x0000) or walking out of the level | The next level: 1 … 13, then 1 again (14 skipped); from 15 to 1 |
| Keen dies | One life less, the gems and the keycard gone, the level again; with fewer than 0 lives the start screen |
| Escape | The start screen |
| Shift+N / Shift+P | The next or previous map, over the missing 14, round from 15 to 0 |
| Shift+G | God mode (as the original's F10+G: nothing kills Keen but falling out of the level) |
| Shift+I | All four gems, the keycard and at least 99 charges |
| F1 | The help line; F2-F6 as in Keen 1-4 |

The fuse levels (4, 6, 8, 10 and 12) have no exit door: they end when
their fuses are broken (E5). Until then they can only be left by
Shift+N.

## Keen's moves (E3)

Keen 4's, unchanged: the actions in `ACTION.CK5` are the same as in
`ACTION.CK4` (Omni; research.md §1). What Keen 5 changes:

- **No moon.** Misc 16 is on two Keen 5 tiles but means nothing; Keen
  5's Keen has no moon actions and never shows it.
- **His sprites are numbered differently** from looking down on (looking
  down one earlier, then KEENONPLAT, dying as Keen 4's, from shooting on
  one further): see `Keen5Sprites`, from
  Omnispeak's `GFXCHUNK.CK5` (index = chunk − 102), checked in js-dos
  (level 1's first frame is the original's to the pixel, Keen included)
  and by eye in our screenshots of levels 1-3, 5, 9, 11-13 and 15.
- Riding a platform (KEENONPLAT), the Ampton and Korath knocking him off a
  pole, and landing on a fuse come in E4 and E5.

## Items and tiles (E3)

As in Keen 4 (docs/keen4/gameplay.md, "Items and tiles"), with one item
more:

| Info value | Item | Points | Sound name |
|---|---|---|---|
| 57-60 | the gems red, yellow, blue, green (items 0-3) | | `got_gem` |
| 61-66 | 100, 200, 500, 1000, 2000, 5000 points (items 4-9) | as named | `got_item` |
| 67 | the Keg o' Vitalin: a life (item 10) | | `got_extra_life` |
| 68 | a stunner (item 11): 5 charges, 8 on Easy | | `got_stunner` |
| 69 | a stunner, only while Keen has fewer than 5 charges | | |
| **70** | **the keycard (item 12)** | 0 | `got_keycard` |

Info 70 is item 70 − 58 = 12, not 70 − 57 (Omni `CK5_ScanInfoLayer`): the
game rules map it with `more_item_infos`. The keycard lies as a sprite in
the seven levels with a security door (2, 3, 5, 7, 9, 11, 13; files), one
each.

- **Vitalin** (misc 4, the drops): 100 make a life, as Keen 4's lifewater.
  Its splash has **four pictures of 8 tics** (Omni
  `CK_ACT_CentilifeNotify1-4`); Keen 4's lifewater has three of 10.
- Item tiles (misc 21-28) as in Keen 4: Keen 5 has 21-26 (points) and 28
  (stunner), no 27 (files).
- **The keycard and the gems are lost** at the end of every level and at
  every death (Omni `CK_GameLoop`): `Keen5Inventory.drop_gems`.

## Doors (E3)

| Tile | Up at it |
|---|---|
| A door (misc 2) | Keen walks to its spot (as Keen 4's) and goes in: 5 pictures of 9 tics, 64 units up each; safe for 110 tics; at the end he is put at the target in the info plane under him (x high byte, y low byte), one tile above it + 15 units, the view on him |
| A security door (misc 32), **without the keycard** | The sound `need_keycard` (14); he stands, and with up held looks up; nothing opens |
| A security door **with the keycard** | The card is used, the sound `open_security_door` (18); a door opener (`Keen5SecurityDoor`) at tile (Keen's middle column − 2, his bottom row − 4) puts in each of the 4 × 4 foreground tiles there the tile 4 before it, three times 15 tics apart (at 15, 30 and 45 tics from the start of the frame it is placed in); Keen steps in for 45 tics (64 units up) and then goes through as through a door (not safe for 110 tics: the original does not set it) |
| Target **0xB1B1** | The level is done (the exit); Keen is out of sight for the last 9 tics (`entered_door`) |
| Target **0x0000** | The level is done as the way to Korath III (`Keen5Keen.KORATH_ENDING`); for now it goes to the next level like the exit (E6: to the world map, on Korath III) |

Checked in the files (E3, `test_keen5_level`): every security door is two
tiles wide in the middle of a 4 × 4 door picture, its target is the exit
(0xB1B1), and after the three steps its two tiles are a plain door (misc
2: tiles 1741/1742 become 1729/1730). Level 1's exit is a plain door; the
other levels with an exit have a security door.

Not built yet: the teleport lightning when Keen starts into a door whose
info at his head row is 0 (research.md §4; E6), and the "pole-door
glitch" (it is kept by Keen 4's code as it is).

## The camera (E3)

Keen 4's rules (docs/keen4/gameplay.md, "The camera"), with **only one
kind of scroll block**: info 25, a row the view never scrolls over. Keen
5's info 26 is the arrival on Korath III on the world map (one, map 0),
not a column block.

## The score box (E3)

Keen 4's: the episode's own score box sprite (Keen 5: sprite 133) with
the digits in it, top left of the view, in 4:3 and widescreen; hidden on
a map that is only looked at.

## Pictures behind the levels (E3)

The machinery is Keen 4's (widescreen only, on by default), but Keen 5
names **no sky tiles yet**, so no level shows a picture and every level
looks as in the original (E10 makes Keen 5's own pictures).

## Watched in E3 (js-dos, the user's v1.4)

Headless js-dos as in D3 (docs/keen4/research.md, "Watched in D3"):
`KEEN5E`, a key, the title, New Game, Begin Normal Game; A+2 held with
Enter gives "Debug keys active", F10 held with W the warp ("Warp to which
level(1-18):"). Our 4:3 World viewport (320 × 200) compared pixel by
pixel:

- **Level 1's first view is the original's to the pixel**: two frames of
  the recording right after the fade-in equal ours with 0 pixels
  different (view, all three tile layers, Keen standing facing left, the
  score box). The other frames differ only where a creature moves (E4)
  or a tile animates.
- **Level 11 and the world map**: the same view and tiles; only the
  Little Ampton (E4), the score box (on the world map ours is hidden
  until E6) and an animated tile differ.
- The security door was not reached in js-dos: the levels' doors are far
  from Keen's start behind creatures, and a scripted walk did not get
  there quickly. Its rules are Omnispeak's and the files'
  (`test_keen5_level` opens every security door of the real levels).
