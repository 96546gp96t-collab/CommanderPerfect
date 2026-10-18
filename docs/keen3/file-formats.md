# Keen 3 file formats

How CommanderPerfect reads the files of episode 3. Written in milestone C2
with the player's own files (version 1.00). Most formats are the same as
Keen 1's and Keen 2's; those are described once, in
[../file-formats.md](../file-formats.md) and
[../keen2/file-formats.md](../keen2/file-formats.md). The facts behind the
numbers are in [research.md](research.md). This page holds descriptions and
numbers only, never data from the files.

## Finding the files

`Keen3Files` (`src/keen3/data/keen3_files.gd`) looks in the same places as
Keen 1 and Keen 2, in this order:

1. the folder given with `--data-dir-keen3=PATH`
2. `game_data/keen3` in the project folder
3. `game_data/keen3` next to the executable
4. `game_data/keen3` next to the macOS app

The first folder that holds `KEEN3.EXE`, `EGAHEAD.CK3`, `EGALATCH.CK3` and
`EGASPRIT.CK3` (any upper or lower case) is used. It returns an ordinary
`GameFiles` with `extension = "CK3"`. The maps are levels 1-16, the world
map 80, the ending's hall 81 and the title 90.

## The same as Keen 1 and Keen 2

| File | Contents | Decoder |
|---|---|---|
| `EGAHEAD.CK3`, `EGALATCH.CK3`, `EGASPRIT.CK3` | Graphics: 624 tiles, 148 sprites, 14 bitmaps (standard header layout) | `EgaHeader`, `EgaGraphics.load_from(files, "CK3")` |
| `LEVEL01.CK3` … `LEVEL16.CK3`, `LEVEL80.CK3`, `LEVEL81.CK3`, `LEVEL90.CK3` | The maps | `LevelData` |
| `FINALE.CK3` | The full-screen picture of the ending | `FinaleImage.load_from(files, "FINALE.CK3")` |
| `KEEN3.EXE` | LZEXE-packed: 61,619 bytes on disk, an image of 127,086 bytes (1.00) | `DosExecutable`, `LzexeDecompressor` |

## Inside KEEN3.EXE

`Keen3Executable` (`src/keen3/data/keen3_executable.gd`) unpacks the EXE and
finds each piece **by its content**. The positions known for 1.00 (and, for
the texts and the tile table, 1.31 from Chocolate Keen) are tried first and
only used when the bytes there pass the same check as the search. The
generic searches of `Keen2Executable` (`find_sound_block`, `text_blocks`,
`text_end`, `message_lines`) are called, not copied or changed. Nothing is
read from the program code.

| Piece | 1.00 position | How it is recognised | Result |
|---|---|---|---|
| Sounds | 0x13BA0 | `SND\0` and a table that fits (Keen 2's search). The block ends after the data of its last sound (0x16604): the size word in its header (16,224) also covers the words up to the help text | `sound_data()` → `SoundFile.parse()`: 63 entries, 45 named |
| Tile properties | 0x199F8 (1.31: 0x198C8) | Keen 1's shape check, but each of the six planes is **715** entries long while there are 624 tiles: `TileProperties.find_in_image(image, 624, offsets, 715)`. Only the first 624 entries of each plane are checked and kept | `tile_properties(count)` |
| Help | 0x17B00 | A text block (Keen 2's rules); see below | `text(TextBlock.HELP)` |
| End text | 0x182D0 | A text block | `text(TextBlock.END_TEXT)` |
| Previews | 0x18610 | A text block | `text(TextBlock.PREVIEWS)` |
| Story | 0x18D00 | A text block | `text(TextBlock.STORY)` |
| Status box | 0x1BC38 | 11 line records right after a zero byte; all but the last end in a line feed; none is wider than 28 characters, the first and the last are exactly 28 | `status_box_lines()` |
| Points table | 0x1C1A9 | The five words 500, 100, 200, 1000, 5000 | `find_points_table()` |
| Mortimer's boxes | 0x1C1B3 | The 23 text records right after the points table, grouped by the box heights 1, 1, 1, 5, 5, 2, 4, 1, 3 | `mortimer_messages()`: nine boxes |
| Ending pages | before the finale name | The line records right before the record naming `FINALE.CK3` (lower case in the EXE): 11 lines, grouped 4, 3, 3, 1 | `ending_pages()` |
| The box over the finale | after the finale name | The record after the finale name: two lines | `the_end()` |
| The ship's messages | 0x1CF00 | Four messages of 4, 3, 4 and 4 line records right after a zero byte; the last line of each has no line feed; no line wider than 40 | `ship_messages()` |
| The line under a ship's message | right after them (0x1D0CE) | Two records: a line feed, nine spaces and the start of the prompt, then the word for a key; a third record has the word for a joystick button | `ship_prompt()` |
| High score names and place words | after the two `SCORES.` records | As in Keen 1 and 2: `ScoreTexts` reads them unchanged | `score_texts()` |

**Text blocks.** Keen 3's order is help, end text, previews, story (Keen 2:
end text first). The format is Keen 1's (CR LF, the break mark, 0x1A at the
end). `Keen2Executable.text_blocks` finds the four blocks but starts the
first one two bytes early: the words before the help text end in `0xFFFF`,
and bytes from 0x80 on count as font pictures. `Keen3Executable.text_blocks`
moves every start past such bytes, so a block never starts with a font
picture. A block is taken from a known position when a block starts there;
otherwise, when the image has exactly four blocks, their order tells which is
which.

**Searching.** The status box and the ship's messages are searched record
by record (every position after a zero byte) when the known position does
not hold them; in the player's image that takes about 20 ms. Mortimer's
boxes need no known position (they follow the points table), nor do the
ending's pages (they come before the finale name).

**Version.** `version` is "1.00" when the packed file is 61,619 bytes or the
image is 127,086 bytes (127,598 with a 512-byte header, Commander Genius's
number); "1.31" for a packed file of 61,599 bytes or an image of 127,104
(127,616 with the header); otherwise "unknown". Nothing depends on the
version. 1.31 could not be tested (the player has 1.00).

**Failures.** Every finder returns −1 or an empty value when a piece is
missing; `sounds()` and `text()` also say so with `push_error`. Nothing
crashes on a damaged or foreign EXE.

## Tile behaviours

The table has two behaviours that Keen 1 and 2 do not have: **27** (the
ankh) and **28** (a single charge). They are in `Keen3Behavior`
(`src/keen3/data/keen3_behavior.gd`), not in the shared
`TileProperties.Behavior` (which stays Keen 1's); the shared plausibility
check already allows them (up to 31).

## The world map's info layer

Checked in C2 (`tests/test_keen3_data.gd`): map 80 is 70x73 cells, Keen
starts at (44,47); every level 1-16 has an entrance (some cells carry
0x8000 + n, blocked until level n is done); 16 cells hold teleporters
(0x0Fsd, all on tile 134, 16 different slots); Messie's path has 252 cells
(0x2000), her weed 4 (0x2100), her landings 6 (0x2200); the ship is two
cells with value 20. What they do is in research.md §8.

## Viewing and exporting

- `godot --path . res://src/viewer/data_viewer.tscn -- --game=3` shows the
  Keen 3 tiles, sprites, bitmaps, font and maps; the status line says which
  version `KEEN3.EXE` is and which pieces were found in it.
- `godot --headless --path . --script res://tools/export_graphics.gd -- --game=3`
  writes the Keen 3 graphics to `exported/keen3/` (ignored by git).
- `godot --path . -- --game=3` (with or without `--level=N`) skips the start
  screen and opens the Keen 3 scene (in C2 a "coming soon" screen).
