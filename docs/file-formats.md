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
| `KEEN1.EXE` | Game code; also tile properties and animations (milestone 3) | — |
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
world map have exactly one. The meaning of the other values follows in
milestones 4 and 5.

Special maps:

| Level | Contents |
|---|---|
| 80 | The world map of Mars |
| 81 | The ending: the flight from Mars to Earth |
| 90 | Backdrops for the title screen, intro and other non-game screens |
