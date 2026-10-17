# Keen 2 file formats

How CommanderPerfect reads the files of episode 2. Written in milestone B2
without the real Keen 2 files (Keen 2 is not shareware), on
[research.md](research.md); checked against the player's own files
(version 1.31) in B5.1. What that showed is listed at the end. Most formats are the same
as Keen 1's; those are described once, in [../file-formats.md](../file-formats.md).

## Finding the files

`Keen2Files` (`src/keen2/data/keen2_files.gd`) looks in the same places as
Keen 1, in this order:

1. the folder given with `--data-dir-keen2=PATH`
2. `game_data/keen2` in the project folder
3. `game_data/keen2` next to the executable
4. `game_data/keen2` next to the macOS app

The first folder that holds `KEEN2.EXE`, `EGAHEAD.CK2`, `EGALATCH.CK2` and
`EGASPRIT.CK2` (any upper or lower case) is used. It returns an ordinary
`GameFiles` with `extension = "CK2"`, so the shared decoders read it:
`level_numbers()` lists the `LEVELxx.CK2` files and `level_file(n)` names
them. Keen 1 keeps using `GameFiles.locate()`, which does exactly what it
did before (extension `CK1`, `game_data/keen1`, `--data-dir=`).

The game has no `SOUNDS.CK2`, `STORYTXT.CK2`, `HELPTEXT.CK2` or
`ENDTEXT.CK2`: those are inside `KEEN2.EXE` (below).

## The same as Keen 1

| File | Contents | Decoder |
|---|---|---|
| `EGAHEAD.CK2`, `EGALATCH.CK2`, `EGASPRIT.CK2` | Graphics: 689 tiles, 134 sprites, 18 bitmaps (standard header layout) | `EgaHeader`, `EgaGraphics.load_from(files, "CK2")` |
| `LEVEL01.CK2` … `LEVEL16.CK2` | The levels | `LevelData` |
| `LEVEL80.CK2` | The world map | `LevelData` |
| `LEVEL81.CK2` | Space: the ending and the Earth exploding | `LevelData` |
| `LEVEL90.CK2` | Title, story and high score backgrounds | `LevelData` |
| `FINALE.CK2` | The full-screen picture of the ending | `FinaleImage.load_from(files, "FINALE.CK2")` |
| `KEEN2.EXE` | LZEXE-packed (version 1.31) | `DosExecutable`, `LzexeDecompressor` |

`EgaHeader` has nothing that is tied to a Keen 1 version: it tries the
standard layout (counts from byte 16) and the Keen 1 v1.34 layout (from byte
22) and keeps the one that passes its plausibility check, so Keen 2's header
needs no change. The tile count comes from `EGAHEAD.CK2`, never from a
constant.

## Inside KEEN2.EXE

`Keen2Executable` (`src/keen2/data/keen2_executable.gd`) unpacks the EXE and
finds each piece **by its content**. The positions known for version 1.31
(raw offsets in the unpacked image, see research.md §1) are tried first, and
only used when the bytes there pass the same check as the search. Nothing is
read from the program code.

| Piece | v1.31 position | How it is recognised | Result |
|---|---|---|---|
| Sounds | 0x12730 | `SND\0`, then a u16 size at +4 that fits in the image, and a u16 entry count at +6 whose table fits in that size. The block is cut out and has the layout of `SOUNDS.CK1` | `sound_data()` → `SoundFile.parse()` |
| Tile properties | 0x17828 (1.31), 0x17938 (1.00) | Same shape check as Keen 1 (`TileProperties.find_in_image` with Keen 2's offsets, then a search of the whole image), for the tile count from `EGAHEAD.CK2` | `tile_properties(count)` |
| End text | 0x15840 | A text block (below) | `text(TextBlock.END_TEXT)` |
| Help | 0x15BC0 | A text block | `text(TextBlock.HELP)` |
| Previews | 0x163A0 | A text block | `text(TextBlock.PREVIEWS)` |
| Story | 0x16AC0 | A text block | `text(TextBlock.STORY)` |
| City names | 0x199AB | Eight zero-terminated strings of letters, spaces and dots ("Wash D.C."). At the known position any such names are accepted; the search wants the lengths 6, 5, 6, 8, 5, 4, 6, 9 (Commander Genius) after a zero byte | `city_names()` |
| `TO BE CONTINUED....` | 0x1A434 | The text `TO BE CONTINUED` | `to_be_continued()` |
| Vorticon Elder messages (B5) | 0x19FCC, 0x1A08C | Only at the known position: zero-terminated records of printable ASCII (and CR), one per line, each ending in LF, at least 32 bytes in all, with no printable byte right before the first. There is no search: not found means the Elder stays silent (no error) | `elder_message(index)` → lines; `find_elder_message(data, index)` |

| Status screen box (B6) | 0x1991C | Twelve line records (see below), the last without LF | `status_box_lines()` |
| Ending texts (B6) | 0x1A1A1, 0x1A253, 0x1A2F7, 0x1A333, 0x1A3C9, 0x1A429, 0x1A434 | Only at the known positions: line records; a text ends after a record without LF, or before the next known text or the record `finale.ck2` (0x1A2EC) | `ending_text(which)` |

**Line records.** The Elder messages, the status box and the ending texts
are runs of zero-terminated records, one per line. `line_records` reads
them from a start: it stops at a record that is not printable text, at the
start of another known text, or after a record without a line feed (which
is kept for the status box and the ending, and left out for the Elder
messages: there it is the prompt).

**Text blocks.** A text block is a run of text bytes (printable ASCII, CR,
LF, tab, the break mark 0x1F, and font pictures from 0x80 on) of at least 64
bytes, with at least one CR LF, ending in 0x1A, with no text byte right
before it. That is the format of the Keen 1 text files, so `text()` returns
the bytes up to and including the 0x1A, ready for `TextDocument.layout`.
When a block is not at its known position, all text blocks in the image are
listed; if there are exactly four, their order (end text, help, previews,
story, as in 1.31) tells which is which. Otherwise the block is reported as
not found.

**Help offset.** research.md lists 0x15DC0 (Commander Genius) against
0x15BC0 (Chocolate Keen). Commander Genius gives file offsets that include
the 512-byte EXE header (its story offsets also need −512), so 0x15DC0 −
0x200 = 0x15BC0: both sources agree, and the help ends at 0x1639F, right
before the previews (0x163A0).

**Elder messages.** The first message starts at 0x19FCC, right after the
five words of the points table (500, 100, 200, 1000, 5000 at 0x19FC2), the
second at 0x1A08C. As Keen 1's statue messages, every line is its own
zero-terminated record, padded with spaces and ending in LF: 8 lines for
the first message, 11 for the second. After the second comes `Press
ENTER:` (no LF), the prompt, which is not part of a message.
`elder_message_text` joins the line records from a message's start and
stops before a record without LF, a record that is not printable text, or
the other message's start; `elder_message` then splits at LF and drops CR,
trailing spaces and empty lines at the end. Which level shows which
message is in gameplay.md.

**Version.** `version` is "1.31" when the packed file is 58,335 bytes, or when
the unpacked image is 118,672 bytes or 118,672 − 512; "1.00" for 118,626 or
118,626 − 512; otherwise "unknown". Commander Genius's sizes include a
512-byte header: version 1.31's file is 58,335 bytes and its unpacked image
118,160 bytes. Nothing depends on the version: the content search works for
any.

**Failures.** Every finder returns −1 or an empty value when a piece is
missing; the accessors (`sounds()`, `text()`, …) also say so with
`push_error`. Nothing crashes on a damaged or foreign EXE.

## Viewing and exporting

- `godot --path . res://src/viewer/data_viewer.tscn -- --game=2` shows the
  Keen 2 tiles, sprites, bitmaps, font and levels; the status line says
  which version `KEEN2.EXE` is and which pieces were found in it.
- `godot --headless --path . --script res://tools/export_graphics.gd -- --game=2`
  writes the Keen 2 graphics to `exported/keen2/` (ignored by git).
- `godot --path . -- --game=2` (with or without `--level=N`) skips the start
  screen and opens the Keen 2 scene.

## Checked with the real files (B5.1, version 1.31)

- `KEEN2.EXE`: 58,335 bytes, LZEXE-packed; the unpacked image is 118,160
  bytes (118,672 − 512). Version 1.00 was not available.
- `EGAHEAD.CK2`: standard layout, 689 tiles, 134 sprites, 18 bitmaps (the
  third high score bitmap is called `SAVED`). The sprite names and
  collision boxes are in research.md §5.
- Sound block at 0x12730: 12,554 bytes (it ends at 0x1583A, just before
  the end text), 63 entries, 42 with a name: Keen 1's 41 and `EARTHPOW`.
- The four text blocks are at their known positions and end in 0x1A. The
  end text starts with `TO BE CONTINUED...` and ends `THE END (for
  now...)`; the previews text is the "PREVIEWS!" page; the story starts
  `COMMANDER KEEN in`.
- City names at 0x199AB: London, Cairo, Sydney, New York, Paris, Rome,
  Moscow, Wash D.C. (the lengths agree with Commander Genius).
- The status box text (0x1991C) is several records, one per line, like the
  Elder messages: `SCORE` / `EXTRA KEEN AT`, `KEENS` / `PISTOL`, `TARGETS
  SAVED` / `KEYS`, `PLEASE PRESS A KEY`.
- The ending texts follow the Elder messages as line records (ending part 1
  at 0x1A1A1, part 2, `finale.ck2`, part 3's pages), then `TO BE
  CONTINUED....` at 0x1A434.
- Tile properties at 0x17828: no floor types (no ice), behaviours 22-26 as
  in research.md §3; the tile numbers are listed there.
- The levels: research.md, "Checked with the real files".

Not checked: version 1.00 (its sizes and offsets), and the exact layout of
the status box and ending records (B6 reads them).
