# Keen 1 file formats

How CommanderPerfect reads the original data files of episode 1. All numbers
are little-endian. Offsets are in bytes unless noted otherwise.

Sources: the [ModdingWiki](https://moddingwiki.shikadi.net/) community
documentation, and the Commander Genius source code as a reference for the
details. No code was copied; the decoders in `src/data/` were written from
these descriptions and checked against the shareware files (version 1.1).

## Overview

| File | Contents | Decoder |
|---|---|---|
| `EGAHEAD.CK1` | Table of contents for all graphics | `EgaHeader` |
| `EGALATCH.CK1` | Font, 16x16 tiles, full-screen bitmaps (4 planes) | `EgaGraphics` |
| `EGASPRIT.CK1` | Sprites (4 color planes + 1 mask plane) | `EgaGraphics` |
| `LEVELxx.CK1` | Levels 1-16 and special maps (see below) | `LevelData` |
| `KEEN1.EXE` | Game code; also the tile properties (only these are read) | `DosExecutable`, `LzexeDecompressor`, `TileProperties` |
| `FINALE.CK1` | Picture of Keen's house at the end of the game | `FinaleImage` |
| `ENDTEXT.CK1` | Text shown after the ending | `TextDocument` |
| `STORYTXT.CK1`, `HELPTEXT.CK1` | The story and the help texts (milestone 6), same format | `TextDocument` |
| `SOUNDS.CK1` | PC speaker sounds | `SoundFile` |

## EGA planar graphics

EGA stores images in four bit planes. One byte holds one bit of eight pixels,
leftmost pixel in the highest bit. The color index (0-15) of a pixel is:

```
index = plane0_bit * 1 + plane1_bit * 2 + plane2_bit * 4 + plane3_bit * 8
```

The planes are stored one after another: plane 1 starts at `plane_size`,
plane 2 at `2 * plane_size`, and so on. Within a plane an image is stored row
by row, `width / 8` bytes per row. Sprites have a fifth plane, the mask: a set
bit means the pixel is transparent.

The colors are the 16 standard EGA colors (see `EgaPalette`).

## EGAHEAD.CK1

| Offset | Type | Meaning |
|---|---|---|
| 0 | u32 | Size of one plane in EGALATCH |
| 4 | u32 | Size of one plane in EGASPRIT |
| 8 | u32 | Position of the bitmap table in this file |
| 12 | u32 | Position of the sprite table in this file |
| 16 | u16 + u32 | Font: number of 8x8 characters, offset in latch plane |
| 22 | u16 + u32 | Unused ("screen tiles") |
| 28 | u16 + u32 | Number of 16x16 tiles, offset in latch plane |
| 34 | u16 + u32 | Number of bitmaps, offset in latch plane |
| 40 | u16 + u32 | Number of sprites, offset in sprite plane |
| 46 | u16 | Compression flags |

Keen 1 **version 1.34** has six extra bytes before the counts, so they start
at offset 22 instead of 16. `EgaHeader` tries both layouts and keeps the one
where the font ends exactly where the tiles begin.

The compression flags are not used: if a data file is exactly
`plane_size * planes` bytes long it is uncompressed, otherwise it is LZW.

**Bitmap table** — 16 bytes per bitmap:

| Offset | Type | Meaning |
|---|---|---|
| 0 | u16 | Width in bytes (pixels / 8) |
| 2 | u16 | Height in pixels |
| 4 | u32 | Offset, relative to the bitmap offset in the header |
| 8 | char[8] | Name, e.g. `TITLE` |

**Sprite table** — 128 bytes per sprite; only the first 32 are used:

| Offset | Type | Meaning |
|---|---|---|
| 0 | u16 | Width in bytes (pixels / 8) |
| 2 | u16 | Height in pixels |
| 4 | u16 | Extra byte offset |
| 6 | u16 | Location in 16-byte units; data starts at `location * 16 + extra` |
| 8 | s16 x 4 | Hitbox left, top, right, bottom (fixed point, 8 fraction bits) |
| 16 | char[12] | Name, e.g. `KEENWALKR1` |

## LZW compression (EGALATCH, EGASPRIT)

| Offset | Type | Meaning |
|---|---|---|
| 0 | u32 | Decompressed size |
| 4 | u16 | Maximum code width in bits (12) |
| 6 | … | Codes, most-significant bit first |

Codes start 9 bits wide. 0-255 are single bytes, 256 means error, 257 means
end of data, and new dictionary entries start at 258. When the number of
dictionary entries reaches `2^width - 1`, the width grows by one bit, up to
the maximum.

## Levels (LEVELxx.CK1)

The file is RLEW-compressed: a u32 decompressed size, then 16-bit words. The
word `0xFEFE` is followed by a count and a value ("repeat value count times").

The decompressed words:

| Word | Meaning |
|---|---|
| 0 | Width in cells |
| 1 | Height in cells |
| 2 | Number of layers (2) |
| 7 | Size of one layer in bytes |
| 16… | Tile layer: tile number per cell, row by row |
| 16 + layer size / 2 … | Info layer: what starts in each cell (0 = nothing) |

**Border.** Every map is surrounded by a border of two cells (tile 144 in the
levels, 155 on the world map). The original never scrolls the border into
view: the 24-cell-wide levels are exactly 20 cells, or 320 pixels, wide inside
it. CommanderPerfect therefore only draws the cells inside the border.

**Info layer.** The value 255 marks where Keen starts. Every level and the
world map have exactly one. In levels 1-16 the other values are the enemies,
each starting with the top left of its sprite at the top left of the cell:

| Value | Enemy |
|---|---|
| 1 | Yorp |
| 2 | Garg |
| 3 | Vorticon (the commander in level 16) |
| 4 | Butler robot |
| 5 | Tank robot |
| 6 | Ice cannon, fires up and to the right |
| 7 | Ice cannon, fires straight up |
| 8 | Ice cannon, fires straight down |
| 9 | Ice cannon, fires up and to the left |
| 10 | Chain holding the stone above the Vorticon commander (level 16) |

Level 2 has two cells with 23 and level 12 a stretch of large values that
look like leftover data; the game ignores them, and so does CommanderPerfect.
See `docs/enemies.md` for how the enemies behave.

**Info layer of the world map** (level 80), see `MapInfo` and
`docs/world-map.md`:

| Value | Meaning |
|---|---|
| 1-16 | Entrance of that level. Large entrances cover 2x2 cells, all with the same value |
| `0x8000` + 1-16 | The same, and the cell blocks the way until the level is done (the right half of level 1, the top half of level 7) |
| 20 | Keen's ship (two cells) |
| 38, 41, 46 | Teleporters (34-46 are all treated as teleporters; only these three are on the map) |
| 255 | Where Keen starts |

Tiles of the world map that the game uses: 77 is the "done" sign for an
entrance of one cell, 78-81 the four quarters (top left, top right, bottom
left, bottom right) of the big one. The teleporters are tile 99 (on the ice)
and 325 (on red ground); while one is used it flickers through tiles 342-345
or 338-341. The pictures of the ship parts in the "missing parts" message
are tiles 321-324.

Special maps:

| Level | Contents |
|---|---|
| 80 | The world map of Mars |
| 81 | The ending: the flight from Mars to Earth |
| 90 | Backdrops for the title screen, intro and other non-game screens |

## KEEN1.EXE

Only data tables are read from the executable; its code is never looked at.

**Unpacking.** The MZ header says how many 16-byte paragraphs it occupies
(u16 at offset 8); the program image follows. The shareware version 1.1 is
packed with LZEXE 0.91 (signature `LZ91` at offset 0x1C). The packed image is
a stream of 16-bit control words and plain bytes. Control bits are read from
the current word, lowest bit first; as soon as its sixteenth bit has been
taken, the next word is read, before any bytes that follow it.

| Bits | Bytes that follow | Meaning |
|---|---|---|
| `1` | `b` | Literal byte `b` |
| `0 0 x y` | `d` | Copy `2 + 2x + y` bytes from `d - 256` bytes back |
| `0 1` | `lo hi` | Distance `(lo \| (hi & 0xF8) << 5 \| 0xE000) - 0x10000`, length `(hi & 7) + 2` |
| `0 1` with `hi & 7 = 0` | `lo hi n` | `n = 0`: end of data; `n = 1`: segment marker, no output; otherwise length `n + 1` |

Version 1.1 unpacks to 99,762 bytes. The relocation table that follows the
packed image is not needed for reading data and is ignored.

**Tile properties.** Six arrays of one 16-bit word per tile (611 tiles in
Keen 1), one after another. In the unpacked image of version 1.1 they start
at 0x131F8; the ModdingWiki gives 0x130F8 for version 1.31. `TileProperties`
tries those positions first and otherwise searches for the first place where
all values are plausible (frame counts 1-8, behaviors -2 to 31, sides 0-3).

| Array | Meaning |
|---|---|
| 0 | Animation: number of frames, 1 = not animated |
| 1 | Behavior (signed), see below |
| 2 | Top: 0 = open, 1 = solid floor, 2 = slippery floor, 3 = ice |
| 3 | Right side solid (1) or not (0) |
| 4 | Bottom side solid |
| 5 | Left side solid |

The sides are independent: a one-way platform only has a solid top. A tile's
"left" side stops a sprite that walks into it from the left, and so on.

Animated tiles: consecutive tiles with the same frame count n form groups of
n tiles, counted from the start of the run (Keen 1's runs are not aligned to
multiples of n: 83-86 is one group, 208-219 are three). A level can place any
frame of a group; the animation then starts from there.

Behaviors seen in Keen 1 (version 1.1).

| Value | Tiles | Meaning |
|---|---|---|
| -2 | — | Masked: drawn in front through a mask (not used in Keen 1) |
| -1 | 32 tiles, e.g. 288-301, 408-423 | Foreground: drawn in front of Keen |
| 0 | most | Nothing |
| 1 | fire, spikes, water, icicles | Deadly |
| 2-5 | 173-174, 195-200 | Doors: yellow, red, green, blue, two tiles each (their sides are not marked solid; the game blocks them) |
| 6-10 | 201-205 | Points: pizza 500, lollipop 100, soda 200, book 1000, teddy bear 5000 |
| 11-14 | 221-248 | Ship parts: joystick, battery, vacuum cleaner, whiskey (animated) |
| 15 | 175 | Raygun |
| 16 | 176 | Pogo stick |
| 17 | 159 | Exit |
| 18-21 | 190-193 | Keycards: yellow, red, green, blue (every level with a door has the keycard of its color) |
| 22 | 435-438, 485-488 | Yorp and Garg statues that show a message (below) |
| 23 | 271 | Looks like a light switch; no level of Keen 1 uses it |
| 24 | 481-484, 494-497 | Teleporter: only in level 13; it takes Keen out of the level to a secret place on the map |

**Points table.** Right before the statue messages (below) are five 16-bit
words: 500, 100, 200, 1000, 5000. These are the points of behaviors 6-10,
which confirms the values in `docs/enemies.md`. CommanderPerfect does not read
them; it uses the same numbers as constants.

**Statue messages.** The texts of the Yorp and Garg statues (behavior 22) are
a run of zero-terminated lines, each about 20 characters padded with spaces
and ending in a newline, followed directly by the string `Press ENTER:`. The
first line has no zero in front of it (the points table is there). Every
message starts with a two-line header whose second line ends in a colon, then
a blank line; the messages have 4 to 7 lines. They belong, in order, to the
levels with a statue: 2, 6, 9, 10, 11 (the Garg statue), 12 and 15.
`HintTexts` reads them from the player's own executable at runtime. After
its message a statue stops glowing: Yorp statues (485-488) become tile 315,
the Garg statue (435-438) tile 434.

**Texts of the ship and the ending.** Like the statue messages, these are
zero-terminated records; a message of several lines is one record per line
ending in a newline, and its last line has no newline (`ExeStrings`,
`EndingTexts`):

- `Your ship is missing\nthese parts:\n\n\n\n\n` is one record, followed
  by `    GO GET THEM!\n`. The empty lines leave room for the pictures of the
  missing parts.
- Keen returning to his ship is four `line\n` records that end right before
  the file name `FINALE.CK1` (which the game opens at that point).
- After that name come the seven messages of the conversation at Keen's
  house, then `TO BE CONTINUED....`. The parents' question and Keen's answer
  ("Aw, Mom, can't I keep him?") are stored as one message.

**Teleporter destinations.** The game keeps them as pixel coordinates inside
its code, not in a data table, so CommanderPerfect does not read them. The
Commander Genius documentation of these coordinates shows that every one
points exactly at another teleporter on the map; `MapSession` therefore
names the destination by the info value of that teleporter (see
`docs/world-map.md`).

## FINALE.CK1

A full-screen EGA picture (320x200), run-length coded:

| Offset | Type | Meaning |
|---|---|---|
| 0 | u32 | Size of the four planes together after decompression (4 x 8192) |
| 4 | … | Run-length code |

The code is a command byte n, then:

| n | Meaning |
|---|---|
| high bit set | `(n & 0x7F) + 1` bytes follow and are copied as they are |
| high bit clear | The next byte is repeated `n + 3` times |

The result is the four colour planes one after another, 8192 bytes each. Each
holds the picture row by row (40 bytes per row, 200 rows); the remaining 192
bytes of a plane are padding. The bitmaps `WINDON` and `WINDOFF` (56x32) are
drawn on top at (80, 0) to switch the light in the bedroom window on and off.

## ENDTEXT.CK1 (and STORYTXT.CK1, HELPTEXT.CK1)

Plain text written for an 80-column screen, lines ending in CR LF:

| Mark | Meaning |
|---|---|
| `~` at the start of a line | Center the line |
| `0x1F` at the end of a line | Break the line here |
| `0x1A` | End of the text |

Other lines run on into the next one: CommanderPerfect joins them into
paragraphs and wraps them again for the 38 columns that fit in a window. An
empty line ends a paragraph. Lines that fit are kept as they are, spaces
included, because some are laid out by hand. Bytes from 0x80 on are
characters of the game font: `0x97 0x98` over `0x99 0x9A` draw a little
Keen face next to "Commander Keen says:".

## SOUNDS.CK1

All sounds of the game for the PC speaker. Little-endian, in three parts.

Header (16 bytes):

| Offset | Size | Meaning |
|---|---|---|
| 0 | 4 | `SND\0` |
| 4 | u16 | Size of the file (8898 in version 1.1) |
| 6 | u16 | Number of entries in the table (63) |
| 8 | u16 | Unknown (60) |
| 10 | 6 | Zero |

Table, one entry of 16 bytes per sound:

| Offset | Size | Meaning |
|---|---|---|
| 0 | u16 | Offset of the sound data in the file |
| 2 | u8 | Priority: a new sound only cuts off the one that is playing if its priority is at least as high |
| 3 | u8 | Unknown: 8 for the real sounds, 1 for the empty slots |
| 4 | 12 | Name, zero-padded, for example `KEENJUMPSND` (three are lower case: `vortscream`, `keencicle`, `keensleft`) |

Version 1.1 has 41 real sounds, followed by 22 slots called `__UnNamed__`
that hold a single tone. The data of a sound is a list of u16 values ending
with `0xFFFF`. Each value lasts one tick of the game's 140 Hz sound timer.
0 is silence; any other value is the divisor for the PC's timer chip
(1193182 Hz), so the speaker plays a square wave of 1193182 / value Hz.
Values go from 60 (about 20 kHz, inaudible) to about 10000 (120 Hz).

The 140 Hz rate comes from the public documentation of the format (the
"inverse frequency" sound format); it still has to be checked by ear
against the original. Which sound belongs to which event is in
[sounds.md](sounds.md).

