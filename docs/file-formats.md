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
| `SOUNDS.CK1` | PC speaker sounds (milestone 6) | — |

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
What the values on the world map mean follows in milestone 5. See
`docs/enemies.md` for how the enemies behave.

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

Behaviors seen in Keen 1 (version 1.1). Values 1-21 are used by the engine;
22-24 are what the tiles look like and still need to be confirmed in
milestone 5.

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
| 22 | 435-438, 485-488 | Animated (light) switch? |
| 23 | 271 | Light switch? |
| 24 | 481-484, 494-497 | Teleporter? |
