# Realistic graphics for every game: research

Milestone `milestone-r1-realistisch-onderzoek` (the user's wish of
24-10-2026: make every game look much better, "zodat het foto realistisch
wordt"; everything must keep working as it does now, and an extra option in
the menu switches it on and off). This file is what the architect found by
reading the graphics code of all five games and the current state of the
tools; the open choices for the user are at the end (§9).

## Samenvatting (voor de gebruiker)

- **Echt fotorealistisch maken kan, maar niet met één knop of één
  techniek.** Het beeld van de spellen is 320x200 pixels met tiles van
  16x16; "realistisch" betekent dat elke tile en elk plaatje opnieuw
  getekend wordt (met AI, op de eigen computer) én dat er echt licht,
  schaduw en sfeer bij komt (in Godot, tijdens het spelen).
- **Advies: in lagen bouwen**, elke laag werkt los en voor alle vijf de
  spellen: (1) de menu-optie met beeldeffecten (licht, gloed, kleur),
  (2) echt licht en reliëf op de bestaande graphics, (3) realistische
  achtergronden (o.a. echte foto's van Mars van NASA, rechtenvrij),
  (4) AI-graphics die de speler zelf maakt (zoals nu HD), eerst als proef
  van ~10 plaatjes. Laag 1-3 hebben geen downloads nodig.
- **Spelen verandert nergens**: alles is alleen tekenen; botsingen, snelheden
  en online blijven gelijk. Standaard uit; met de optie uit is het spel
  pixel voor pixel zoals nu (de bestaande regressiescripts bewijzen dat).
- **Grootste risico's**: Keen en de vijanden gaan flikkeren als elk
  loopbeeldje apart door een AI gaat; herhalende tiles vallen meer op met
  foto-texturen; een fotorealistische wereld met een cartoon-Keen kan raar
  ogen. Daarom eerst een proef en jouw oordeel.
- **Wat de speler ervoor nodig heeft** (alleen voor laag 4): ~7-12 GB aan
  AI-modellen en een paar uur rekenen op de Mac per spel. De gemaakte
  graphics blijven op de eigen computer (net als HD), nooit in git.

## 1. What is there now

### One display setting for all five games

`DisplaySettings` (`src/game/display_settings.gd`) holds what the player
sees, for every game at once (stored by `UserSettings` in `user://settings.cfg`,
section `[display]`):

| Field | Values | Default | Key |
|---|---|---|---|
| `aspect` | `ORIGINAL`, `WIDESCREEN` | widescreen | F2 |
| `correct_pixel_aspect` | bool | | F3 |
| fullscreen | bool | | F4 |
| `graphics` | `ORIGINAL`, `XBRZ`, `HD` | original | F5 |
| `smooth_motion` | bool | off | F6 |
| `backgrounds` | bool (only shown in widescreen) | on | — |

`is_original_picture()` is true only with original graphics and smooth
motion off; then the `World` viewport is exactly the game picture. In every
other case it is `K` times larger (2-8, `GameScreen._fit_screen`), and its
texture is drawn on screen by `%Screen` with `even_pixels.gdshader`. **A
realistic mode slots in there**: it is "not the original picture", so the
large viewport, linear filtering and the `%Screen` pass are already in
place for it.

### Two engines, two texture paths

| | Keen 1, 2, 3 (Vorticons) | Keen 4, 5 (Galaxy) |
|---|---|---|
| Textures | `GraphicsTextures` + `ScaledGraphics` (`src/game/`, `src/graphics/`) | `GalaxyScaledGraphics`, `GalaxyTileAtlas`, `GalaxyObjectLayer` (`src/galaxy/`) |
| Modes | original, xBRZ, HD | original, xBRZ (HD is shown as original) |
| How scaled graphics come in | the whole set at once (`GraphicsLoader`, worker threads) | per level, only the tiles and sprites it uses |
| Player-made graphics | `HdPack`: `game_data/keenN/hd/*.png`, sheets 4x | none |
| Tools | `tools/make_hd_graphics.sh`, `tools/export_hd_sheets.gd`: **Keen 1 only** | none |
| Size | Keen 1: 611 tiles, 119 sprites; Keen 2: 689 / 134; Keen 3: 624 / 148 | Keen 4: 1296 background + 2916 foreground tiles (many empty) and a few hundred sprites; Keen 5 alike |

`GraphicsTextures._texture()` gives every larger image the size of the
original (`set_size_override`), so **game code never knows how large a
texture really is**. That is why a new set of graphics needs no change in
gameplay code: the boxes, positions and timings stay those of the original.

### Menus

- Keen 1-3: `MenuController._options_menu()` (`src/menu/menu_controller.gd`)
  builds Sound, Widescreen, 4:3 pixels, Full screen, Smooth motion,
  Backgrounds, Graphics (and Extra levels for Keen 1); `_toggle_option()`
  changes a setting, saves it and emits `settings_changed`.
- Keen 4-5: `GalaxyMenuPages.options()` (`src/galaxy/ui/galaxy_menu_pages.gd`)
  with the same items plus Score box; `GalaxyMenuController._toggle_option`
  hands everything but the score box to `MenuController`.
- F5/F6 are handled once, in `GameScreen._handle_display_keys()`, for all
  five games. F1-F7 are taken (and reserved from rebinding in
  `KeyBindings`); **F8 is free**.
- Tests that walk the options by position: `tests/test_menus.gd` (checks the
  last two labels), `test_backdrops.gd`, `test_keen2_menus.gd`,
  `test_galaxy_menus.gd`, `test_galaxy_paddle_menus.gd`,
  `test_keen5_menus.gd`, and the settings round trip in `test_saving.gd`.

### Rendering

- Renderer: **GL Compatibility** (`project.godot`), chosen so the game runs
  on every Mac and Windows PC. 2D lights, 2D shadows and canvas shaders work
  there.
- Shaders today: `even_pixels` (equal game pixels on screen), `level_wall`
  (Keen 1/2 walls), `masked_tiles` (Keen 2/3 masked tiles), `player_colors`
  (player 2), `split_screen`.
- **No light, normal map or post effect anywhere**; the only lighting node
  is `Keen2Darkness` (a `CanvasModulate` that dims lights-off levels).
- Pictures behind the levels (`LevelBackdrop`, `LevelWall`,
  `BackdropHoles`) exist for all five games, painted by our own tools
  (`tools/make_keen*_backgrounds.py`); only in widescreen.

### What the user said before

On 14-10-2026 the Real-ESRGAN HD was tried and judged "best lelijk": it
sharpens, but invents no details, and flat colours differ per tile. xBRZ
looks better but misses detail. The plan "HD with new details" (Stable
Diffusion + ControlNet Tile on top of xBRZ) is in `docs/graphics.md` and was
parked. This research picks it up and widens it to "realistic".

## 2. What "photorealistic" can mean here

A realistic look has four ingredients. They are independent, and each can
be built for all five games:

| Layer | What changes | Where it runs | Needs the player to download/compute? |
|---|---|---|---|
| A. Atmosphere | tone mapping, colour grading, gloom/bloom, vignette, haze, fine grain | a shader on `%Screen` | no |
| B. Light and relief | normal maps on tiles and sprites, light from lamps, shots, lava, fire, exits; soft shadows; ambient occlusion in corners | Godot 2D lights in the `World` viewport | no (normals worked out from the graphics at start) |
| C. Realistic backgrounds | photographic skies and walls behind the levels, with depth (blur, haze) | the existing backdrop system | no (our own pictures in `assets/`) |
| D. Realistic graphics | every tile and sprite redrawn with real materials (stone, metal, ice, skin, cloth) | made once by AI on the player's computer, read like HD | yes: models of 7-12 GB, hours of compute |

A to C make it look *lit and real*; only D makes the things themselves look
real. Without D, A-C on top of xBRZ give a "remastered 2.5D" look (comparable
to modern pixel-art games with real-time light). With D it can come close to
photoreal. A full 3D remake (models for every tile and sprite) would be the
only way to be truly photographic from every angle; it is out of proportion
and is not advised.

## 3. Layer A: atmosphere (post-processing)

All in our own canvas shaders, so it works the same in the Compatibility
renderer on Mac and Windows, and needs no `WorldEnvironment`:

- **Bloom/glow**: bright pixels (lamps, shots, lava, the exit sign) bleed
  light. Two small extra viewports (half and quarter size, blurred) feed the
  `%Screen` shader. Godot's own glow needs HDR 2D and a `WorldEnvironment`,
  whose support in the Compatibility renderer differs per version: our own
  pass avoids that risk.
- **Tone mapping and colour grading**: EGA colours are fully saturated; a
  filmic curve (ACES/AgX-like) and a colour look-up table per game (Mars
  red-orange, the cold grey-blue of the Mothership, Vorticon purple, Keen
  4's green forests, Keen 5's cold station) make them read as real light.
  The LUTs are ours (small PNGs in `assets/`).
- **Vignette, very fine film grain, a hint of lens softness** at the edges.
- **Depth**: the background pictures get a little blur and haze (they are
  "far away"); the level stays sharp.

Cost: one or two extra passes on a 1080p picture, small for any GPU of the
last ten years. It must never touch the picture with the option off
(`is_original_picture()` stays as it is).

## 4. Layer B: light and relief

Godot lights 2D items through a `CanvasTexture` (colour + normal map +
specular), or through a canvas shader that writes `NORMAL_MAP`. Lights are
`PointLight2D` (with a light texture) and `DirectionalLight2D`; shadows come
from `LightOccluder2D` or the occlusion layers of a `TileSet`.

- **Normal maps without AI.** Worked out at start from the graphics the game
  already has (original, xBRZ or HD), per image, like xBRZ now on worker
  threads: height from the shape (distance to the edge of the drawn area =
  a soft bevel) plus a little from brightness, then the slope (Sobel) as
  the normal. Published methods for pixel art (bevel, Sobel; see the
  sources) give a convincing raised look for blocks, pipes, rocks and Keen.
  A per-game table can switch it off for flat things (signs, the HUD, text).
- **Tiles.** Keen 1-3 draw tiles with `LevelTileSet` atlases; Keen 4-5 with
  `GalaxyTileAtlas`. The safest way to give a tile layer its normals is a
  material with our own canvas shader that reads a second atlas (same
  layout) and writes `NORMAL_MAP`; whether a `CanvasTexture` in the
  `TileSetAtlasSource` works as well is to be checked in the first build.
- **Light sources, from our own tables per game** (tile and sprite numbers,
  written by us, no game data): lamps (Keen 1's blue lamp 156, Keen 2's
  lights), shots, explosions, fire and lava, exit signs, Keen 2's Tantalus
  machine, Keen 4's fire and lava, Keen 5's fuses and electricity. One
  `PointLight2D` per visible source (pooled; the Compatibility renderer has
  a limit of lights per item), plus a soft "sky light" from above outside.
- **Shadows and occlusion.** Solid tiles cast soft shadows from strong
  lights; a cheap ambient-occlusion pass darkens inside corners (worked out
  from the tile behaviour the game already knows).
- **Rules that keep the game as it is:** light never makes something
  invisible that the original shows, never shows what the original hides.
  Keen 2's darkness keeps its strength (it is gameplay); in realistic mode it
  may become darkness with the lamps glowing in it, but never darker than
  now. Split screen: each half shows the same lights (both viewports share
  the level's canvas, to be checked as for `LevelWall`). Player 2's colour
  shader keeps working on lit sprites.

## 5. Layer C: realistic backgrounds

The backdrop system (`LevelBackdrop`, `LevelWall`, `BackdropPictures`,
`BackdropHoles`) already decides per game which pixels show a picture, and
finds pictures in `assets/backgrounds/...` with the player's own folder
winning. A realistic set is one more folder, e.g.
`assets/backgrounds/realistic/keenN/`, used when the option is on (falling
back to the painted ones).

Where realistic pictures can come from, without breaking the rules:

- **NASA/JPL photographs**: Keen 1 is on Mars, and the Mars rover panoramas
  (Curiosity, Perseverance) are in general not under copyright (NASA's
  media guidelines; credit asked). Real Martian landscapes behind Keen 1's
  levels. Space pictures for Keen 5's station and Keen 2's windows-less
  ship walls as real metal plates. Each picture is checked one by one before
  it goes in (some NASA pages carry third-party images).
- **Generated from text only** (no game image in the input), with a model
  whose licence allows it; then it may be committed like our painted ones.
- **Our own painters** (`tools/background_painter.py`), as now, with a more
  photographic style.

Pictures still only show in widescreen (the 4:3 picture is always the
original, decision of the user) unless the user decides otherwise.

## 6. Layer D: realistic graphics made by AI

### The models (state of October 2026)

| Model | Fit | Licence | On a 16 GB Mac |
|---|---|---|---|
| SDXL + ControlNet Tile (e.g. xinsir) | keeps shapes and colours of the input, adds texture; mature tooling (`diffusers`) | CreativeML Open RAIL++-M | yes, ~7 GB, ~0.5-1 min per 1024² image (to measure) |
| SD 1.5 + ControlNet Tile (the parked plan) | the same, weaker detail | CreativeML Open RAIL-M | easy, ~6 GB |
| FLUX.1 Kontext [dev] (12B) | edits by instruction ("make this photorealistic, keep the layout"), strong detail | FLUX.1 Non-Commercial | only quantised, slow (to measure) |
| Qwen-Image-Edit (20B) | the same kind as Kontext | Apache 2.0 (to confirm on the model page) | too large for 16 GB without heavy quantisation |

Advice: **SDXL + ControlNet Tile** first (it fits the Mac, its licence is
clear and ControlNet Tile is made for "keep this picture, add detail"), and
Kontext as a second candidate in the trial only if SDXL falls short.

### How it fits in

- **Same as HD**: the player runs a tool on their own computer; the result
  lands next to the game files (`game_data/keenN/realistic/`, ignored by
  git) and is never shared. The game reads it like `HdPack` and takes the
  transparency from the original mask (enlarged, softened; the user's
  choice: original pictures as input, not xBRZ), so outlines and holes stay exactly where
  the game expects them (backdrop holes, masked tiles, Keen 2's lattice
  walls all keep working, because they are cut from whatever larger tile
  there is).
- **Extra sheets**: `*_normal.png` (from a depth model on the generated
  pictures, e.g. Depth Anything; better relief than layer B's estimate) and
  `*_emissive.png` (what glows), used by layers A and B.
- **Tools**: `export_hd_sheets.gd` and `make_hd_graphics.sh` become
  game-agnostic (they are Keen 1 only now); a new
  `tools/make_realistic_graphics.sh` with a Python script (`diffusers`,
  PyTorch on Apple's MPS or CUDA on Windows) does the generation.
- **Keen 4 and 5** need HD-style packs first: `GalaxyScaledGraphics` only
  knows xBRZ. Their sheets are much larger (~4,000 tiles, many empty or
  repeated), so they come after Keen 1-3.

### Known problems and how to meet them

1. **Flicker in animations.** Every frame of Keen or a Yorp generated alone
   gets different details. Generate all frames of one animation side by
   side on one image, with a fixed seed, low denoise (~0.3-0.45) and one
   "reference" frame (IP-Adapter); keep the original silhouette (the
   original mask). This is the hardest part; the trial must show it works before
   anything else is made.
2. **Seams between tiles.** Generate each tile in the middle of its
   neighbours as they occur in the levels (or 3x3 copies of itself for
   repeating ground), keep the middle; things of several tiles (pipes,
   machines, the ship) as one piece.
3. **Repetition.** A photo-like rock tile repeated 40 times reads as
   wallpaper, more than the flat original. A shader can vary each cell a
   little (brightness, a large-scale detail texture at the cell's place in
   the level, like `level_wall.gdshader` does).
4. **Readability.** Items, enemies and hazards must still stand out:
   keep their EGA colour as the main colour (colour transfer to the
   original after generation), a subtle dark outline or rim light on
   sprites, never on the background.
5. **Style mix.** A real stone world with a cartoon Keen can look odd; a
   realistic Keen at 24 game pixels high can be hard to read. The trial
   shows both side by side; the user chooses how far sprites go (§9).
6. **Cost for the player.** Keen 1 roughly 1-2 hours on a Mac (to measure in
   the trial), Keen 4/5 several hours. The tool can resume and do one
   game at a time.

A second, larger idea for later: generate a **whole level as one picture**
(the model sees that a pillar is a pillar) and draw that instead of the
tiles, with everything that changes (doors, items, bridges, switches,
animated tiles) drawn on top. It looks best but breaks tile reuse and needs
per-game rules for every tile that changes; only worth it if the per-tile
way disappoints.

## 7. The option in the menu

The user asked for one extra option to switch it on and off. Proposal:

- `DisplaySettings.realistic: bool`, default **off**, stored as `realistic`
  in `settings.cfg`; one item **REALISTIC: ON/OFF** in the options of all
  five games (`MenuController._options_menu`, `GalaxyMenuPages.options`),
  handled in `MenuController._toggle_option`; **F8** in a level, next to F5
  and F6, with a message like the graphics one.
- On: layers A-C always; layer D when the player has made the pack for this
  game (otherwise it uses the current Graphics choice, xBRZ advised, and says
  once in the status line how to make the pack, like HD now).
- Off: exactly as now. `is_original_picture()` also checks `realistic`.
- Code: one shared node (e.g. `RealisticLook` in `src/graphics/`) that
  `GameScreen` adds to the `World` viewport and the `%Screen` pass, so all
  five games get it through the base class; game-specific tables
  (light sources, colour grade) in each game's own folder
  (`src/keen2/`, `src/keen4/`, ...), so Keen 1 code and the frozen parts
  stay as they are.
- Online: purely local, nothing in the protocol changes; the host and the
  one who joins can each choose.
- Tests: the order-sensitive menu tests get the new item; a new suite checks
  that with the option off every frame is the same as now (the regression
  scripts `tools/keen1_regression.sh` ... `keen5_regression.sh`), and that
  with it on the game state (positions, boxes, score) is identical.

## 8. Proposed milestones

| # | Milestone | Content | Needs |
|---|---|---|---|
| R1 | Research | this file | — |
| R2 | The option + atmosphere | setting, menu item in five games, F8, post-processing chain (layer A), tests | nothing |
| R3 | Light and relief | normals worked out at start, light-source tables per game, soft shadows, corners (layer B) | nothing |
| R4 | Realistic backgrounds | NASA pictures for Keen 1, photographic walls/skies for the others, depth blur (layer C) | the user's eye on each picture |
| R5 | AI trial | ~10 pictures (Keen standing and walking, a Yorp, a few tiles of level 1, the map) side by side: xBRZ, SDXL+ControlNet, maybe Kontext | the user's approval to download the models; run on the Mac |
| R6 | AI pack Keen 1-3 | game-agnostic sheet tools, the generation tool, normal/emissive sheets, reading the pack | R5 approved |
| R7 | AI pack Keen 4-5 | HD-style packs in the Galaxy engine, the tool for Galaxy sheets | R6 |
| R8 | Side by side and polish | every game with the option on and off, regressions, builds | — |

R2-R4 give a visible result in every game without any download; R5 decides
whether R6-R7 are worth it. From the times in `docs/doorlooptijden.md`
(30-90 minutes per milestone), R2-R4 are roughly 1-2 hours each; R6-R7
depend on the trial, plus the player's own compute time.

## 9. Open questions for the user

1. How far: "realistically lit" (original shapes, real materials, light and
   shadow) or fully photographic sprites as well?
2. A separate REALISTIC ON/OFF option (advised), or a fourth value of
   Graphics?
3. May the AI models (~7 GB for SDXL + ControlNet Tile, from Hugging Face,
   into a folder git ignores) be downloaded for a trial on the Mac?
4. Start with R2 (the option and atmosphere in all five games), or first the
   AI trial (R5)?

### The user's answers (24-10-2026)

1. **Realistically lit**: original shapes, real materials, light, shadow and
   atmosphere. Added the same day: **it may come close to photorealistic**
   ("het mag ook tegen foto realistisch aan zitten"), sprites included, as
   long as the risks are covered and everything runs well ("het is
   belangrijk dat het allemaal goed loopt"). So the trial aims high and §10
   sets the checks every step must pass.
2. **A separate option REALISTIC ON/OFF** in the options of all five games,
   with F8 in a level (§7).
3. **Yes to an SDXL trial** (SDXL + ControlNet Tile, ~7 GB, into a folder git
   ignores), **with the original pictures as input, not xBRZ** ("dat vond
   ik toch iets minder mooi"). So the trial feeds the original tiles and
   sprites, enlarged by whole pixels (nearest), to the model; the
   transparency comes from the original mask enlarged the same way and
   softened, not from xBRZ. This replaces "Base: the xBRZ images" of the
   parked plan in `docs/graphics.md`.
4. **R2 first** (the option and the atmosphere in all five games), then R3,
   R4 and the AI trial R5.

## 10. How the risks are covered

The user's condition (24-10-2026): the risks must be covered and
everything must run well. Every risk gets a measure and a check that is
measured, not judged by eye alone; a milestone is only done when its checks
pass. The checks run headless where they can (tests, `tools/scripted_play.gd`,
the regression scripts) and are written down per milestone in `PROGRESS.md`.

| Risk | Measure | Check (pass when) |
|---|---|---|
| The option off changes something | All realistic code is behind `DisplaySettings.realistic`; `is_original_picture()` and every existing path are untouched when it is off | `tools/keen1_regression.sh` ... `keen5_regression.sh`: every frame equal to `main` with the option off; all tests green, `gdlint` clean |
| Gameplay changes with the option on | Only drawing changes; textures keep the original size (`set_size_override`), no game code reads the new images | A new suite plays the same input with the option off and on (each game, a level and the map) and compares the game state every tick: positions, boxes, score, lives, RNG: identical |
| Frame rate (it must run smoothly) | A budget per layer; lights pooled and capped; post-processing at reduced resolution; work done at level start on worker threads, as xBRZ now | A built-in measurement (frame time over 30 s in the heaviest level of each game, split screen included): on the user's Mac and on the Windows PC at least 60 fps steady, 99 % of frames under 16.7 ms; on a 120 Hz screen with smooth motion under 8.3 ms. If a layer misses the budget it gets a lower setting automatically, never a stutter |
| Level start gets slow | Normals and holes worked out once and kept (as `GraphicsLoader` keeps xBRZ); the game keeps running with the current graphics until the new ones are ready | Time from level start to the first frame not more than now + 0.3 s; switching F8 never freezes the game |
| Memory | Packs at 4x (64 px per tile, plenty for 1080p; 8x only if the trial shows it is needed), Galaxy per level as now | Video memory of the heaviest level measured; under 1 GB on the Mac with 16 GB |
| Flicker in animations | All frames of an animation in one image, fixed seed, low denoise, one reference frame, the original silhouette | A tool compares every animation: the change between two frames of the AI version may not be larger than in the original (per pixel, inside the silhouette, after alignment); every animation is also shown to the user as a moving sheet before it goes into the pack |
| Seams between tiles | Tiles generated in their neighbourhood; one pass that blends the edge pixels with the neighbours they have in the levels | A tool lays every level out with the pack and measures the colour jump across every tile edge; no edge may jump more than the same edge in the original (enlarged) |
| Repetition | Per-cell variation in the tile shader (brightness, a large detail texture at the cell's place in the level) | Screenshots of the widest flat areas of each game shown side by side to the user |
| Readability (items, enemies, hazards) | EGA colour stays the main colour of each item and enemy; light rim on sprites; backgrounds darker and softer than the play layer | Contrast of every sprite and item against the tiles behind it in each level at least that of the original; the user plays a level per game before it counts as done |
| A broken or missing pack | The pack is checked against the game files as `HdPack` does; on any fault the game says so once and stays on its current graphics | Tests with a missing, too small and corrupt pack: no crash, the status line message, the original picture |
| Split screen, two players, online | The realistic look hangs on the shared `GameScreen` and the level's canvas, so both halves get it; nothing goes over the network | Scripted play with F7 in each game with the option on; online host and join each with their own setting |
| The AI trial looks bad | R6-R7 only start after the user approved the trial (R5) | The user's yes on the side-by-side pictures of R5 |
| Player's compute time | The tool resumes after a stop, does one game at a time and says how long it will take | Measured in R5 on the Mac and written in the guide |

## 11. What is built

- **R2 (branch `milestone-r2-realistisch-optie`)**: the option Realistic
  (F8, Options in all five games, `settings.cfg` key `realistic`) and the
  atmosphere layer (bloom, colour grade per game, vignette, grain). How it
  works: `docs/graphics.md`, "The realistic look (R2)". Checks of §10 done
  in the cloud: option off = every Keen 1 regression picture equal to
  `main`; the game state equal with it on (`test_realistic_look`); the
  automatic fallback; frame times only in software rendering (the real
  numbers need the Mac and the Windows PC, `tools/measure_frames.gd`).

- **R3 (branch `milestone-r3-realistisch-licht`)**: light and relief in
  the same layer, without normal maps: slopes from the brightness of the
  picture (a bevel along every outline, lit from the upper left) and up to
  16 lights per view from lit tiles and shots (`RealisticLights`; Keen 1's
  table in `Keen1Lights`). Deviation from §4: normals come from the
  finished picture on the screen instead of per texture, so one shader
  covers all five games and every kind of graphics (original, xBRZ, HD,
  later the AI pack) without touching their drawing code. Shadows cast by
  walls are not built (a later step if the look asks for it).

## Sources

- Godot 2D lights and shadows (normal and specular maps through
  `CanvasTexture`, `PointLight2D`, `LightOccluder2D`):
  https://docs.godotengine.org/en/4.6/tutorials/2d/2d_lights_and_shadows.html
- Normal maps on tile maps (open question in Godot 4.3):
  https://forum.godotengine.org/t/is-there-a-way-to-add-normal-maps-to-tilemap-in-godot-4-3/90479
- Normal-map techniques for pixel art (bevel, Sobel, a learned model):
  https://arxiv.org/pdf/2212.09692
- Light the Sprite, light maps from pixel art (Eurographics 2025):
  https://diglib.eg.org/handle/10.2312/egs20251032
- Laigter, an open sprite normal-map tool (as documentation):
  https://laigter.readthedocs.io/en/latest/Introduction/intro.html
- Relighting from depth maps (smoothing depth before deriving normals):
  https://tympanus.net/codrops/?p=119000
- Consistent sprite animation is a hard, separate problem:
  https://arxiv.org/html/2412.03685v2
- FLUX.1 Kontext [dev] and its non-commercial licence:
  https://bfl.ai/blog/flux-1-kontext-dev
- Qwen-Image-Edit (licence to confirm on the model page):
  https://dev.to/czmilo/2025-latest-complete-guide-to-qwen-image-edit-image-editing-model-2kd5
