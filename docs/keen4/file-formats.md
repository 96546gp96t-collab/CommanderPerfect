# Keen 4 file formats

How CommanderPerfect reads the files of episode 4 ("Secret of the
Oracle"). Written in milestone D1 by the architect, from Omnispeak and
Commander Genius and **checked against the user's own files (v1.0)** with
scratch scripts (nothing from the files is in the repository); D13
checked everything again in the user's **shareware v1.4** (marked "D13"). D2 built
the readers (`src/galaxy/data/`, `src/keen4/data/`) and corrected this page
where the code learned more (marked "D2"). The facts
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
| `KEEN4E.EXE` (or `KEEN4.EXE`) | The program, with the headers of the other files inside (below). v1.0: **LZEXE 0.91**, 102,355 bytes, image 246,288 bytes. v1.4 (CG): not packed, 263,488 bytes, MZ header 0x2E00, image 0x3D740. The shareware v1.4 (D13): LZEXE, 105,108 bytes, the same image of 251,712 bytes (= 0x3D740) | `DosExecutable` |
| `EGAGRAPH.CK4` | All graphics: fonts, pictures, sprites, 8×8 and 16×16 tiles, texts, demos. v1.0 487,332 bytes, v1.4 520,581 | Huffman per chunk |
| `GAMEMAPS.CK4` | All 20 maps; starts with `TED5v1.0` | Carmack, then RLEW, per plane |
| `AUDIO.CK4` | PC speaker sounds, AdLib sounds, AdLib music | Huffman per chunk |
| `CONFIG.CK4`, `SAVEGAM?.CK4` | The original's settings and saves | not read |

D13: `GAMEMAPS.CK4` (99,040 bytes) and `AUDIO.CK4` (33,325 bytes) are
**byte for byte the same** in v1.0 and v1.4; so are TILEINFO, the random
numbers and every text we read from the EXE. Only the program and
`EGAGRAPH.CK4` differ (above and below).

External header files (`EGAHEAD.CK4`, `EGADICT.CK4`, `MAPHEAD.CK4`,
`AUDIOHED.CK4`, `AUDIODCT.CK4`) exist for mods and in Omnispeak's own data
folder. If present, they are used (`GalaxyHeaders`); normally the pieces
are found in the EXE. `MAPHEAD.CK4` holds the tag, the 100 offsets and the
tile information after them, as in the EXE. `Keen4Files` needs
`EGAGRAPH.CK4`, `GAMEMAPS.CK4`, `AUDIO.CK4` and `KEEN4E.EXE` or
`KEEN4.EXE` (`KEEN4E.EXE` is taken when both are there).

## Inside KEEN4E.EXE: the six headers

Offsets are "raw": in the unpacked image after the MZ header.

| Piece | v1.0 (files) | v1.4 (files, D13) | Recognised by |
|---|---|---|---|
| `AUDIOHED` | 0x1FB80, 163 × 32 bit | 0x20DF0 | Offsets starting at 0, the last equal to the size of `AUDIO.CK4`. Entries 104-155 (digitised sounds, absent) hold one bogus value larger than entry 156: skip that block when checking the order |
| `EGAHEAD` | 0x1FE10, 4744 × 24 bit | 0x21080, 4752 × 24 bit (CG's place) | Offsets starting at 0, never decreasing apart from 0xFFFFFF (empty), the last equal to the size of `EGAGRAPH.CK4` |
| `MAPHEAD` | 0x235B0, 402 bytes | 0x24830 (CG) | The word 0xABCD, then 100 32-bit offsets into `GAMEMAPS.CK4` (0 = no map) |
| `TILEINFO` | 0x23742, 23,004 bytes | 0x249C2 (CG), the same bytes | Directly after `MAPHEAD`; its size is 2 × 1296 + 7 × 2916 |
| `AUDIODCT` | 0x33FF6 | 0x354F6 | A Huffman tree (below); decompressing an audio chunk gives a sane length |
| `EGADICT` | 0x343F6 | 0x358F6 (CG) | A Huffman tree; chunk 0 decompresses to 4 × the number of pictures |

**A Huffman tree** is 255 nodes of two 16-bit values (0-bit, 1-bit); a
value below 256 is a byte (a leaf), 256 or more is node (value − 256). In a
valid tree every byte 0-255 is a leaf exactly once and every node 0-253 is
referenced at most once (node 254 is the root). In memory each tree takes
1024 bytes. In 1.0 exactly two places in the image pass this test.

Search by content first; the positions above are only the first place to
look. Never read program code. (The action records are data too, but they
hold code addresses: we do not read them; see research §3.)

How `GalaxyHeaderSearch` does it (D2):

- **Offset tables**: first the known places; then every place where the
  data file's size is stored as an entry (3 or 4 bytes, little-endian),
  walking back over entries that are at most that size (or 0xFFFFFF) to
  the 0 that starts the table. A table passes when it starts with 0, ends
  with the size, has at least 8 entries, and never goes down except for
  **one block of equal entries larger than the ones after them** (the
  AUDIOHED gap). Such entries count as empty chunks; every other chunk
  ends where the next non-empty one starts (`without_bogus`).
- **MAPHEAD**: the known places, then the place that holds the offset of
  the first map header in GAMEMAPS (found by its `!ID!`), minus the 2-byte
  tag. It passes when every non-zero slot (and slot 0) points at a header
  with `!ID!` 38 bytes in.
- **TILEINFO**: always right after MAPHEAD; its length follows from the
  tile counts (below).
- **The dictionaries**: the known places that hold a complete tree; when
  one is still missing, the whole image is scanned (about 0.1 s in
  GDScript). A tree is EGADICT when it expands the first three EGAGRAPH
  chunks to their stored lengths, reading all but at most 8 of their bytes;
  AUDIODCT likewise with AUDIO. One small chunk can fit a wrong tree by
  chance; three in a row do not.
- In 1.0 the known places hit at once (the whole load, LZEXE included,
  takes ~70 ms); without them the search finds the same six places in
  ~0.2 s. D13: the same for v1.4 (~80 ms with its places known, ~150 ms
  when the two audio pieces had to be searched).

## Huffman

Start at node 254; read the bits of each byte from the lowest up; follow the
0- or 1-value; at a leaf, write the byte and start again at node 254; stop
after the expanded length.

A chunk is not always exactly as long as its Huffman data (D2, 1.0): of
the chunks with a length, 459 are exact, 65 one byte longer, 5 four or five
bytes longer; of the tile chunks 2382 exact, 485 one byte longer, one four
bytes longer. So "expands its length reading at most its own bytes, and
at most 8 fewer" is the test, never "exactly".

## EGAGRAPH.CK4: chunks

`EGAHEAD` has one offset per chunk and one for the end of the file. A chunk
starts with its 32-bit expanded length, then the Huffman data, **except**
the tile chunks (fixed lengths, no prefix): one chunk with all 8×8 tiles
(32 bytes each), one with all masked 8×8 tiles (40 each), and **one chunk
per 16×16 tile**: 128 bytes (four planes of 32) for a background tile, 160
bytes (the mask plane, then four planes) for a foreground tile. An empty
16×16 chunk (0xFFFFFF) is a tile that is never drawn. (D13: foreground
tiles 1-88 are empty in 1.0 but hold pictures in 1.4; no map uses them.
Every other tile and every sprite decodes to the same picture in both.)

| Range | v1.0 chunks (files) | v1.4 chunks (CG; files, D13) | Count |
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

The range starts follow from the tables (`GalaxyChunkRanges`, D2): after
the three tables come the fonts (their number, 3, from the episode),
then the counts read from chunks 0, 1 and 2 (bytes ÷ 4, ÷ 4, ÷ 18), then
one chunk of 8×8 tiles and one of masked 8×8 tiles. At the end of the file
come the episode's misc chunks (4), texts (7) and demos (5). Everything in
between is 16×16 tiles:

- **8×8 counts**: expand the whole chunk (until its stored end) and divide
  by 32 (40 for masked): the padding bits give less than a tile extra
  (1.0: 3336 bytes → 104, 809 → 20).
- **Background or foreground**: a background tile holds 128 bytes, a
  foreground tile 160. Expanding 160 bytes from a background tile's chunk
  reads past its end (true for all 1296 in 1.0), so the first foreground
  tile is found by halving. Empty chunks next to the border could belong to
  either set; the border is then put on a whole row of TED5's tile sheet
  (18 tiles; Keen 4's 1296 and 2916, Keen 5's and 6's sets are all
  multiples of 18). In 1.0 the last background tile is not empty, so this
  does not matter there.
- `TILEINFO`'s size then follows: 2 × 1296 + 7 × 2916 = 23,004.

The code keeps **indices inside a range**, never chunk numbers.

- **Picture tables** (chunks 0, 1): per picture its width in bytes (× 8
  pixels) and its height. A picture is stored plane by plane, in the
  order **blue, green, red, intensity** (D2: checked by eye in 1.0, the
  title, the help pictures and the cards come out in their colours).
- **Masked pictures, sprites, foreground tiles, masked 8×8 tiles**: the
  **mask plane first** (a set bit is see-through), then the four colour
  planes in the same order (D2, checked by eye in 1.0).
- **Sprite table** (chunk 2): 18 bytes per sprite (signed 16-bit): width in
  bytes, height, origin x and y, hit box xl, yl, xh, yh, shifts. Origin and
  hit box are in **global units (1/16 pixel)** and both relative to the
  object's position: the picture is drawn at **position + origin** (D2:
  sprite 10 of 1.0 has origin y 32 and box y 48-496 in a 29-pixel picture,
  so the box ends at the picture's bottom row; the standing Keen's feet).
  The data viewer draws the box this way.
- **Sprite order** (D4): the 397 sprites of 1.0 are in the order of
  Omnispeak's v1.4 list (`GFXCHUNK.CK4`, chunk − 124): Keen standing
  right 6 and left 14, running 7-10 / 15-18, jumping 11-13 / 19-21, … the
  stunner shot 50-53, its hit 54-55, the items 103-128, the score box 129,
  Keen showing the moon 395-396 (checked on a sheet of all sprites;
  `Keen4Sprites` names them). The hit box changes from frame to frame
  (Keen's pogo sprites start 64 or 128 units lower than his standing one).
  D7, the world map (seen in the original's recordings): the map Keen
  130-155 (three per direction, walking 1, walking 2, standing, in the
  order W, E, N, S, SE, SW, NW, NE, then waving 154-155; box 0-240 square),
  swimming 156-171 (two per direction: N, E, S, W, NE, SE, SW, NW; box
  32-208), on the Foot 172-173 (40 × 27), the flag flipping 174-178,
  falling 179-180 and waving 181-184.
- **8×8 tiles in the score box** (D4, Omni CK_UpdateScoreBox): the digits
  '0'-'9' are unmasked 8×8 tiles 42-51 (character code − 6), tile 41 is the
  dim "8" of an unused place; the original draws them into the SCOREBOX
  sprite (88 × 32 pixels in 1.0): the score at (8, 4), the lives at
  (24, 20), the charges at (64, 20).
- **Fonts**: height (16 bit), 256 offsets (16 bit, from the start of the
  chunk), 256 widths (bytes), then the pixels: per character `height` rows
  of ⌈width ÷ 8⌉ bytes, the leftmost pixel in the highest bit. Font 0 is
  the menu font, font 1 a small one, font 2 large (D2, 1.0).
- **Misc** (D8, 1.0; Omni's 1.4 names): 0 the ordering text screen, 1
  and 2 the two words of the intro credits, 3 the "out of memory" text
  screen. A text screen is an 8-byte header, then 4000 bytes of characters
  and colours (80 × 25). An intro word (`GalaxyIntroBitmap`) is a 16-bit
  height (200) and width (1.0: 1664 and 668 pixels), 200 16-bit offsets
  (one per row, from the start of the chunk), then per row 16-bit run
  lengths, dark and light in turn starting with dark, ended by 0xFFFF; every
  row of 1.0's second word starts with a dark run of 20.
- **Texts** (D8, 1.0's order; D13: v1.4 has the same order): 0 the
  ComputerWrist help, 1 the story, 2 the keys ("The keys to excitement"),
  3 about Id, 4 the end, 5 "not in the demo version", 6 how to order. In
  v1.4 texts 0-3 and 6 differ (other colours, no `^G` of the page bar,
  pages split elsewhere: 15, 21, 9, 20 and 2 pages for the help's topics
  where v1.0 has 13, 21, 9, 18, 2); the end (4) and text 5 are the same. Lines end in CR LF; commands start with
  `^` (`GalaxyTextPages`, `GalaxyPageLayout`):
  - `^P` a new page (the rest of the line is skipped), `^E` the end;
  - `^G y,x,chunk` a picture (**y first**), its x rounded down to 8;
  - `^T y,x,chunk,tics` a picture after a pause (the page so far is shown
    meanwhile);
  - `^L y,x` the next word's line (rounded to the 10-pixel lines) and x;
  - `^C` / `^c` and one hex digit: the text colour (the EGA colour
    itself: 1.0 on light grey, before any `^C` dark grey (8); 1.4 on red
    (4), before any `^C` yellow (14); D13 saw `^cB` light cyan on red, so
    it is not ORed with the red);
  - `^B y,x,width,height,colour` a bar in the background colour (the end
    uses it to wipe a line).
  The picture numbers are **chunk numbers of this version**; subtract the
  picture range start (6 in 1.0 and 1.4).
  A translation of a text (`GalaxyTexts`, `languages/<code>/keen4.txt`,
  name `keen4.text.<chunk>`) is the whole text with the same commands in
  the same order: the game keeps the commands of the player's own text
  (pictures, places, colours) and takes only the words between them. A
  release whose text has other commands (1.4's help, 0-3 and 6) shows that
  text in English; the end (4) is the same in both. Keen 5 works the same
  way (`keen5.text.<chunk>`).
- **Pictures by place** (D8, D13): pictures 0-73 counted from the start
  have the same places in 1.0 and 1.4, and counted from the end the last
  33 (1-33) are the same pictures. 1.4 puts **eight pictures in between**
  (74-81; Omni PIC_BORDERTOP … PIC_H_KEEN6PIC): the page frame's top (320
  × 8), left and right (8 × 192), bottom with the help's bar (304 × 24)
  and plain bottom (304 × 8) (`GalaxyPageFrame`), a bar (288 × 8) and
  two big pictures (304 × 176, 304 × 152) of the order text. Places from
  the start: 0 the help menu (136 × 184), 5 the help's "PAGE / ESC BACKS
  OUT" bar (96 × 16 in 1.0; an 8 × 8 dummy in 1.4, whose bar is part of
  the frame), 39 the pointing hand, 41 and 42 the end's dim and bright
  arrow (16 × 16 in 1.0, 16 × 8 in 1.4, drawn at the same place). Of 0-73,
  1.4 draws 0-5, 14-22, 37, 39, 41, 42 and 73 differently (for the red
  pages). Counted from the end: 17-14 the four intro credits, 13 the
  story's picture, 12 the title picture (both 320 × 200).
- **The pages of 1.4** (D13, seen in the shareware v1.4; Omni
  PageLayout, ShowHelp): filled with red (4); the frame's top at (0, 0),
  sides at (0, 8) and (312, 8); a help page has the bar at (8, 176) and
  "pg n of m" at (218, 186) in light red (12), the help's menu and the end
  pages the plain bottom at (8, 192). The text keeps 1.0's lines (18 of
  10 pixels from y 10, x 10-310). With this, our help menu, the first page
  of every topic and all 16 end pages equal the original's frames (0
  pixels differ).
- **Demos** (D8): a 16-bit map number (1, 9, 11, 15, 19 in 1.0 and 1.4), a 16-bit
  length in bytes, then pairs of bytes: how many logic frames, and what is
  held (bits 0-1 up/down + 1, bits 2-3 left/right + 1, bit 4 jump, bit 5
  pogo). 1.0's demos are 744, 687, 749, 645 and 271 frames of 3 tics;
  1.4's first demo is another recording (812 frames), the other four are
  the same bytes.

### Decoding time (D2, GDScript, this machine)

Decoding is lazy (`GalaxyGraphics` decodes a picture, sprite or tile when
asked and keeps it). Loading (unpacking the EXE, the headers, the ranges)
takes ~70 ms; one sprite under 1 ms (the start screen's icon). Everything:
the 107 pictures ~0.27 s, masked pictures and 397 sprites ~0.19 s, the 1296
background tiles ~0.19 s, the 2916 foreground tiles ~0.32 s, the rest
(8×8 tiles, fonts, texts, demos, misc) ~0.05 s: **about 1 s for all of
EGAGRAPH**. All 20 maps expand in ~45 ms. No thread is needed.

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

D2: the far offset of a Carmack copy counts words from the start of the
Carmack output, which includes the RLEW length word; with that, all 20
maps of 1.0 expand to exactly width × height words. The names in GAMEMAPS
are the editor's ("DescendentsCave"); the names the game shows are in the
EXE (below).

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
  around a cycle. (D2: the order above holds; in 1.0 an animation offset
  leads to another animated tile for 311 of the 333 foreground tiles with
  an offset; the other 22, and the gem holders' offset 18, have no time.
  Every animated background tile's offset stays inside the set.)

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
  16-bit delay) at **560 Hz** for the OPL2 chip. (D2: in 1.0 the length is
  the chunk's size minus 2 for all six songs.)

`GalaxyAudioFile` (D2) gives the expanded chunks as bytes; the bogus
AUDIOHED block (104-155) is empty, chunk 103 ends where 156 starts.

What D9 learned (files, 1.0; Omni `id_sd.c` for how they are played):

- **Lengths**: a PC chunk is 6 + length + 1 bytes, an AdLib chunk 23 +
  length + 1 (a trailing byte); only `length` steps are played. The PC
  and AdLib versions of a sound have the same priority (all 52); their
  lengths differ for some sounds (the jump: 45 and 45 steps, the shot 54
  and 67, the death 283 and 283).
- **The AdLib instrument** (16 bytes): modulator and carrier of register
  0x20, 0x40, 0x60, 0x80 and 0xE0 (in that order, modulator first), then
  the connection byte (feedback and connection, register 0xC0), then five
  bytes Muse used. The original writes the ten operator bytes to channel 0
  (operators at offsets 0 and 3) and **not** the connection byte (Omni);
  the files have connection bytes 0-15, mostly with the additive bit set,
  so writing it would change most sounds. The block byte goes to register
  0xB0 as (block << 2) | 0x20 with every note; the note is the F-number's
  low byte (0xA0), its top two bits stay 0; a 0 note turns the key off.
- **The songs** never write register 0x01: the original's reset (all
  registers 0, then 0x01 = 0x20) enables the waveforms, and songs 0 and 1
  use waveform 3. They start with (0, 0, 0), (0xBD, 0, 0), (8, 0, 0), write
  0xBD only as 0 (no rhythm mode, shallow tremolo and vibrato), use all
  nine channels (0-8, also the sounds' channel 0), feedback/connection
  values 0-14 (channel 0: 6) and key-scale levels 0-3; some operators have
  tremolo or vibrato set. Their last delay is 0.

| Song | Bytes | Commands | Delay sum (ticks) | One round at 560.7 Hz |
|---|---|---|---|---|
| 0 | 3734 | 933 | 11688 | 20.85 s |
| 1 | 9906 | 2476 | 29941 | 53.40 s |
| 2 | 2742 | 685 | 9057 | 16.15 s |
| 3 | 14422 | 3605 | 25384 | 45.27 s |
| 4 | 7202 | 1800 | 18354 | 32.74 s |
| 5 | 2282 | 570 | 7187 | 12.82 s |

The rendered sounds and songs are cached in `user://keen4/cache/`
(`GalaxySoundCache`): one `<sha-256>.pcm` per chunk, two little-endian
32-bit numbers (the loop's first and last sample, −1 for a sound) and then
16-bit mono samples at 49716 Hz. Never shipped: they are made from the
player's files.

## Texts and tables in KEEN4E.EXE (D2)

All found by **shape**, never by their words (`GalaxyExecutable`,
`GalaxyExeTexts`); the known 1.0 places are tried first.

| Piece | 1.0 position (1.4, D13) | How it is found |
|---|---|---|
| Version | the sign-on screen | A text-mode screen: each character followed by its colour byte, so "(v1.0)" has its letters two bytes apart. The search reads "(v" + digits and a dot + ")" two (or one) bytes apart. Without it: the size of the EXE (1.0: 102,355; 1.4: 263,488) |
| Random numbers | 0x1DA32 (1.4: 0x1ED32) | 256 bytes starting 0, 8, 109, 220, 222, 241, 149 (Omni `US_RndT`) |
| Level names | 0x1DD40 (1.4: 0x1F040) | 19 zero-terminated records (maps 0-18), each on a 16-byte boundary (zeros in between), then 19 "Keen enters …" texts. The test: every entry text, newlines read as spaces, ends with its level's name (1.0: also map 3 "the The …"). Names may hold a newline (maps 13 and 18) |
| The janitor | 0x1E280 (1.4: 0x1F580) | Right after the entry texts: 4 records with 4, 3, 2 and 2 lines: his first two boxes, Keen's reply, his last box (D6: the fifth box has no text, only Keen's picture with the cross face; seen in the original) |
| Council, Lindsey, wetsuit | 0x2F5BC (1.4: 0x3094C) | 17 records, one zero apart, with 4, 4, 1, 3, 1, 1, 2, 2, 2, 1, 3, 1, 3, 2, 4, 5, 5 lines: Lindsey's two hints, Keen's two thanks, "Princess Lindsey says:", Keen without and with the wetsuit, Keen's eight answers to the council members, the member's message under water and on land. The first record follows code bytes, not a zero |

| Status window (D7) | 0x2E115 (1.4: 0x2F487) | 14 one-line records, one zero apart, of 8, 5, 5, 7, 5, 4, 6, 4, 4, 4, 5, 5, 7 and 3 characters: location, score, extra, rescued, level, the three difficulties, keys, ammo, lives, drops, the wetsuit and its absence. One-line labels say nothing by their lines, so this run is found by its **lengths** (`GalaxyEpisode.text_lengths`, `GalaxyExeTexts.find_by_lengths`) |
| Game texts (D7) | 0x2DD4C (1.4: 0x2F0BE) | 13 records of 10, 31, 31, 4, 33, 22, 39, 23, 9, 19, 34, 48 and 10 characters: "game over", two memory errors, the demo texts, the three lines of the box after a death (0-based 7, 8, 9), two memory errors, and the box when Keen leaves the world map (12). Found by its lengths too |

| Story (D8) | 0x1DB40 (1.4: 0x1EE40) | One record of 30 lines (the title loop's story), found by that shape |
| Cheat box (D8) | 0x2E0C3 (1.4: 0x2F435) | 3 records of 70, 6 and 3 characters: the B+A+T box, "PAUSED", the drive prompt; right before the status labels |
| High scores (D8) | 0x31E9C (1.4: 0x33234) | 8 records of 64 bytes: a name of 58 bytes (printable, then zeros), a 32-bit score, a 16-bit number (council members rescued). Found by that shape (`GalaxyHighScores.find_defaults`); the same records are kept in `CONFIG.CK4` after its 6-byte header |

A record is a run of printable characters and newlines ending in a zero.
The shapes and lengths are Keen 4's numbers (`Keen4Episode`); the Galaxy
code knows none of them. Not searched yet (for later milestones): the
menus' texts. "I can't swim!" is in the council
block (record 5).

D6, the order in the council block as the boxes use it (seen in the
original, the same order as Omnispeak's strings): 0 the hint of level 7
(the wetsuit), 1 the hint of level 5 (the Pyramid of the Forbidden), 2 and
3 Keen's thanks for them, 4 "Princess Lindsey says:", 5 "I can't swim!"
(the world map, D7), 6 Keen with the wetsuit, 7-14 Keen's answers to the
first … eighth council member, 15 the member under water (level 17), 16
the member on land.

## The pictures of the message boxes (D6)

The last eleven pictures of the picture range are the same in 1.0 and
1.4 (Omni `GFXCHUNK.CK4`: PIC_ORACLE … PIC_COUNTDOWN0, 110-120 in 1.4;
1.0: pictures 96-106 of 107, looked at in the scratchpad): counted from
the end, 11 the council elder (48 × 64), 10 Keen talking (48 × 64), 9 Keen
with his thumb up (48 × 64), 8 Keen's cross face (24 × 24), 7 Lindsey
(48 × 64), 6-1 the count-down of the "Keen enters …" box (one 48 × 64 and
five 24 × 24; D7). `Keen4Messages` takes them by that place, never by
chunk number. The window's frame is the masked 8×8 tiles 0-8 (corners,
edges); the text is font 0, the menu font.

## The status window (D7)

Drawn from the 8×8 tiles, not from a picture (Omni CK_DrawStatusWindow;
compared with the original: no pixel differs): the frame is the
**unmasked** 8×8 tiles 54-62 (54, 55, 56 the top, 57 and 59 the sides, 60,
61, 62 the bottom), the digits the tiles 41 (blank) and 42-51 ('0'-'9', as
the score box), a rescued member tile 40, the four gems 36-39, and the
window's own "press a key" sign the tiles 72-91 (two rows of ten). The
two masked pictures 1 and 2 (1.0 and 1.4 have three: 0 the wrist-watch
screen, 1 the arm at the window's left, 24 × 96, 2 the strap above it, 48 ×
16) hang it from the top of the screen. The labels are printed with XOR in
the menu font (colour 15): dark grey on the grey inside, black on the
white bars.
