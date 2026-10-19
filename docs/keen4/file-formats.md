# Keen 4 file formats

How CommanderPerfect will read the files of episode 4 ("Secret of the
Oracle"). Written in milestone D1 by the architect, from Omnispeak and
Commander Genius and **checked against the user's own files (v1.0)** with
scratch scripts (nothing from the files is in the repository). D2 builds
the readers and corrects this page where the code learns more. The facts
behind the numbers are in [research.md](research.md). This page holds
descriptions and numbers only, never data from the files.

Keen 4 is a **Galaxy** game. Not one of the Vorticon formats in
[../file-formats.md](../file-formats.md) is used again; only the EGA palette
and the idea of four bit planes carry over.

## Finding the files

`Keen4Files` (D2) looks in the same places as Keen 1-3 (`--data-dir-keen4=`,
`game_data/keen4` in the project, next to the executable, next to the macOS
app) for a folder that holds:

| File | Contents | Compression |
|---|---|---|
| `KEEN4E.EXE` (or `KEEN4.EXE`) | The program, with the headers of the other files inside (below). v1.0: **LZEXE 0.91**, 102,355 bytes, image 246,288 bytes. v1.4 (CG): not packed, 263,488 bytes, MZ header 0x2E00, image 0x3D740 | `DosExecutable` |
| `EGAGRAPH.CK4` | All graphics: fonts, pictures, sprites, 8×8 and 16×16 tiles, texts, demos | Huffman per chunk |
| `GAMEMAPS.CK4` | All 20 maps; starts with `TED5v1.0` | Carmack, then RLEW, per plane |
| `AUDIO.CK4` | PC speaker sounds, AdLib sounds, AdLib music | Huffman per chunk |
| `CONFIG.CK4`, `SAVEGAM?.CK4` | The original's settings and saves | not read |

External header files (`EGAHEAD.CK4`, `EGADICT.CK4`, `MAPHEAD.CK4`,
`AUDIOHED.CK4`, `AUDIODCT.CK4`) exist for mods and in Omnispeak's own data
folder. If present, use them; normally they are found in the EXE.

## Inside KEEN4E.EXE: the six headers

Offsets are "raw": in the unpacked image after the MZ header.

| Piece | v1.0 (files) | v1.4 (CG) | Recognised by |
|---|---|---|---|
| `AUDIOHED` | 0x1FB80, 163 × 32 bit | — | Offsets starting at 0, the last equal to the size of `AUDIO.CK4`. Entries 104-155 (digitised sounds, absent) hold one bogus value larger than entry 156: skip that block when checking the order |
| `EGAHEAD` | 0x1FE10, 4744 × 24 bit | 0x21080 | Offsets starting at 0, never decreasing apart from 0xFFFFFF (empty), the last equal to the size of `EGAGRAPH.CK4` |
| `MAPHEAD` | 0x235B0, 402 bytes | 0x24830 | The word 0xABCD, then 100 32-bit offsets into `GAMEMAPS.CK4` (0 = no map) |
| `TILEINFO` | 0x23742, 23,004 bytes | 0x249C2 | Directly after `MAPHEAD`; its size is 2 × 1296 + 7 × 2916 |
| `AUDIODCT` | 0x33FF6 | — | A Huffman tree (below); decompressing an audio chunk gives a sane length |
| `EGADICT` | 0x343F6 | 0x358F6 | A Huffman tree; chunk 0 decompresses to 4 × the number of pictures |

**A Huffman tree** is 255 nodes of two 16-bit values (0-bit, 1-bit); a
value below 256 is a byte (a leaf), 256 or more is node (value − 256). In a
valid tree every byte 0-255 is a leaf exactly once and every node 0-253 is
referenced at most once (node 254 is the root). In memory each tree takes
1024 bytes. In 1.0 exactly two places in the image pass this test.

Search by content first; the positions above are only the first place to
look. Never read program code. (The action records are data too, but they
hold code addresses: we do not read them; see research §3.)

## Huffman

Start at node 254; read the bits of each byte from the lowest up; follow the
0- or 1-value; at a leaf, write the byte and start again at node 254; stop
after the expanded length.

## EGAGRAPH.CK4: chunks

`EGAHEAD` has one offset per chunk and one for the end of the file. A chunk
starts with its 32-bit expanded length, then the Huffman data, **except**
the tile chunks (fixed lengths, no prefix): one chunk with all 8×8 tiles
(32 bytes each), one with all masked 8×8 tiles (40 each), and **one chunk
per 16×16 tile**: 128 bytes (four planes of 32) for a background tile, 160
bytes (the mask plane, then four planes) for a foreground tile. An empty
16×16 chunk (0xFFFFFF) is a tile that is never drawn.

| Range | v1.0 chunks (files) | v1.4 chunks (CG) | Count |
|---|---|---|---|
| Tables: pictures, masked pictures, sprites | 0, 1, 2 | 0, 1, 2 | 3 |
| Fonts | 3-5 | 3-5 | 3 |
| Pictures | 6-112 | 6-120 | **107** / 115 |
| Masked pictures | 113-115 | 121-123 | 3 |
| Sprites | 116-512 | 124-520 | 397 |
| 8×8 tiles, masked 8×8 tiles | 513, 514 | 521, 522 | 104, 20 tiles |
| 16×16 background tiles | 515-1810 | 523-1818 | 1296 |
| 16×16 foreground tiles | 1811-4726 | 1819-4734 | 2916 |
| Misc (text screens, intro tables) | 4727-4730 | 4735-4738 | 4 |
| Texts | 4731-4737 | 4739-4745 | 7 |
| Demos | 4738-4742 | 4746-4750 | 5 |

The range starts follow from the tables: pictures start at 6, then come the
counts read from chunks 0, 1 and 2 (bytes ÷ 4, ÷ 4, ÷ 18), then the tiles,
whose counts follow from `TILEINFO`'s size and from the chunks without a
length prefix. The code keeps **indices inside a range**, never chunk
numbers.

- **Picture tables** (chunks 0, 1): per picture its width in bytes (× 8
  pixels) and its height. A picture is stored plane by plane.
- **Sprite table** (chunk 2): 18 bytes per sprite: width in bytes, height,
  origin x and y, hit box xl, yl, xh, yh, shifts. Origin and hit box are in
  **global units (1/16 pixel)** (checked in 1.0). A sprite chunk is the mask
  plane and four colour planes.
- **Fonts**: height, 256 offsets, 256 widths, then one bit per pixel.
- **Misc**: two 80×25 text screens (an 8-byte header, then 4000 bytes of
  characters and colours) and two tables used by the intro credits.
- **Texts**: help, story, keys, about id, end, "level not available", how
  to order. Lines end in CR LF; commands start with `^`: `^P` new page,
  `^E` end, `^G<chunk>,<x>,<y>` a picture, `^T<chunk>,<x>,<y>,<tics>` a
  timed picture, `^C`/`^c<colour>`, `^L<x>,<y>`. The picture numbers are
  **chunk numbers of this version**; subtract the picture range start.
- **Demos**: a 16-bit map number (1, 9, 11, 15, 19 in 1.0), a 16-bit
  length, then the recorded input.

## GAMEMAPS.CK4 and MAPHEAD

A map header (at the offset from `MAPHEAD`):

| Field | Size |
|---|---|
| Offsets of the three planes | 3 × 32 bit |
| Compressed lengths of the three planes | 3 × 16 bit |
| Width, height (tiles) | 2 × 16 bit |
| Name | 16 bytes, NUL-padded |
| Signature | `!ID!` |

Each plane: a 16-bit length after Carmack, the Carmack data; that gives a
16-bit length after RLEW followed by the RLEW data; that gives width ×
height 16-bit values. All 20 maps of 1.0 decode exactly this way.

- **Carmack**: 16-bit words. 0xA7nn: copy nn words from a near offset (the
  next byte, counted back from the end of the output). 0xA8nn: copy nn words
  from a far offset (the next word, counted from the start of the output).
  nn = 0: a literal word with high byte 0xA7 or 0xA8, whose low byte is the
  next byte.
- **RLEW**: a word equal to the tag (0xABCD, from `MAPHEAD`) is followed by
  a count and a value. Our `RlewDecompressor` has a fixed tag (0xFEFE) and
  a 32-bit size: Galaxy gets its own small decoder.

The three planes:

1. **Background**: a 16×16 background tile (0-1295).
2. **Foreground**: a 16×16 foreground tile (0-2915); 0 is empty.
3. **Info**: 0 or a value that places Keen, an enemy, an item, a platform
   direction, a scroll block (25, 26), …; a value ≥ 0x100 is a target
   (x in the high byte, y in the low byte). On the world map: 0xC000 + n
   (entrance to level n), 0xD0nn and 0xF0nn (what changes when level nn is
   done). The full list is in [research.md](research.md), §6 and §8.

Maps in 1.0: 0 the world map, 1-17 the levels, 18 the Megarocket, 19 the
high-score screen.

## TILEINFO

Arrays, each as long as its kind of tile, in this order (Omnispeak's
`id_ti.c`, confirmed by the value ranges in 1.0):

| # | Background (1296 each) | Foreground (2916 each) |
|---|---|---|
| 1 | animation time (tics) | top |
| 2 | animation offset (signed: next tile = tile + offset) | right |
| 3 | | bottom |
| 4 | | left |
| 5 | | animation offset |
| 6 | | misc |
| 7 | | animation time |

- **Top / bottom**: 0 none, 1 flat, 2-7 slopes, 8-15 deadly (slope = value
  & 7), 17 pole hole.
- **Right / left**: 0 or 1 (a wall on that side).
- **Misc**: low 7 bits the special meaning (pole, door, deadly, drop,
  switches, gem holders, water, items …, research §4); bit 0x80 draws the
  tile **in front of sprites**.
- **Animation**: after the time in tics the tile becomes tile + offset,
  around a cycle.

## AUDIO.CK4

Each chunk: a 32-bit expanded length, then Huffman data (`AUDIODCT`).

| Chunks (1.0) | Contents |
|---|---|
| 0-51 | PC speaker sounds |
| 52-103 | AdLib sounds (the same 52 sounds) |
| 104-155 | digitised sounds: absent |
| 156-161 | the six songs |

- **PC speaker sound**: length (32 bit), priority (16 bit), then one byte
  per step at **140 Hz**: the timer divisor ÷ 60 (0 = silence). Our
  `SpeakerSynth` plays it after multiplying by 60.
- **AdLib sound**: length, priority, a 16-byte instrument (the registers of
  the two operators), an octave (block), then one note byte per step at
  140 Hz on one OPL2 channel.
- **Song**: a 16-bit length, then commands of 4 bytes (register, value,
  16-bit delay) at **560 Hz** for the OPL2 chip.
