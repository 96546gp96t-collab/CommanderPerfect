# Keen 2 file formats

How CommanderPerfect reads the files of episode 2. Written in milestone B2
**without the real Keen 2 files** (Keen 2 is not shareware): everything here
is built on [research.md](research.md) and checked only with hand-made test
data and with the Keen 1 files under Keen 2 names. What still has to be
checked against real files is listed at the end. Most formats are the same
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
| `EGAHEAD.CK2`, `EGALATCH.CK2`, `EGASPRIT.CK2` | Graphics: 689 tiles, 134 sprites (expected) | `EgaHeader`, `EgaGraphics.load_from(files, "CK2")` |
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
| City names | 0x199AB | Eight zero-terminated strings of letters and spaces. At the known position any such names are accepted; the search wants the lengths 6, 5, 6, 8, 5, 4, 6, 9 (Commander Genius) after a zero byte | `city_names()` |
| `TO BE CONTINUED....` | 0x1A434 | The text `TO BE CONTINUED` | `to_be_continued()` |
| Vorticon Elder messages (B5) | 0x19FCC, 0x1A08C | Only at the known position: a zero-terminated record of at least 32 bytes, all printable ASCII, LF or CR, with no printable byte right before it. There is no search: not found means the Elder stays silent (no error) | `elder_message(index)` → lines; `find_elder_message(data, index)` |

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

**Elder messages.** research.md §1 places the first message at 0x19FCC (191
bytes, right after the five words of the points table) and the second right
after it at 0x1A08C (275 bytes). Each is taken as one record with line
breaks inside; `elder_message` splits it at LF, drops CR, trailing spaces
and empty lines at the end. Whether the records really hold LF line breaks
(rather than one record per line, as Keen 1's statue messages do) is not
known without the files; a message made of several records would fail the
check and show no window. Which level shows which message is in
gameplay.md.

**Version.** `version` is "1.31" when the packed file is 58,335 bytes, or when
the unpacked image is 118,672 bytes or 118,672 − 512; "1.00" for 118,626 or
118,626 − 512; otherwise "unknown". Commander Genius's sizes include a header
(for Keen 1 v1.1 its 100,274 is our 99,762 + 512), so the second reading is
the likely one. Nothing depends on the version: the content search works for
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

## Not yet checked (needs the real files)

- The tile count (689) and sprite count (134), and that `EGAHEAD.CK2` uses
  the standard layout.
- The size of `KEEN2.EXE` and of its unpacked image, so the version table can
  be fixed (research.md open question 1), and whether version 1.00 is
  LZEXE-packed too.
- That the sound block is at 0x12730, holds 42 entries, and that `EARTHPOW`
  is the only new name (open question 3).
- That the four text blocks end in 0x1A and are at the positions above, what
  the previews text is for (open question 9).
- The city names, especially the 9-character one for level 16 (open
  question 6), and their lengths.
- The tile properties at 0x17828: behaviour values 22-26, floor types, the
  tile numbers of items and switches (open question 4).
- The Vorticon Elder messages (B5): that they are at 0x19FCC and 0x1A08C,
  one record each with LF line breaks, and which levels show them. The
  three ending texts (positions in research.md §1) are not read yet; they
  follow in a later milestone (`Keen2Texts`).
- The sound block's name for the Earth exploding (`EARTHPOW`, compared
  without case and with any suffix by `Keen2Sounds`).
- The level contents: info values, bridges, the Elder levels (open questions
  5, 7, 8, 10).
