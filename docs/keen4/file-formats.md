# Keen 4 file formats

How CommanderPerfect will read the files of episode 4 ("Secret of the
Oracle"). Written in milestone D1 by the architect, **before** any Keen 4
file was opened: no Keen 4 data was available in the cloud session (see
[research.md](research.md), §0). Everything here comes from Omnispeak and
Commander Genius and is to be confirmed in D2 against the real files; D2
replaces this page with what the files say (as C2 did for Keen 3). This page
holds descriptions and numbers only, never data from the files.

Keen 4 is a **Galaxy** game. Not one of the Vorticons formats in
[../file-formats.md](../file-formats.md) is used again; only the EGA palette
and the idea of "four bit planes" carry over.

## The files

| File | Contents | Compression |
|---|---|---|
| `KEEN4E.EXE` | The program. **Not packed** in v1.4 (Commander Genius: 263,488 bytes, an MZ header of 0x2E00 bytes and an image of 0x3D740 bytes). Holds the headers of the other files (below) | none (LZEXE or PKLITE in other releases: `DosExecutable` already unpacks LZEXE) |
| `EGAGRAPH.CK4` | All graphics: fonts, pictures, sprites, 8×8 and 16×16 tiles, texts, demos | Huffman per chunk |
| `GAMEMAPS.CK4` | All maps (world map = map 0, levels 1-18 and more) | Carmack, then RLEW per plane |
| `AUDIO.CK4` | PC speaker sounds, AdLib sounds and AdLib music | Huffman per chunk |
| `CONFIG.CK4`, `SAVEGAM?.CK4`, `GAMEMAPS`… | The original's settings and saves | not read |

The file check in D2 requires `KEEN4E.EXE`, `EGAGRAPH.CK4`, `GAMEMAPS.CK4`
and `AUDIO.CK4` (any case). The EXE may also be called `KEEN4.EXE` in some
releases (Commander Genius tries both); accept both.

External header files (`EGAHEAD.CK4`, `EGADICT.CK4`, `MAPHEAD.CK4`,
`AUDIOHED.CK4`, `AUDIODCT.CK4`) are used by mods and by Omnispeak's own
`data/keen4/` folder. If the player has them next to the game, read them; if
not (the normal case), find the same bytes inside the EXE.

## Inside KEEN4E.EXE: the five headers

Commander Genius knows these positions in the v1.4 image (the image starts
after the 0x2E00-byte MZ header):

| Piece | v1.4 image offset (CG) | Size | How to recognise it by content |
|---|---|---|---|
| `EGAHEAD` | 0x21080 | 4752 × 3 bytes | A run of 3-byte little-endian offsets, first 0, never decreasing (except the 0xFFFFFF of an empty chunk), the last one equal to the size of `EGAGRAPH.CK4` |
| `EGADICT` | 0x358F6 | 255 nodes × 4 bytes (1020; external files are 1024) | Every node is two 16-bit values; a value < 256 is a leaf byte, a value ≥ 256 is node (value − 256) < 255. Confirm by decompressing chunk 0 (the picture table) to exactly 4 × 115 bytes |
| `MAPHEAD` | 0x24830 | 2 + 100 × 4 = 402 bytes | The word 0xABCD (the RLEW tag), then 100 32-bit offsets into `GAMEMAPS.CK4`; each non-zero offset points at a level header whose name is printable and whose plane offsets lie inside the file |
| `TILEINFO` | 0x249C2 (= `MAPHEAD` + 402) | 23,004 bytes for 1296 + 2916 tiles | Follows `MAPHEAD` directly; its size follows from the tile counts |
| `AUDIOHED` | search | 163 × 4 bytes (Omnispeak's file: 652 bytes) | 32-bit offsets, first 0, never decreasing, the last one equal to the size of `AUDIO.CK4` (this is how Commander Genius finds it) |
| `AUDIODCT` | search | 255 nodes × 4 bytes | As `EGADICT`; confirm by decompressing a PC speaker sound with a sane length and priority |

Find all of them by content first and use the known offsets only as the
first place to look, as `Keen3Executable` does. Never read program code.

## EGAGRAPH.CK4 and the chunk layout

`EGAHEAD` has one 3-byte offset per chunk plus one at the end; 0xFFFFFF is
an empty chunk. Each chunk is Huffman-compressed with `EGADICT`: start at
node 254, read bits from the lowest bit of each byte up, follow `bit_0` or
`bit_1`, emit a byte at a leaf and start again at node 254.

A chunk starts with its 32-bit expanded length, **except** the tile chunks,
whose length is fixed: one chunk of 32 × n bytes for all 8×8 tiles, one of
40 × n for the masked 8×8 tiles, and **one chunk per 16×16 tile** (128 bytes
unmasked: 4 planes of 32 bytes; 160 bytes masked: the mask plane and then
4 planes). An empty 16×16 chunk is a tile that is never drawn.

Keen 4 v1.4 (Omnispeak's `GFXINFOE.CK4` and Commander Genius agree):

| Range | Chunks | Count |
|---|---|---|
| Picture table, masked picture table, sprite table | 0, 1, 2 | 3 |
| Fonts | 3-5 | 3 |
| Pictures (help screens, title, status, map flags …) | 6-120 | 115 |
| Masked pictures | 121-123 | 3 |
| Sprites | 124-520 | 397 |
| 8×8 tiles (one chunk), masked 8×8 tiles (one chunk) | 521, 522 | 104, 20 tiles |
| 16×16 background tiles | 523-1818 | 1296 |
| 16×16 masked foreground tiles | 1819-4734 | 2916 |
| Misc (end screen and the like) | 4735-4738 | 4 |
| Texts (help, story, …) | 4739-4745 | 7 |
| Demos | 4746-4750 | 5 |

The counts must come from the files (D2 derives them from the chunk sizes
and the tables, with these numbers as the check), never be hard-coded in
more than one place.

- **Picture table** (chunk 0): per picture its width in bytes (÷ 8 pixels)
  and its height, two 16-bit values. Pictures are stored plane by plane.
- **Sprite table** (chunk 2): per sprite 18 bytes: width in bytes, height,
  origin x and y, the hit box (x1, y1, x2, y2) and the number of shifts.
  Omnispeak treats the origin and the box in *global units* (1/16 pixel);
  D2 checks this. A sprite chunk is the mask plane and four colour planes.
  The hit box is the one the game uses for collisions: our actors take it
  from here, not from estimates.
- **Fonts**: a height, 256 offsets and 256 widths, then 1-bit glyphs.
- **Texts**: the help and story pages with their own mark-up (`^P` page,
  `^E` end, `^G` with a picture number and position, `^C` colour, `^L`
  position, …); read in D7.
- **Demos**: recorded key presses for the title loop.

## GAMEMAPS.CK4 and MAPHEAD

`GAMEMAPS.CK4` starts with `TED5v1.0`. `MAPHEAD` gives the RLEW tag and an
offset per map. A map header (38 bytes, then the signature `!ID!`):

| Field | Size |
|---|---|
| Offsets of the three planes | 3 × 32 bit |
| Compressed lengths of the three planes | 3 × 16 bit |
| Width, height (in tiles) | 2 × 16 bit |
| Name | 16 bytes, NUL-padded |

Each plane: a 16-bit Carmack length, the Carmack data, giving a 16-bit RLEW
length and the RLEW data, giving width × height 16-bit values.

- **Carmack**: words; a word 0xA7nn copies nn words from a near offset (one
  byte, counted back from the output), 0xA8nn copies nn words from a far
  offset (a word, counted from the start of the output); nn = 0 means a
  literal word with high byte 0xA7 or 0xA8 whose low byte follows.
- **RLEW**: a word equal to the tag (0xABCD) is followed by a count and a
  value.

The three planes:

1. **Background**: index of a 16×16 background tile (0-1295).
2. **Foreground**: index of a masked 16×16 tile (0-2915); 0 is empty.
3. **Info**: 0 or a number that places Keen, an enemy, an item spot, a
   platform path arrow, a scroll block (25 horizontal, 26 vertical) and so
   on; the list per value is in [research.md](research.md). On the world
   map the info plane also holds level entrances (0xC000 + level).

Map 0 is the world map ("Shadowlands"), maps 1-17 are the levels, map 18
is the Bean-with-Bacon Megarocket (Omnispeak's name list, which is the list
in the EXE). D2 lists the maps from the real file and checks for others.

## TILEINFO

Per tile, in arrays (each array as long as its tile kind):

| Background tiles (1296) | Foreground tiles (2916) |
|---|---|
| animation time (tics), next-tile offset (signed) | animation time, next-tile offset |
| | top, right, bottom, left (the collision and slope type of each side), misc |

- **Animation**: a tile with a time > 0 is replaced by tile + offset after
  that many tics; the cycle ends where it started. Both layers animate.
- **Top**: 0 none, 1 flat solid top, 2-7 slopes (which half, rising or
  falling), plus values for deadly or "sticky" tops; **bottom**: the same
  for ceilings; **left/right**: walls (and the value for a "door" on the
  map).
- **Misc**: the low 7 bits are the special behaviour (deadly, pole,
  item/point, door, switch, gem holder, climbable ledge, water, the
  council, …); the high bit (0x80) means **draw this tile in front of
  sprites**.

The exact values per number are in Omnispeak (`ck_phys.c`, `ck_keen.c`,
`ck4_misc.c`) and are listed for the developer in
[research.md](research.md), §4.

## AUDIO.CK4

`AUDIOHED` has a 32-bit offset per chunk; each chunk starts with its
expanded length and is Huffman-compressed with `AUDIODCT`. Keen 4 v1.4
(Omnispeak's `AUDINFOE.CK4`): **52 sounds**, chunks 0-51 the PC speaker
versions, 52-103 the AdLib versions, 104-155 the (absent) digitised slots,
**156-161 the music**.

- **PC speaker sound**: length (32 bit), priority (16 bit), then one byte
  per step at **140 Hz**; a byte is a PIT divisor ÷ 60 (0 = silence). This
  is not the Vorticons format (16-bit divisors), but the same idea as our
  `SpeakerSynth`.
- **AdLib sound**: length, priority, a 16-byte instrument (the two
  operators' registers), an octave/block, then one note byte per step at
  140 Hz on one OPL2 channel.
- **Music**: a 16-bit length, then IMF-style commands (register, value,
  16-bit delay) played at **560 Hz** on all OPL2 channels.

An OPL2 (YM3812) synthesiser is needed for the AdLib sounds and the music;
see [architecture.md](architecture.md), "Sound".
