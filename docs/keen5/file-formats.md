# Keen 5 file formats

How CommanderPerfect will read the files of episode 5 ("The Armageddon
Machine"). Written in milestone E1 by the architect, **checked against the
user's own files** with scratch scripts that ran the existing Galaxy
readers of Keen 4 (`src/galaxy/data/`) over them; nothing from the files
is in the repository. Keen 5 is a **Galaxy** game: every format of
[../keen4/file-formats.md](../keen4/file-formats.md) holds. This page
lists only what is different, and the numbers of episode 5. The facts
behind the numbers are in [research.md](research.md).

## Finding the files

The user uploaded their Keen 5 on 22-10-2026 (a zip). For this session it
was copied to `game_data/keen5/` (ignored by git).

| File | Size (files) | Note |
|---|---|---|
| `KEEN5E.EXE` | 106,417 bytes | **LZEXE 0.91** (`LZ91`); `DosExecutable` unpacks it to an image of **254,832 bytes** |
| `EGAGRAPH.CK5` | 573,664 bytes | 4,931 chunks |
| `GAMEMAPS.CK5` | 73,721 bytes | `TED5v1.0`; 16 map slots used (0-13 and 15) |
| `AUDIO.CK5` | 101,990 bytes | 206 chunks |
| `CONFIG.CK5` | 557 bytes | The original's settings; not read |
| `KEEN5.VIF` | 2,764 bytes | Not a data file of the game (a release's vendor information); not read |

`Keen5Files` (E2) needs `EGAGRAPH.CK5`, `GAMEMAPS.CK5`, `AUDIO.CK5` and
`KEEN5E.EXE` (or `KEEN5.EXE`), the same rules as `Keen4Files`.

### The version

The sign-on text that told Keen 4's version ("(v1.0)", "(v1.4)") is **not
in this program** (no "(v" in plain text nor in screen layout, files), so
`GalaxyExecutable.sign_on_version` answers "unknown". Signs that it is
**v1.4**: the help and end pages have the red frame of five pictures that
only Keen 4's v1.4 has (pictures 22-26 here, files), and the program
holds the v1.4 message "Combining EGA1.CK5 and EGA2.CK5 into
EGAGRAPH.CK5..." (files). The research (research.md §0) compares the sizes
with the versions Omnispeak and Commander Genius know; E2 puts the size in
`Keen5Episode.EXECUTABLE_SIZES` so the version is named.

## Inside KEEN5E.EXE: the six headers

Found by content by the **unchanged** `GalaxyHeaderSearch`, without any
known offset (files, E1, ~0.2 s). Raw image offsets:

| Piece | Offset (files) | Note |
|---|---|---|
| `AUDIOHED` | 0x21C80 (138,368) | 207 × 32 bit (206 chunks) |
| `EGAHEAD` | 0x21FC0 (139,200) | 4,932 × 24 bit (4,931 chunks) |
| `MAPHEAD` | 0x25990 (154,000) | Tag 0xABCD and 100 offsets |
| `TILEINFO` | 0x25B22 (154,402) | Right after `MAPHEAD`; 2 × 1512 + 7 × 2952 = 23,688 bytes |
| `AUDIODCT` | 0x35EC4 (220,868) | Huffman tree |
| `EGADICT` | 0x362C4 (221,892) | Huffman tree |

E2 writes these in `Keen5Episode.known_offsets`, so the search hits at
once; the content check stays.

## EGAGRAPH.CK5: chunks

What the unchanged `GalaxyChunkRanges` worked out (files), and where it is
**wrong for Keen 5**:

| Range | Chunks | Count | Note |
|---|---|---|---|
| Tables | 0-2 | 3 | |
| Fonts | 3-5 | 3 | As Keen 4 |
| Pictures | 6-98 | **93** | Help frame at pictures 22-26 (as Keen 4 v1.4's frame at 74) |
| Masked pictures | 99-101 | 3 | |
| Sprites | 102-447 | **346** | |
| 8×8 tiles | 448 | 104 | As Keen 4 |
| Masked 8×8 tiles | 449 | 20 | As Keen 4 |
| Background tiles | 450-1961 | **1512** (84 rows of 18) | `GalaxyChunkRanges` says **1440**: wrong, see below |
| Foreground tiles | 1962-4913 | **2952** (164 rows of 18) | `GalaxyChunkRanges` says 3025 |
| **Texts** | **4914-4920** | 7 | Help, controls, story, about id, two end texts, ordering info (files: their `^P` mark-up) |
| **Misc** | **4921-4925** | **5** | Binary: 4,037, 15,071, 5,891, 4,032 and 32,031 bytes (the last a full 320×200 screen) |
| Demos | 4926-4930 | 5 | 192-454 bytes each |

Two things the Keen 4 reader assumes do not hold for Keen 5:

1. **The border between the two tile sets.** The last background tiles
   (up to chunk 1961) are empty, and so is foreground tile 0 (chunk 1962;
   it always is). `GalaxyChunkRanges._back_tile_count` puts the border on
   the first row of 18 after the last non-empty background tile (1440).
   The right border is 1512: with 1512/2952 every `TILEINFO` table lines up
   (the left and right tables hold only 0 and 1, the first entry of every
   foreground table is 0); with 1440/3025 they do not (files). Fix in E2,
   additive: `GalaxyEpisode.back_tile_count` (0 = work it out as now);
   Keen 5 sets 1512. Keen 4's result does not change. (Done in E2.)
2. **The texts come before the misc chunks** (Keen 4: misc, texts,
   demos). Fix in E2, additive: `GalaxyEpisode.texts_before_misc`
   (false = as now). Keen 5: 7 texts, 5 misc chunks. (Done in E2.)

## GAMEMAPS.CK5

| Map | Name (files) | Size |
|---|---|---|
| 0 | Armageddon Mach (the world map) | 52 × 114 |
| 1 | Ion Vent System | 58 × 88 |
| 2 | Security Center | 72 × 70 |
| 3 | DefTunnel Vlook | 204 × 24 |
| 4 | Energy Flow Sys | 70 × 74 |
| 5 | DefTunnel Burrh | 200 × 24 |
| 6 | Reg Control Ctr | 70 × 70 |
| 7 | DefTunnel Sorra | 200 × 20 |
| 8 | Neutrino Burst | 70 × 70 |
| 9 | DefTunnel Teln | 208 × 26 |
| 10 | Brownian Motion | 70 × 74 |
| 11 | GravDamping Hub | 70 × 70 |
| 12 | QE Dynamo | 80 × 80 |
| 13 | Korath III Base | 42 × 250 |
| 14 | (empty slot) | |
| 15 | HighScores | 24 × 17 |

The info plane uses the same kinds of values as Keen 4 (research.md §6
lists them): small numbers for objects, 0xC0nn for the entrances on the
world map (0xC001-0xC00D: 13 levels), 0xD0nn and 0xF0nn on the world map
(13 × 0xF0nn), and in the levels values of 0x100 and more that are not
objects (the research says which: targets, the 0xB1B1 pair in most
levels).

## AUDIO.CK5

206 chunks (files): **64 PC speaker sounds** (0-63), **64 AdLib sounds**
(64-127), 64 empty digitised slots (128-191), and **14 songs** (192-205,
4-17 KB each). Keen 4 has 52 + 52 + 52 + 6. The readers take the counts
from the episode (E9).

## Texts in KEEN5E.EXE

Found by their shape in E2 (`Keen5Episode`; raw image offsets of v1.4, only
tried first: every run is also found without them, tested in
`tests/test_keen5_data.gd`). Nothing of the texts is in the repository;
the code knows only their numbers of lines or characters.

| Run | Offset (v1.4) | Shape | What |
|---|---|---|---|
| Story | 0x1FDE0 | one record of 37 lines | the title loop's story (`message_shapes`) |
| Level names | 0x20040 | 16 names, then 16 entry texts | maps 0-15, also the empty slot 14 (the Megarocket); every entry text ends with its name, the last "...theHigh Scores" (sic) |
| `game` | 0x3053E | lengths 31, 4, 30, 33, 22, 39, 23, 9, 18, 34, 48, 10 | a memory error, "DEMO", **the arrival on Korath III** (record 2, two lines), the demo recorder's three texts, the death box (three lines, "Exit to Armageddon"), two memory errors, "One moment". No "Game Over!" text: Keen 5 shows a picture |
| `cheat` | 0x30881 | lengths 70, 6, 3 | the B+A+T box, "PAUSED", the drive prompt (as Keen 4) |
| `status` | 0x308D3 | lengths 8, 5, 5, 7, 5, 4, 6, 4, 4, 4, 5, 7 | the status window: location, score, extra, **keycard**, level, the three difficulties, keys, ammo, lives, drops (no "rescued", no wetsuit) |
| `fuse` | 0x31BFB | lengths 36, 69 | the Korath III fuse's message (2 lines), then the one of the four elevator fuses (4 lines). By lengths: the line counts 2, 4 match an earlier place too |
| High scores | 0x33D56 | 8 records of 64 bytes | as Keen 4 (`GalaxyHighScores.find_defaults`, found by shape too); all 10,000, extra number 0 |

Not looked for yet (the milestones that need them find them the same way):
the menus' texts, Paddle War's ("KEEN:", "COMP:"), the debug texts.

## Checked in E2

- **The tile border** (`GalaxyEpisode.back_tile_count` = 1512, given by
  `Keen5Episode`): the exported tile sets show the last drawn background
  row (80), four empty rows (1440-1511), and a foreground set that starts
  with the empty tile 0 and the info icons, as Keen 4's. With 1512/2952
  every side wall in `TILEINFO` is 0 or 1; 123 animated background tiles,
  415 animated foreground tiles, 962 drawn in front of the sprites.
- **Texts before the misc chunks** (`GalaxyEpisode.texts_before_misc`):
  the seven texts (chunks 4914-4920) start with the `^P` page mark-up; the
  five misc chunks expand to 4,008, 15,044, 5,864, 4,008 and 32,000 bytes
  (the last a whole 320×200 screen in four planes); the five demos play
  maps 1, 3, 10, 11 and 15.
- **The version** by the program's size: 106,417 bytes is 1.4
  (`Keen5Episode.EXECUTABLE_SIZES`; also CG's unpacked 1.0, 262,176).
- **Keen's sprites** are Keen 4's numbers: 6 standing right, 7 walking
  right (the icon), 14 standing left, 15 walking left (seen by eye).
- Loading (unpacking, headers, ranges) takes ~75 ms; the six headers
  without the known places ~85 ms.
