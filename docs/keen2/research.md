# Keen 2 ("The Earth Explodes"): what differs from Keen 1

Research notes for adding episode 2 to CommanderPerfect, collected in
milestone B1 (see [roadmap.md](roadmap.md)). They are written for the
developer of milestones B2-B10: look here before searching Commander Genius
again. When a fact is checked against the real files or the original game,
update it here and drop the "uncertain" mark. Facts that end up as code get
their final, short description in [file-formats.md](file-formats.md) or
[gameplay.md](gameplay.md) (to be written in B2 and later).

Every fact names its source and is marked:

- **certain (CG)**: the Commander Genius source says so (used as
  documentation only; nothing was copied). This means "CG does this", which
  is not always what the original does. CG has known bugs and guesses.
- **certain (Choco)**: a *data* fact (file size, offset, name list) from
  Chocolate Keen's `src/episodes/episode2.h` / `src/engine/engine_loader.c`
  (github.com/jamesfmackenzie/chocolatekeen). Chocolate Keen is a
  reconstruction of the original code, so only its offset/name/size tables
  were looked at, never its behaviour code. Whether this source may be used
  at all is an open decision for the user (see `PROGRESS.md`); until then
  every "(Choco)" fact must be checked against the real files before code
  relies on it.
- **uncertain**: inferred, contradictory between sources, or memory. Check it
  against the real files or the original game.

CG paths are relative to `src/` of the CG checkout (commit 58a3c4f,
"Getting ready for SDL3"). Speeds are in CG units: 1 tile = 512, 1 pixel = 32
(`CSF = 9`, `STC = 5`, `engine/core/scrollingplane.h:13-15`). That is the same
"n/32 pixel per tick" unit as `docs/keen-physics.md`. CG runs the Vorticon
games at 60 logic ticks per second (`GsKit/base/GsTimer.h:28`,
`DEFAULT_LPS_VORTICON = 60`). "Raw offset" means an offset in the program
image *after* the MZ header, the same frame of reference as the Keen 1
offsets in `docs/file-formats.md` (CG's ep1 v1.1 tile offset 0x131F8 matches
ours).

---

## 1. Files and versions

### File list

| Keen 1 | Keen 2 | Notes |
|---|---|---|
| `KEEN1.EXE` | `KEEN2.EXE` | certain (CG `fileio/CExeFile.cpp:164-165`, the name is `keen<ep>.exe`) |
| `EGAHEAD.CK1`, `EGALATCH.CK1`, `EGASPRIT.CK1` | `EGAHEAD.CK2`, `EGALATCH.CK2`, `EGASPRIT.CK2` | Same format. certain (CG `CEGAGraphicsVort.cpp:48-49,148`, `CEGALatch.cpp:160`) |
| `LEVELxx.CK1` | `LEVEL01.CK2` … `LEVEL16.CK2`, `LEVEL80.CK2`, `LEVEL81.CK2`, `LEVEL90.CK2` | Same RLEW format, same loader. certain (CG `CVorticonMapLoader.cpp:128-130,175-189`) |
| `FINALE.CK1` | `FINALE.CK2` | Same RLE full-screen picture. certain (CG `finale/CEndingEp2.cpp:174`) |
| `SOUNDS.CK1` | **none**: sounds are inside `KEEN2.EXE` | certain (CG `CAudioVorticon.cpp:40-56`, "In Episode 2 and 3 this an usual case") |
| `ENDTEXT.CK1` | **none**: the end text is inside `KEEN2.EXE` (raw 0x15840) | certain (Choco `CVort2_END_TEXT_OFFSET`). CG's ep2 ending never shows an end text (`finale/CEndingEp2.cpp:34-46`) |
| `STORYTXT.CK1` | **none**: story inside the EXE (raw 0x16AC0) | certain (CG `CStory.cpp:55-72`, Choco `CVort2_STORY_TEXT_OFFSET`) |
| `HELPTEXT.CK1` | **none**: help inside the EXE | certain (CG `CHelp.cpp:55-73`). Offset disagrees: CG 0x15DC0-0x1659F, Choco 0x15BC0 |
| — | **new**: a "previews" text inside the EXE (raw 0x163A0) | certain (Choco `CVort2_PREVIEWS_TEXT_OFFSET`) |
| `SCORES.CK1`, `SAVEn.CK1`, `CTLPANEL.CK1` | same with `.CK2` | Written by the game. uncertain (not checked in CG) |

There is **no shareware Keen 2**. Episodes 2 and 3 were registered-only, so
`tools/get_shareware.sh` cannot fetch them. Tests that need Keen 2 data must
skip when `game_data/keen2/` is missing (uncertain about the legal side, but
no free source is known).

### Versions and how to detect them

| Version | `KEEN2.EXE` on disk | Unpacked size (header + image) | Tile table (raw) | Source |
|---|---|---|---|---|
| 1.00 | ? | 118,626 | 0x17938 | certain (CG `CExeFile.cpp:33,361-362`, `CTileLoader.cpp:72`) |
| 1.31 | **58,335 bytes, LZEXE-packed** | 118,672 | 0x17828 | certain (Choco `engine_loader.c:135-136`, CG `CExeFile.cpp:34,363-364`, `CTileLoader.cpp:73`) |

- **CG's detection**: CG unpacks the EXE (LZEXE first, then PKLITE, otherwise
  it uses it as is), then takes the size of the result (header + image) and
  looks it up in a table (`CExeFile.cpp:235-255,350-401`). For KEEN1 v1.1 that
  is 100,274 = 99,762 (our image size) + 512, so the "unpacked size" above
  includes a 512-byte header if the same holds for KEEN2 (uncertain). CG also
  has a CRC check for v1.31 (`0x94E464B4`, `CExeFile.cpp:438-442`). It is not
  enforced.
- **Chocolate Keen's detection** accepts only v1.31: either the packed size
  58,335 or the unpacked size 118,672 (`engine_loader.c:135-137,196-217`).
- Keen 1 v1.31 is also LZEXE-packed (51,190 → 100,484, Choco
  `engine_loader.c:132-133`), so our existing `LzexeDecompressor` should work
  for KEEN2 v1.31. certain (Choco). Whether v1.00 is packed: uncertain.
- **Steam/GOG** most likely ship v1.31 for episodes 2 and 3. uncertain (CG has
  a CRC only for 1.31, and Chocolate Keen supports only 1.31, which suggests
  that this is the common version).
- Recommendation: do what `TileProperties` does for Keen 1. Try the known
  offsets first, then search by content (signatures below), so unknown
  versions still work.

### The data segment and other EXE positions (v1.31, raw offsets)

From Chocolate Keen's `CVort2_imageOffsets` (certain (Choco)) and CG (where
noted). The layout is consistent: each block ends where the next begins.

| Raw offset | Contents |
|---|---|
| 0x11780 | ANSI quit screen (80x25x2 = 4000 bytes → ends 0x12720) |
| 0x12730 – 0x15839 | Sound block, 12,554 bytes (checked; CG `CAudioVorticon.cpp:49-50` says 9,386) |
| 0x15840 | End text |
| 0x15BC0 | Help text (CG says 0x15DC0) |
| 0x163A0 | Previews text |
| 0x16AC0 – ~0x17758 | Story text (CG `CStory.cpp:62-63`: 0x16CC0-512 … 0x17958-512) |
| 0x17780 | Start of the data segment (CG `CExeFile.cpp:271`) |
| 0x17784 | EGA palette patch area (CG `GsKit/graphics/GsPalette.cpp:52-53`) |
| 0x17828 | Tile property table (689 tiles x 6 words = 8,268 bytes → ends 0x19874) |
| 0x198C6 | Cheat text "C+T+Space" (85 bytes) (CG `CMessages.cpp:433`, offset −512) |
| 0x1991C | Status box text (110 bytes) |
| 0x199AB … 0x199E3 | The eight city names (below) |
| 0x199E4 | God mode on/off texts |
| 0x19B2E | Character map |
| 0x19BE8 | Palettes |
| 0x19FC2 | **Points table** (5 words, as in Keen 1, followed directly by …) |
| 0x19FCC – 0x1A08B | Vorticon Elder message 1 (191 bytes) |
| 0x1A08C – 0x1A19F | Vorticon Elder message 2 (275 bytes) |
| 0x1A1A1 – 0x1A252 | Ending part 1 (ship heads for Earth) |
| 0x1A253 – 0x1A2EA | Ending part 2 (mothership) |
| 0x1A2F7 – 0x1A433 | Ending part 3, pages 1-4 (0x1A2F7, 0x1A333, 0x1A3C9, 0x1A429) |
| 0x1A434 – 0x1A447 | `TO BE CONTINUED....` |
| 0x1A6AA | "Keens left" text |
| 0x1C80C, 0x1C8B5, 0x1C9DD, 0x1CA2B | Translation map, random value table, "fibs17", upper-case table |

The text positions from 0x1991C on come from CG `CMessages.cpp:427-457`,
which gives *file* offsets with odd corrections (−804, −776, −774). Subtracting
them gives the raw offsets above. That the first Elder message lands exactly
10 bytes after Choco's points table (0x19FC2 + 5 words = 0x19FCC) confirms
the conversion. certain (CG + Choco agree). CG extracts strings only for v1.31
(`CMessages.cpp:430-457`). For v1.00 everything is shifted (uncertain by
how much; the tile table moves by +0x110).

**Recommendation:** as with `HintTexts`/`ExeStrings` for Keen 1, find the texts
by content (for example `TO BE CONTINUED`, the city names, `SND\0`) instead of
by offset.

---

## 2. Sounds (inside KEEN2.EXE)

- **Where:** raw offset 0x12730 to 0x14BDA (9,386 bytes) in the unpacked
  image. certain (CG `CAudioVorticon.cpp:47-51`, Choco `CVort2_SOUNDS_OFFSET`).
  CG uses the same offsets for every version (v1.00 included), which is
  probably wrong for 1.00 (uncertain). A robust way: search the image for
  `SND\0` and read the u16 total size at +4.
- **Format:** identical to `SOUNDS.CK1`. The loader copies the block and then
  parses it exactly like the file: entry count u16 at +6, a table of 16-byte
  entries from +0x10 (u16 offset, u8 priority, u8 unknown, 12-byte name),
  data as u16 timer divisors ending in 0xFFFF. certain (CG
  `CAudioVorticon.cpp:86-149` treats the file and the EXE block the same way).
- **Names:** the same set as Keen 1 plus one new sound, `EARTHPOW` (the Earth
  exploding). certain (CG `CAudioVorticon.cpp:317-320`; Choco's
  `CVort2_sndtype` lists 42 names: `WLDWALK … keensleft, earthpow`). CG loads
  `EARTHPOW` but never plays it (no use outside `CAudioVorticon.cpp`). Playing
  it when the Earth blows up is our own choice (uncertain).
- `CLICKSND` is now used: it plays when Keen hits a switch (bridge, light or
  Tantalus switch). certain (CG `ai/CPlayerLevel.cpp:326`).
- `TANKFIRE` is the Guard robot shot and `KEENFIRESND` the Elite shot.
  certain (CG `ai/CGuardRobot.cpp:126`, `ai/CVorticonElite.cpp:288`).
- `vortscream` is played when any Vorticon (grunt, youth, elite) dies; a dying
  Scrub plays `SHOTHIT`. certain (CG).
- **Side note for Keen 1 too:** CG makes each sound value last
  1000/145575 s, so it plays **145.575 Hz** ticks, not 140 Hz
  (`CAudioVorticon.cpp:134`). 145.6 Hz is 1193182/8192, the PIT rate. Worth
  checking against `docs/sounds.md` (uncertain which one is right).

---

## 3. EXE data tables

### Tile properties

- **Same format as Keen 1**: six arrays of u16, one word per tile (animation
  frame count, behaviour, top, right, bottom, left). CG reads episodes 1-3
  with one routine. certain (CG `fileio/CTileLoader.cpp:135-144,162-193`).
- **Number of tiles: 689**. certain (Choco `CVort2_TILENUM = 689`). CG takes
  the count from `EGAHEAD.CK2` (`CEGAGraphicsVort.cpp:89,103`). The array
  stride is 2 x 689 bytes. Only episode 3 needs a forced stride (715), not
  episode 2 (`CTileLoader.cpp:168-170`).
- **Offsets:** v1.31 0x17828, v1.00 0x17938 (raw). certain (CG
  `CTileLoader.cpp:72-73`, Choco agrees for 1.31). Our plausibility search
  (frame counts 1-8, behaviours −2 to 31, sides 0-3) should find it too.
- **CG workaround "for some tile bugs in Episode 2":** a tile that is solid on
  all four sides and has behaviour −1 or −2 (foreground or masked) is treated
  as behaviour 0. certain that CG does this (`CTileLoader.cpp:180-185`). Whether
  the original does is uncertain.
- Top-side values >1 are floor types (2 slippery, 3 ice), as in Keen 1
  (`CTileLoader.cpp:187-192`).
- **Tile left behind after a pickup:** CG uses tile 276 for items with a
  number ≥ 305 (0x131) and tile 143 otherwise, in episodes 1 and 2 alike.
  Doors also become 143. certain (CG `CTileLoader.cpp:295-321`). Keen 1 items
  are all below 305, so this only matters in ep2. uncertain whether 276 is
  right for every ep2 item.

### Behaviour values

Shared with Keen 1 (CG `CPlayerItems.cpp:52-213`):

| Value | Meaning | Ep2 |
|---|---|---|
| 1 | Deadly | certain |
| 2-5 | Doors yellow/red/green/blue (two tiles high, sink into the floor at 1 px per 2 ticks, `ai/CDoor.cpp`, `DOOR_OPEN_SPEED 1`) | certain |
| 6-10 | Points 500/100/200/1000/5000 | certain (CG `CPlayerItems.cpp:123-137`). Points table at raw 0x19FC2 (Choco). Which pictures are used in ep2: uncertain |
| 11-14 | Ship parts | not used in ep2 (no parts) (uncertain, nothing in CG ep2 refers to them) |
| 15 | Raygun: +5 charges (CG reads the amount from raw 0x728C on non-easy, which is a code byte) | certain (CG `CPlayerItems.cpp:138-151`) |
| 16 | Pogo stick | never placed in ep2 (Keen has it from the start) (uncertain) |
| 17 | Exit | certain |
| 18-21 | Keycards | certain |
| 22 | **Vorticon Elder message** (only when tile 429 is directly *below* the touched tile; afterwards that tile becomes 182 = "the switch stops glowing") | certain (CG `CPlayerItems.cpp:290-311`) |
| 23 | **Light switch** | certain (CG `ai/CPlayerLevel.cpp:323-346`) |
| 25, 26 | **Switch up / down** (tiles 480 / 493 in CG): bridge switch or Tantalus Ray switch | certain (CG `ai/CPlayerLevel.cpp:296-371`) |
| 24, 27, 28 | Teleporter (ep1), ankh and single shot (ep3) | not ep2 |

### Strings, hints, score texts

See the table in section 1. Notes:

- **Vorticon Elder messages** (called "Vorticon Elder" in CG; Keen 1 has
  statues): two messages, keys `EP2_VE_NOJUMPINDARK` and `EP2_VE_EVILBELTS`.
  CG's game code puts them in **levels 8 and 10** (`CPlayerItems.cpp:299-306`),
  but CG's patcher says **levels 8 and 12** (`fileio/CPatcher.cpp:347-353`).
  **Checked (B5.1): levels 8 and 10** (tile 559 with 429 below, only
  there).
- The ending texts are three parts. Part 3 has four pages. There is a `TO BE
  CONTINUED....` record, but CG's ep2 ending does not show it.
- **Status box**: one record of 110 bytes, plus the eight city names as
  separate zero-terminated strings.
- **City names** (strings in this order): London, Cairo, Sydney, New York,
  Paris, Rome, Moscow, and a 9-character name for level 16. CG names the keys
  after the levels (`EP2_LVL4/6/7/9/11/13/15/16_TargetName`). The string
  lengths 6,5,6,8,5,4,6,9 fit those names, so the city ↔ level mapping is
  **4 London, 6 Cairo, 7 Sydney, 9 New York, 11 Paris, 13 Rome, 15 Moscow,
  16 Washington**. The order and lengths are certain (CG). **Checked
  (B5.1):** the strings are `London`, `Cairo`, `Sydney`, `New York`,
  `Paris`, `Rome`, `Moscow`, `Wash D.C.`, and exactly levels 4, 6, 7, 9,
  11, 13, 15 and 16 have a spark.
- **High score texts**: the bitmap for the third column is `SAVED` in CG's
  fallback names (`CEGALatch.cpp:79-85`) and `CITIESSA` in Choco's enum.
  Either way, the name comes from `EGAHEAD.CK2`. The default names and
  `first`…`last` words: probably laid out as in Keen 1 (search `SCORES.`).
  uncertain.
- **Starting charges** come from raw 0x8AA2 (a code byte) in CG
  (`engine/core/CPhysicsSettings.cpp:78-82`). The value is not given. Avoid
  reading code bytes: use a constant and check the original. uncertain
  (probably 3?).

---

## 4. Levels and the info layer

- Levels 1-16, world map 80, map 81 (space scenes: the ending **and** the
  Earth explosion), map 90 (title, story, high scores; CG uses the same pixel
  positions in map 90 for all three episodes: title at (32,32), story at
  (32+2·320,32), high scores at (1344,32)). certain (CG
  `finale/CTantalusRay.cpp:66`, `finale/CEndingEp2.cpp:72,129`,
  `CHighScores.cpp:23-24,83-85`, `CStory.cpp:78-86`, `CPassiveVort.cpp:38,48`).
- CG swaps levels 5 and 9 on "hard" only for episode 1
  (`CVorticonMapLoader.cpp:120-126`). This is a CG extra, not ep2.
- **Info values in levels 1-16** (certain (CG `CVorticonMapLoader.cpp:350-537`)):

| Value | Ep1 | **Ep2** |
|---|---|---|
| 255 | Keen start | Keen start |
| 1 | Yorp | **Vorticon (grunt)**, 1 HP |
| 2 | Garg | **Vorticon youth** ("Vortikid", baby) |
| 3 | Vorticon | **Vorticon Elite** |
| 4 | Butler robot | **Scrub** |
| 5 | Tank robot | **Guard robot** |
| 6 | Ice cannon ↗ | **Moving platform** (horizontal); spawned 4 px *above* the cell top |
| 7 | Ice cannon ↑ | **Spark** = the Tantalus Ray machine's core |
| 8-11 | ice cannons, chain | nothing in ep2 (CG logs "unknown enemy") |
| other (≥ 0x100) | — | At a **switch** tile the info value is not an enemy but a bridge offset: low byte = signed X offset, high byte = signed Y offset (in tiles) from the switch to where the bridge starts. Value 0 at a switch = light switch (behaviour 23) or Tantalus Ray switch (behaviour 25/26). certain (CG `ai/CPlayerLevel.cpp:331-358`) |

- Sprites start with their top left at the top left of the cell, as in ep1.
- A commented-out CG fix: in ep2 level 15 the tile at (50,18) should be 187
  (`CVorticonMapLoader.cpp:555-559`). It is disabled. uncertain whether the
  original level has a bug there.

---

## 5. Enemies and objects

Sprite numbers: Choco's enum (the `EGAHEAD.CK2` names, **134 sprites,
0-133**) agrees with CG's constants except for one swap (noted). certain
(Choco + CG `engine/core/spritedefines.h`).

| Sprites | Name |
|---|---|
| 0-31 | Keen: walk R 0-3, walk L 4-7, jump R 8-13, jump L 14-19, shoot R 20, L 21, dead 22-23, pogo R 24-25, L 26-27, **28-29 `KEENSICLE1/2` (stunned), 30 `KEENSBACK`, 31 `KEENGETSUP`** |
| 32-47 | Keen on the map: right, down, left, up (4 each) |
| 48-57 | Youth: left 48-51, right 52-55, die 56-57 |
| 58-59 | Tantalus Ray beam (Earth explosion scene) |
| 60-63 | "Fire earth" explosion |
| 64-67 | Big Earth chunks; 68-71 small chunks |
| 72 | `LAMESHIP` = Vorticon mothership; 73 `YAWN` |
| 74-87 | Vorticon: left 74-77, right 78-81, stand/look 82-83, jump 84-85, die 86-87 |
| 88-101 | Elite: left 88-91, right 92-95, fire L 96 / R 97, jump R 98 / L 99, die 100-101 |
| 102-111 | Scrub: left 102-103, up 104-105, right 106-107, down 108-109, shot 110, dead 111 |
| 112-121 | Guard robot: right 112-115, left 116-119, stand 120-121 |
| 122 | Keen's shot; 123 enemy ("tank") shot; 124/125 shot splash ("ZAP"/"ZOT") |
| 126-127 | Moving platform |
| 128-131 | Spark |
| 132-133 | Keen's small ship right/left (ending) |

Discrepancy: CG uses 84 = Vorticon jump **right**, 85 = jump **left**
(`ai/CVorticon.h` `VORT2_JUMP_RIGHT_FRAME 84`), but Choco's names are
`VORTJUMPL` (84), `VORTJUMPR` (85). **Checked (B5.1):** `EGAHEAD.CK2` names
them `GRUNTJUMPL` (84) and `GRUNTJUMPR` (85), as Choco. More from the real
sprite table: the Guard robot is `GUARDLEFT1-4` at **112-115** and
`GUARDRIGHT1-4` at **116-119** (the table above, from CG, has them the
other way round); 98/99 are `ELITEJUMPL`/`ELITEJUMPR`; 31 is `KEENMELT`;
the rest of the table above is right.

The general rules match Keen 1: enemies wake up when seen (CG
`CVorticonSpriteObject.cpp:101-157`); platforms are always active; enemies in
mid-air keep moving. Enemy gravity is 4/32 per tick, at most 104/32
(`CPhysicsSettings.cpp:48-50`). `getProbability(n)` in CG is
`rnd()%1000 <= n` per tick, so n+1 in 1000 (`misc.cpp:20-23`).

### Vorticon (grunt), info 1. certain (CG `ai/CVorticon.cpp`, `.h`)

- The **same AI as the ep1 Vorticon**, with these ep2 differences:
  - **HP 1** on normal (CG's constructor default `hp=1`; easy 1, hard 2).
    Ep1 reads the HP from the EXE.
  - **Dying:** no white screen flash. Frame 86 for 26 ticks, then frame 87
    (corpse) stays (`CVorticon.cpp:148-162,322-330`, `VORT2_DIE_ANIM_TIME 25`).
  - **Does not jump while the lights are off** (`CVorticon.cpp:224,243-259`).
- Shared numbers: walk 28/32; walk frames change every 5 ticks; looks for 2
  frames x 16 ticks; jump chance 20 (normal), 10 (easy), 30 (hard) per 1000
  per tick; jump speed random 90-149/32 up; trapped after < 160 ticks of
  walking → jumps (90 or 150). On a look it turns towards Keen if he is
  within 8 tiles horizontally. Touch: deadly.

### Vorticon youth ("Vortikid"), info 2. certain (CG `ai/CVortikid.cpp`)

- Runs at **77/32** px/tick (very fast), 4 frames, one every 7 ticks. Starts
  in a random direction.
- On the ground: chance 100/1000 per tick of a hop. Each hop is small (80/32)
  or big (200/32), picked at random. At a wall it turns around, with chance
  200/1000 of a hop.
- **Touching Keen does not kill him; it stuns him** (`player->freeze()`): Keen
  is thrown up with a full jump (120/32), loses the pogo stick, cannot act for
  **250 ticks**, and faces the youth's direction. Frames 28/29 alternate every
  26 ticks; the last 20 ticks show frame 31 ("gets up"). In ep2 friction still
  works while stunned (in ep1 it does not while frozen) (`ai/CPlayer.cpp:698`,
  `941-975`; `ai/CPlayerLevel.cpp:225-251`; `Playerdefines.h:122-126`).
- A shot that hits a stunned Keen only shortens the stun to 20 ticks; it does
  not kill him (`ai/CPlayerLevel.cpp:990-1003`).
- 1 HP. Dying: frame 56 ("fry") for 21 ticks, then 57. It slides on with
  inertia 20/32, reduced by 1 every 11 ticks.

### Vorticon Elite, info 3. certain (CG `ai/CVorticonElite.cpp`)

- **HP 4 on normal** (built as a Vorticon with 4 HP; easy 1, hard 5). CG has
  an unused `VORTELITE_HP 3`. uncertain which one is right.
- Walks at **31/32**. It **charges at 62/32** when Keen's feet are within
  ±2 tiles vertically *and* within 6 tiles horizontally. When Keen is at its
  height, it turns towards him (9 times out of 10).
- Walk frames: 4, one every 7 ticks. Turns at walls (not at ledges, so it
  falls off). Trapped (< 150 ticks of walking) → it jumps.
- Jump chance 15/1000 per tick, jump speed 90-149/32. Only when the lights
  are on (CG lets it jump in the dark on difficulty > normal).
- **Fires**: at least 26 ticks after the last shot, chance 8/1000 per tick.
  Faces Keen 4 times out of 5, shows the gun (96/97) for 23 ticks, fires, and
  holds the pose for 21 more ticks. The shot (sprite 123) starts at the
  Elite's front edge, 9 px below its top, and flies at **108/32**
  (`RAY_DEFAULTSPEED`, `ai/CRay.h:5`). Sound `KEENFIRESND`.
- **Immune to Guard robot shots** (`CVorticonElite.cpp:339-347`). Touch:
  deadly.
- Dying: frame 100 for 46 ticks, then corpse 101.

### Scrub, info 4. certain (CG `ai/CScrub.cpp`, `ai/CCarrier.cpp`)

- A red crawler that **follows walls, floors and ceilings** at **25/32**
  px/tick. It starts by falling; on the ground it walks left. At a wall on its
  left it climbs up; at a ceiling it walks right (upside down); at a wall on
  its right it goes down; on the floor it goes left again. At the edge of a
  platform it tries to wrap around the edge; if there is nothing to hold on
  to, it falls (gravity as for enemies). 2 frames per direction, one every 12
  ticks. The exact wall-wrapping rules in CG are messy; watch the original.
  uncertain.
- **Harmless**: Keen can **stand and ride on it** (it carries him and moves
  him along), and it pushes Keen when he touches its side
  (`CCarrier.cpp:10-44`).
- 1 HP. Shot: frame 110, it pops up (speed −10/32, then normal gravity) and
  lies dead as frame 111. Sound `SHOTHIT`.

### Guard robot, info 5. certain (CG `ai/CGuardRobot.cpp`)

- **Hovers** (no gravity, so it does not fall off ledges). It turns only at
  walls. Moves at **31/32**, 4 hover frames, one every 7 ticks. At a wall it
  "looks" (frames 120-121, switching every 5 ticks) for 26 ticks, then goes
  the other way.
- **Invincible**; it stops Keen's shots.
- **Touch kills Keen** (normal and up; CG lets him survive on easy).
- **Fires volleys**: 4 shots (sprite 123, 108/32), 13 ticks apart, from
  5 px below its top, in the direction it faces. Sound `TANKFIRE`. The first
  volley comes after 200 ticks, later ones after a random 31-199 ticks. It
  stands still for 25 ticks before and after a volley. It does not fire while
  touching a wall on either side. (CG has a "hardmode" flag that is never set.)

### Moving platform, info 6. certain (CG `ai/CPlatform.cpp`)

- Moves horizontally at **23/32**, starting to the right. At a wall (or the
  map edge) it waits 51 ticks and reverses. Keen rides on it (a "carrier", as
  with the Scrub). Animation: 126/127, switching every 16 ticks. Always
  active, even off screen. Absorbs shots. Spawned 4 px above its cell.
- Keen cannot use an exit door while he stands on a platform or another
  object (`ai/CPlayerLevel.cpp:88-97`).

### Spark (the Tantalus Ray machine), info 7. certain (CG `ai/CSpark.cpp`)

- Animates through 128-131, one frame every 6 ticks. Harmless to touch. **One
  shot** destroys it. CG then plays a fixed tile sequence around the spark
  position (mx,my):
  1. At once: row my becomes tiles 492, 546, 547, 548, 492 (x −2…+2: the
     broken glass); the dome tiles at (x −1…+1, my−1) become 143; **the
     switch at (mx−3, my+4) becomes 506 (broken)**.
  2. Every 26 ticks, three times: the "purple thing" at (mx, my+3+k) becomes
     tile 505, a ZAP/ZOT splash appears there, and **every player gets 10,000
     points**. In CG that adds up to 30,000; uncertain whether the original
     gives 10,000 once.
  3. Every 26 ticks, four times: the glow cells in column mx+3+k, rows my+3…5,
     become tile 549, with splashes.
  4. Last: the 3x3 "targeting display" at (mx−7…−5, my+2…4) becomes tile 533
     (static). The object disappears.
- Old CloneKeen comment: "**you must destroy the tantalus ray generator before
  exiting**" (`fileio/Oldsavegamestructs.h:55-57`, `sparks_left`). Current CG
  does not enforce this. uncertain how the original stops Keen (is the exit
  locked, or out of reach?).

### Switches, bridges, lights. certain (CG `ai/CPlayerLevel.cpp:296-375`, `ai/CBridges.cpp`, `playgame/CPlayGameLevel.cpp:106-137`)

- Keen uses a switch with the **pogo button** (not jump). CG checks the tiles
  in the column through Keen's middle, from his feet up in 8 px steps. If one
  has behaviour 23/25/26, it is a switch press instead of taking out the pogo
  stick. The pogo stick is put away.
- Behaviour 26 on tile 493 → becomes 480; behaviour 25 on 480 → 493 (lever
  up/down). Sound `CLICKSND`.
- **Info value ≠ 0 → bridge**: starting at switch + (dx, dy), CG lays
  **tile 270** one tile every **4 ticks**. It goes right if the tile right of
  the start has no solid left side, otherwise left, and stops at the first
  tile that blocks. Pressing again retracts it, tile by tile from the far end,
  and puts back the tile that was next to the start. One background tile is
  remembered for the whole bridge.
- **Info value 0 and behaviour 23 → lights toggle**. CG fades the palette to
  dark (`GsPalette::setdark`, a CG approximation). While dark, Vorticons do
  not jump. How the original darkens (black palette? some colours stay?):
  uncertain, watch it. A new level always starts with the lights on
  (`playgame/CPlayGameVorticon.cpp:136-137,202`).
- **Info value 0 and behaviour 25/26 → Tantalus Ray fires**: the Earth
  explodes, game over (section 7).

### Shots (shared with ep1, changed sprites). certain (CG `ai/CRay.cpp`)

- Keen's shot: sprite 122, 124/32 (`ai/CPlayerLevel.cpp:780-784`). Enemy shot:
  sprite 123, 108/32. Splash 124/125, 11 ticks (`RAY_ZAPZOT_TIME 10`).
- A shot hurts any object that "can be zapped" and is not of the shooter's
  type. So in CG, Guard robot shots also kill grunts and youths, and Elite
  shots hit grunts (but Elites are immune to Guard robot shots). uncertain
  whether the original does friendly fire.
- An enemy shot kills Keen. On a stunned Keen it only ends the stun early.

### Doors and keycards

The same as ep1 (CG `CPlayerItems.cpp:94-122,372-407`). The opened door
becomes tile 143. certain (CG). Keycards are reset when Keen goes back to the
map (`playgame/CPlayGameWorldMap.cpp:138-141`).

### Not in ep2

Yorp, Garg, butler, tank, ice cannons, chain/stone, in-level teleporter, ship
parts, ankh, and the Vorticon commander (ep2's info 3 is the Elite).

---

## 6. Items, HUD, status screen

- **Start:** 4 lives, extra life every 20,000, **pogo stick from the start**
  (certain, CG `CPhysicsSettings.cpp:80`, `ai/CPlayer.cpp:172-183`).
  Starting charges: read by CG from code byte 0x8AA2; value unknown
  (uncertain).
- **Raygun pickup:** +5 charges (+8 on CG's easy). certain (CG).
- **No ship parts.** The "parts" are the 8 cities (= 8 levels).
- **Keycards**: yes, four colours, same behaviour as ep1.
- **Status screen** (CG `CStatusScreen.cpp:230-346`, certain (CG) as CG's
  layout; compare with the original):
  - Box 29 x 14 characters (ep1: 29 x 15). Header text from the EXE status
    box string.
  - Score (x 1-12, y 2), "extra Keen at" (x 14-28, y 2), lives as small Keens
    (x 1-18, y 4-6, at most 7), raygun (x 20-28, y 4-6, icon tile 414,
    charges right-aligned to column 27).
  - **"Targets saved"** box (x 1-18, y 8-11): each completed city is printed
    in two columns: (1,8) London, (8,8) Cairo, (1,9) Sydney, (8,9) Rome,
    (1,10) Paris, (8,10) New York, (1,11) Moscow, (8,11) Washington.
  - Keycards box (x 20-28, y 8-11): tiles 424 (yellow) at (21,8), 425 (red) at
    (25,8), 426 (green) at (21,10), 427 (blue) at (25,10). uncertain whether
    these tile numbers are right for ep2 (CG uses the same numbers for ep1).
  - No pogo box and no ship parts.
- **High score table** (CG `CHighScores.cpp:101-109,194,212-218,348-352`): the
  bitmap `SAVED`/`CITIESSA` at (232,32); `NAME` and `SCORE` at y 36 (ep1: 32);
  rows from y 56 (ep1: 52), 16 px apart; the number of cities saved is drawn
  at x 252. The number = how many of levels 4, 6, 7, 9, 11, 13, 15, 16 are
  done. certain (CG).

---

## 7. World map, cities, Tantalus Ray, Earth explosion

- **Entering levels:** as in ep1 (jump/pogo on an entrance; values 1-16,
  `0x8000` = blocking until done; done levels get tile 77 or 78-81). CG uses
  77/78-81 for ep1 and ep2 alike (`CVorticonMapLoader.cpp:307-328`, a
  "consistency" override). certain (CG). Whether the ep2 map tiles really are
  77-81: uncertain (likely the same tileset layout).
- **No teleporters** (CG has teleporters only for ep1 and ep3,
  `playgame/CPlayGameWorldMap.cpp:292-303`), **no ship on the map**: info 20
  does nothing in ep2 (`CPlayGameWorldMap.cpp:60-70`). Values > 32 are
  ignored. certain (CG). Which special values ep2's map holds: check the file.
- **The 8 cities** are levels **4, 6, 7, 9, 11, 13, 15, 16**. Each has a
  Tantalus Ray machine (spark). A city is saved when its level is *completed*
  (exit door). certain (CG `CPlayGameVorticon.cpp:686-700,761-776`). The other
  8 levels are "normal" levels, probably needed to open paths (uncertain).
- **Winning:** as soon as the map loads with all 8 city levels done, the
  ending starts (`verifyFinales()` during the map's `init`,
  `CPlayGameVorticon.cpp:198,664-706`). certain (CG).
- **Earth explodes (game over)** (CG `playgame/CPlayGameLevel.cpp:109-125`,
  `finale/CTantalusRay.cpp`, `ai/CEarthExplosion.cpp`, `ai/CEarthChunk.cpp`):
  - **Trigger:** Keen hits a switch (behaviour 25/26) whose info value is 0,
    the Tantalus Ray switch next to a machine that is still intact. Once the
    spark is destroyed the switch becomes tile 506 and is no longer a switch.
  - The lights come on, the music stops, the screen shakes for 2 s (CG
    `CVibrate(2000)`), and CG shows a box "Uh-Oh" (CG's own text; uncertain
    what the original shows). Keen is hidden. **This is game over whatever
    the lives.**
  - Then on **map 81**: a beam (sprites 58/59 alternating each tick) starts at
    tile (4,9) and flies right 252/32 and down 108/32 per tick, the view
    following, until it reaches tile column 47 (the Earth is the 4x4 tiles at
    (47,21)). `KEENFIRESND` plays at the start.
  - The explosion runs in steps of 6 ticks: in steps 0-15 an explosion sprite
    (60-63, frames every 6 ticks) appears at a random spot within 32 px of the
    hit point. Step 5: ten small chunks (68/70); steps 6-8: single chunks;
    step 10: four big chunks (64/66) fly diagonally at 16/32, small ones at
    20/32 and 10/32, and **the Earth's 16 tiles become tile 561**. Explosions
    also leave tile 155 (space) behind. Step 32 (≈ 3.3 s) ends the scene.
  - CG then shows the `GAMEOVER` bitmap centred with `GAMEOVERSND`, then the
    high score table. `EARTHPOW` is probably the explosion sound (CG does not
    play it).
  - CG bug: all ten step-5 chunks go the same direction (`EC_UPLEFTLEFT`). The
    original probably spreads them out. uncertain.

---

## 8. Keen's physics

- **No differences** in CG between ep1 and ep2 for walking, jumping, pogo,
  friction, falling or ice. The ep-dependent code is only sprite frame
  offsets for ep3. certain (CG: grep of `ai/CPlayer*.cpp`; constants in
  `CPhysicsSettings.cpp:12-31`).
- Differences that matter:
  - Pogo stick from the start.
  - **Stun** instead of being frozen (youth): see section 5. The same 250
    ticks, other frames (28/29, then 31), and friction keeps working.
  - Riding objects (Scrub, platform) with `pSupportedbyobject`. The exit
    cannot be used while riding.
  - The pogo button doubles as the switch button.

---

## 9. Intro, ending, finale

- **Title/intro:** same scheme as ep1 (map 90 + bitmaps `TITLE`, `IDLOGO`,
  `AN`, `PRESENT`, `APOGEE`, `ONEMOMEN`, `OFAN`, `PRODUCT`, `IDSOFT`, …). The
  ep2 bitmap list matches ep1 except `PARTS` → `SAVED`/`CITIESSA`
  (`CEGALatch.cpp:79-85`; Choco `CVort2_bmptype`, 18 bitmaps incl. `KEENSHIP`,
  `WINDON`, `WINDOFF`). certain.
- **Story:** from the EXE (raw 0x16AC0), shown over map 90 at the
  "Keen with his ship" screen, as in ep1. certain (CG `CStory.cpp:55-86`).
- **The ending** (CG `finale/CEndingEp2.cpp`, `finale/CShipFlySys.cpp/.h`).
  certain (CG), timings are CG's:
  1. **Map 81**: Keen's small ship (sprites 132/133) starts where **tile 593**
     is on the map. Message "ending part 1". It waits 10 ticks, then flies
     **672 ticks down-right** (32/32 px right, 12.8/32 down per tick), then
     **150 ticks down** (8/32 per tick). The scene ends when the script and
     the message are both done.
  2. **Map 81 again**: the **Vorticon mothership** (sprite 72) at tile (8,26),
     view at (0,300). Message "ending part 2". It waits 10 ticks and flies
     **80 ticks up-left** (32/32 left, 12.8/32 up).
  3. **`FINALE.CK2`** picture (Keen outside in the snow; CG calls it
     "SnowedOutside") with the four pages of part 3, one per button press. No
     `WINDON`/`WINDOFF` bitmaps are used here. uncertain: CG's static scene
     can place bitmaps, but ep2 adds none.
  4. CG then shows the high score table. CG does **not** show `TO BE
     CONTINUED....` and does **not** show the end text, but both exist in the
     EXE (raw 0x1A434 and 0x15840). Chocolate Keen has a `draw_win_text` for
     ep2, so the original most likely shows the end text after the ending.
     uncertain, watch the original.

---

## 10. Things an implementer will trip over

1. **No `SOUNDS.CK2`, `ENDTEXT.CK2`, `STORYTXT.CK2`, `HELPTEXT.CK2`**: all
   come from the unpacked `KEEN2.EXE`. The game-file check and the launcher
   must not require them. The texts inside the EXE probably have the same
   format as the `.CK1` text files (CR LF, `~`, 0x1F, 0x1A); uncertain, check
   that each block ends in 0x1A.
2. **Tile count 689**: anything hard-coded to 611 (tile properties, the HD
   sheets, tests) must use the count from `EGAHEAD`.
3. **Item and special tile numbers differ** from ep1. Use the behaviour
   table, never tile numbers, except for the ones CG hard-codes for ep2: 143
   (gray background), 155 (space), 182 (Elder light off), 270 (bridge), 276
   (background after picking up items ≥ 305), 414 (raygun icon), 424-427
   (keycard icons), 429 (Elder light), 480/493 (switch up/down), 492, 505,
   506, 533, 546-549 (destroyed Tantalus machine), 561 (destroyed Earth), 593
   (ship start on map 81), 77-81 (done signs on the map).
4. **Info values ≥ 0x100 in levels** are bridge offsets at switches, not
   enemies. Ignore them when spawning, and read them when a switch is used.
5. **Carriers**: Keen must be able to stand on moving sprites (Scrub,
   platform). Ep1 had nothing like this (`LevelCollision` must accept moving
   floors).
6. **Darkness**: a level-wide state that changes palette and enemy AI.
   Widescreen/HD/xBRZ must darken too.
7. **Game over without losing lives** (Tantalus switch). Keen 1 has no
   comparable path.
8. **Tile replacements while the level runs** (bridge, Tantalus wreck, Elder
   lights, switches): `TileMapLayer` and the HD and xBRZ layers must update
   per cell.
9. **The ending start** is checked when the map loads (all 8 cities), as in
   ep1, where it is checked when Keen has all parts.
10. **Version handling**: CG and Chocolate Keen only know offsets for 1.31
    (and CG a few for 1.00). Use content searches as for ep1.
11. CG's tile animation for ep1-3 is shared (6-tick rate; runs of n tiles with
    frame count n). No ep2 difference is known. certain (CG
    `CTileLoader.cpp:195-228`).
12. **Ice/slippery floors** exist in the tile format, but whether ep2 uses
    them is unknown. Check the floor types in the real table.
13. The pogo button opens switches **before** toggling the pogo stick, so the
    order of input handling matters.
14. The Elder message needs tile 429 below the trigger tile. CG notes that the
    original has behaviour-22 tiles elsewhere that should not fire
    (`CPlayerItems.cpp:292-296`).
15. Multiplayer (future co-op): CG gives the 10,000 Tantalus points to *all*
    players, and the Earth explosion ends the game for everyone.

---

## Checked with the real files (B5.1)

The player's own files, version 1.31 (`KEEN2.EXE` 58,335 bytes). Details of
the EXE pieces are in [file-formats.md](file-formats.md).

**Tiles** (behaviour from the table at 0x17828, picture from `EGALATCH.CK2`):

| Tiles | What |
|---|---|
| 143, 276 | The two backgrounds that items leave behind (items 306-311 lie on 276, the others on 143) |
| 155 | Empty space on map 81 |
| 159 | Exit (17) |
| 173-174, 195-196, 197-198, 199-200 | Doors yellow, red, green, blue (2-5) |
| 175, 311 | Raygun (15); 176 pogo (16), placed in no level |
| 182 | A plain blue floor block, solid (common in many levels) |
| 190-193 | Keycards (18-21); 201-205 and 306-310 points (6-10) |
| 270 | A gray girder, solid on every side (the bridge in CG); in no level |
| 271 | Light switch panel (23) |
| 375, 376 | Behaviour 22 without anything below that speaks: the silent ones |
| 414, 424-427 | Status screen icons: raygun and keycards |
| 429-432 | The glowing blue floor (4 frames, behaviour 1 = deadly), under the Elder |
| 464 | The tile under every spark (the dome's middle) |
| 480 / 493 | Lever, behaviours 25 / 26; every lever in the levels is 480 |
| 481-484, 494-497 | Animated, behaviour 24 (Keen 1's teleporter value; nothing in Keen 2) |
| 492, 505, 506, 533, 546-549 | Broken sparkers, burnt tube, broken lever, display static, broken dome, dark lamp: CG's wreck tiles; the pictures fit |
| 559 | Behaviour 22, the Elder's tile (levels 8 and 10 only) |
| 561 | Black: what is left of the Earth |
| 572-574, 585-587, 598-600 | The Earth on map 81 |
| 575-581, 589-594 | The Vorticon mothership on map 81; 593 is one of its tiles |

No tile has a floor type (no ice or slippery floors). Tiles 371-373 are
masked foreground (−2) and solid on every side, the kind CG's "tile bug"
workaround turns into plain tiles; sprites cannot overlap them anyway.

**Levels:**

- Info values 1-7 as in section 4. Level 1: 4 Scrubs. Platforms (6) in
  levels 2, 11, 12 (six), 13, 15 and 16. The bottom border row of level 2
  holds stray values from 0x8F up; they make no enemy.
- Sparks: (66, 14) in levels 4, 6, 7, 11, 15 and 16, (126, 14) in level 9,
  (46, 14) in level 13; the lever is always at (mx−3, my+4), and the dome,
  glass, tubes, lamps and display are where CG's tile sequence expects
  them.
- Bridges: level 5 (15, 41) 0xFE04 (4 right, 2 up: over the fire pit),
  level 13 (76, 17) 0x01FC (4 left, 1 down), level 16 (7, 34) 0xFA04 and
  (58, 34) 0x00FA (6 left, same row: a value under 0x100 at a switch).
- Light switches: level 4 (3, 8), 13 (67, 21), 15 (47, 8), 16 (35, 4),
  (44, 12), (6, 31), (6, 40).
- The Elders: level 8 (58, 52) and level 10 (57, 55), tile 559 with 429
  below.
- World map 80: entrances 1-16 (four cells each), 0x8001 and 0x8005 (two
  cells each), Keen's start 255; no 20 and no teleporter values.
- Map 81: the Earth is 3x3 at (47, 22); tile 593 is at (6, 5); the
  mothership's tiles at (1-7, 4-5).

**Sprites** (`EGAHEAD.CK2`): the names agree with section 5 except the
Guard robot (named 112-115 left, 116-119 right; the pictures face the
other way, see gameplay.md) and 31 (`KEENMELT`). Collision
boxes (left, top, right, bottom; the table holds the last pixel inside):

| Sprites | Box |
|---|---|
| Keen 0-31 | 4, 1, 11, 23 (pogo 4, 0, 11, 23; dead 4, 4, 11, 15), as Keen 1 |
| Youth left 48-51 | 1, 6, 14, 23 |
| Youth right 52-57 | 4, 4, 11, 23: Keen 1's Yorp box, most likely left over |
| Grunt, Elite 74-101 | 2, 1, 21, 31 (Keen 1's Vorticon) |
| Scrub 102-111 | 0, 0, 15, 15 |
| Guard robot 112-121 | 0, 0, 15, 23 |
| Platform 126-127 | 0, 0, 31, 15 |
| Spark 128-131 | 2, 2, 13, 13 |
| Shots 122-123 | 0, 0, 15, 7 |

**The ending with the real files (B6):** with CG's numbers, Keen's ship
starts at tile 593 (6, 5), flies 672 ticks at (32, 12.8)/32 and 150 at
(0, 8)/32 and ends right on the Earth (47-49, 22-24): the numbers fit the
map. The texts: part 1 (6 lines), part 2 (5 lines), four pages at home,
`TO BE CONTINUED....`; all line records (file-formats.md).

**Texts around the high scores (B7):** after the two `SCORES.` records
(0x1A4CA: Yorpy, Gargile, Zzapp!; 0x1A515: first ... last) come
`SCORE:`, `You saved `, `no cities!`, ` cities!`, ` city!`,
`CONGRATULATIONS!`, `You got `, ` place!` and `Enter your name:`
(around 0x1A660), then `Keens Left` and the main menu's own words. So the
original most likely tells how many cities were saved at the end of a
game; B7 does not show that yet (the shared name entry is used).

## Open questions (need real KEEN2 files or the original game)

**Answered in B5.1 with the player's own files (version 1.31):**

1. v1.31: 58,335 bytes LZEXE-packed, image 118,160 bytes (CG's 118,672
   includes the 512-byte header). **v1.00: still open** (not available).
2. The player's files are v1.31. Which version Steam and GOG ship: still
   open.
3. Sound block at 0x12730, 12,554 bytes, 63 entries, 42 names; `EARTHPOW`
   is the only new one. v1.00's offset: still open.
4. See the tile table above. No floor types.
5. Levels 8 and 10.
6. London, Cairo, Sydney, New York, Paris, Rome, Moscow, `Wash D.C.`
7. See "World map 80" above. The done-sign tiles (77-81?) are left for B6.
8. See "Bridges" above; the offsets fit the encoding.
9. All four blocks end in 0x1A at the 1.31 positions (help at 0x15BC0).
   The previews text is the "PREVIEWS!" page; where the original shows it
   (a menu item) is left for B7.
10. Tile 593 at (6, 5), part of the mothership; the Earth is 3x3 at
    (47, 22), not 4x4 at (47, 21); 561 is black.
11. **Still open**: CG reads it from code, which we do not read; watch the
    original.
12. 84 `GRUNTJUMPL`, 85 `GRUNTJUMPR`.

**Answerable from the files** (the original list, kept for reference):

1. Exact size of KEEN2.EXE v1.00 and whether it is LZEXE-packed; the image
   size after unpacking (is CG's 118,672 = 512 + image?).
2. Which versions Steam and GOG ship (expected: 1.31).
3. Sound block offset in v1.00 (search `SND\0`); number of entries; exact
   names (is `EARTHPOW` the only new one?).
4. Tile numbers of ep2 items, doors, keycards, deadly tiles, switches (25/26,
   23), floor types (any ice?), animation groups.
5. Which levels hold the two Vorticon Elder messages (8 and 10, or 8 and 12)?
6. The exact city names, especially level 16's 9-character string.
7. The info values on the ep2 world map (blocking `0x8000` entries? a value
   20 or other specials?), and the done-sign tiles (77-81?).
8. Bridge info values in the levels (to test the offset encoding).
9. Whether the embedded texts end in 0x1A and what the "previews" text is
   used for (an ordering/preview screen?). CG's help text offset (0x15DC0)
   vs Choco's (0x15BC0).
10. Map 81: where tile 593 is, where the Earth is (47,21?), and that 561 is
    the "destroyed Earth" tile.
11. Starting charges (CG reads a code byte; not to be read by us).
12. The `EGAHEAD.CK2` sprite names for 84/85 (Vorticon jump left/right).

**Only by watching the original:**

13. How darkness looks (fully black? Keen and some tiles visible?), and
    whether enemies behave differently in the dark beyond not jumping.
14. How the original stops Keen from leaving a city level before destroying
    the machine (locked exit? out of reach?), and the points for destroying
    it (10,000 or 30,000?). B6 saves a city when its level is done, as CG.
15. What happens on screen when the Tantalus switch is hit (text? shake
    length?), and the timing of the beam and explosion; whether `EARTHPOW`
    plays.
16. Vorticon grunt/Elite HP (1 and 4 in CG), Elite fire/jump rates, youth
    speed and hop rates, Scrub wall-crawling rules, Guard robot volley timing,
    platform speed and wait.
17. Whether enemy shots hurt other enemies (Guard robot shots vs grunts and
    youths).
18. The ending: whether `TO BE CONTINUED....` and the end text are shown after
    the `FINALE.CK2` pages (B6 shows both); the ship flight timings (they fit
    map 81); whether the light bitmaps are used (B6: no). Also the places on
    the status screen (B6 uses CG's).
19. Stun: whether Keen is thrown up a full jump, and the frames (28/29, then
    31; what is 30 `KEENSBACK` for?).
20. The sound tick rate (CG: 145.6 Hz, our docs: 140 Hz). This applies to
    Keen 1 too.

**B10, watched in the original (js-dos):** of questions 13-20 only part of
18 could be answered: the places on the status screen (now the original's,
apart from the cities and keycards). Also seen: 3 starting charges, the
title over the first screen of map 90, the high score screen at cells
84-103, and GAME OVER without a window (`gameplay.md`, "Seen in the
original"). Questions 13-17, 19, 20 and the rest of 18 stay open: they need
someone to play the original through those levels.
