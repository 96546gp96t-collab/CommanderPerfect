# Keen 4: the rules of a level in our engine

What a Keen 4 level does in CommanderPerfect so far, and where its numbers
come from. Written in milestone D3 (drawing a level), D4 (Keen moves), D5 (the
creatures) and D6 (platforms, the council, under water); later milestones
add to it. The facts and their sources are in
[research.md](research.md), the code layout in
[architecture.md](architecture.md), the files in
[file-formats.md](file-formats.md). Numbers from Omnispeak are marked
(Omni), what was seen in the user's v1.0 in js-dos "(seen)".

All positions are the original's **global units**: 16 per pixel, 256 per
tile. Times are **tics** of 1/70 s.

## The course of the game (D4)

| What | Then |
|---|---|
| Keen 4 picked on the start screen | Level 1 (Border Village), played; there is no title or menu yet (D8, D10) |
| `-- --game=4` | Level 1 |
| `-- --game=4 --level=N` | Map N: 1-19 are played (17, the Well of Wishes, swum: D6); 0 (the world map) is only shown, with the D3 look-around (D7); another number: a message |
| Keen walks out of the level (left or right) | The next level (after 16 the Well of Wishes, after 17, 18 and 19 level 1 again); the world map comes in D7 |
| The Foot carries Keen off (D5) | The level is done (the flight over the world map is D7's) |
| Keen rescues a council member, or takes the wetsuit (D6) | The message boxes, each until a key is pressed; then the next level. After the eighth rescue the status line says so (the end is D8's) |
| Lindsey, the janitor (D6) | Their boxes; the level goes on |
| Keen dies | One life less; the level starts again (fresh, without the gems); with no lives left (fewer than 0): "Game over" and the start screen |
| Shift+N / Shift+P | The next or previous map (0-19, round) |
| Arrows / WASD, jump, pogo, fire | Keen (the shared keys: Ctrl or Z jump, Alt or X pogo, Space or C fire); on maps 0 and 17 the arrows look around |
| Shift+G | God mode on/off (the original's debug key F10+G): nothing kills Keen, except falling out of the level |
| Escape | Back to the start screen |
| F1-F6 | As in Keen 1-3: help line, widescreen, pixel shape, full screen, graphics (original / xBRZ), smooth motion |

A new game starts with 3 lives, 5 stunner charges and the first extra life
at 20,000 points (Omni); what Keen carries goes from level to level.

## Keen's moves (D4)

Keen is the original's state machine (`GalaxyKeen`, his actions in
`GalaxyKeenActions` with Omnispeak's numbers): every action has its sprite
facing left and right, a type, a timer in tics, a velocity and three
functions (think, contact, react). A logic frame runs his action for the
frame's tics, then moves him with the tile collision (`GalaxyClip`), then
the contacts, the tiles he touches, and the reacts (`GalaxyWorld`, the
original's order). Speeds are units per tic.

| Move | How (Omni unless marked) |
|---|---|
| Standing | After 200 tics without a key he looks up (60 tics), after 300 more he is bored (two waiting sprites), after 700 more he sits down and reads a book (until left/right, jump or pogo); in level 11 on the moon spot (misc 16) he shows the moon instead of being bored |
| Walking | 24 a tic (frames of 6 tics; the first frame a quarter); on a slope the floor's slope adds +4 (gentle, down to the right) / +8 (steep) per tic, −4 / −8 up to the right: walking up a slope is 20 a tic, down 28 (seen: 30 instead of 36 pixels per 24 tics uphill). His feet stand on the slope's height under the middle of his box. Walking off a ledge he falls with 8 sideways; a wall stops him |
| Jumping | −40 a tic for up to 18 tics while jump is held, then gravity (+4 on every odd tic, at most 70); in the air left/right +2 on odd tics up to 24, without them −1 towards 0; from a walk 16 sideways. **Held: 67 pixels** (seen; Omnispeak's scratch model said 70, see below); a jump held 3 frames 37 pixels (seen) |
| Pogo | First bounce from the ground: −48 and at once 6 × −48 up (at most 239 a frame); every bounce −48 for 24 tics: with jump held (or in the last 9 tics) the speed stays (no gravity, seen), otherwise gravity. **Held: 105 pixels a bounce; not held: 41** (both seen); the first bounce from the ground 50-56. Left/right +1 on odd tics up to 24, without them he keeps his speed. Pogo again: he falls |
| Ceilings | A ceiling stops the jump; a sloped one only slows it by 16; a pole hole lets him through onto the pole's column |
| Looking | Up: look up (the view moves 1 px a tic up to 167 / 33 px); down: look down; down + jump on a thin floor (flat top, nothing else on that tile or the one below) drops him through it |
| Shooting | Standing 9 + 6 tics (also up, then looking up); in the air ahead, up and down (9 + 1 + 6 tics, falling meanwhile); on a pole ahead, up and down. The shot starts at fixed offsets from Keen (Omni CK_KeenSpawnShot) |
| Poles (misc 1) | Up (the pole at his head + 96) or down (the pole under his feet) grabs it: he goes to its column and is not clipped. Climbing 8 a tic, sliding 24 (both seen: the view follows him 1 and 3 px a frame); at the top he stops with his head just over it; at a floor he stands looking down; at the pole's end without a floor he falls. Jump: −20 for 10 tics, sideways −8 / 0 / 8 by left / none / right; no grabbing for 19 tics. Left/right at the bottom (a floor under him) steps off |
| Ledges | Falling with left or right held, when the top of his box passes 64 units under a tile's top where that tile is a wall (side and top) and the tile above it is free: he hangs (12 tics, then waits). Up or towards the wall: four pulling steps of 10 tics (128 units each) and he stands on top, drawn in front of the ledge's tile unless that one is in front anyway; down or away: he falls |
| Doors (misc 2) | Up at a door: he walks to its spot (96 into the door tile, a tile less for a two-wide door) 16 a tic, then 5 × 9 tics walking in (−64 each); then he stands at the info plane's target under the door (x high byte, y low byte), one tile above it; the view is put on him again; 110 tics nothing hurts him. Seen in level 1: the door at x 77-78 leads to the room with four sodas, the one at 66-67 to the room with the pole, as ours |
| Switches (misc 5, 6, 15) | Up at a switch: he walks to its spot (−64 from the tile), presses it (8 + 8 tics): the switch tile moves on by its animation offset; a bridge switch moves the bridge's two rows (the second from one tile further left) on by their offsets; another switch turns the platform turn point at its target on or off (info XOR 0x1F; the platforms follow it since D6) |
| Dying | A deadly tile (misc 3) under his box, a deadly floor (top 8-15), or falling below the level (also in god mode): one of two death sprites at random, −40 up and 16 sideways under gravity +3, nothing clips him, the view stands still; once he has left the view the level is lost. Nothing kills him for 30 tics after a death started and 110 after a door |

### The frames and the odd tics (seen in the original, D4)

A level's first logic frame covers 3 tics, every other frame 2 (Omni
CK_PlayLoop), so from then on every frame starts on an odd tic: gravity and
acceleration (which act on odd tics) change the speed *before* the frame's
first tic is moved. Omnispeak's numbers in the research (70 px for a jump)
came from a scratch model with frames on even tics; in the original the
held jump rises 5 pixels a frame for 9 frames and then 4, 4, 4, 3, 2, 2, 2,
1, 0, 0: 67 pixels, exactly what our engine does with the odd frames.

## The creatures (D5)

Every creature is its own class with its own action table (rows as for
Keen; `src/keen4/actors/`), numbers from Omnispeak (Omni) unless marked
(seen). A creature is placed by its info value, with its own rise above
the info tile's corner, and faces right or left by a coin toss of the
random table unless said otherwise. "Kills" means touching it kills Keen
in any state (on a pole too); the original does that in the creature's
own contact.

| Creature (info) | What it does | Kills Keen | The stunner |
|---|---|---|---|
| Poison slug (22, 43, 44) | Crawls 64 units every 8 tics, turns at walls, ledges and deadly floors; 16 in 256 at every second step it stops 60 tics facing Keen and leaves slime (kills 300 tics, fades 60) | touching it, the slime | stunned for good: hops −24, slides 8, stars half a tile above |
| Mad Mushroom (21) | Hops in place under gravity mid, facing Keen: −40, −40, −68 (seen: 31 px hops and a big leap) | touching it | nothing (the shot stops) |
| Egg (13) | Lies still; Keen or a shot breaks it: the shell stays, three bits fly off (−28/−40, 28/−40, 0/−56), the bird hatches facing Keen (seen: an egg on Normal) | no | breaks it |
| Bird (77, 78; hatched) | Stands 120 tics, walks 128 units every 7 tics to Keen (seen), turns at walls; when Keen stands on the ground 3 tiles higher it flies (speeds up 1 on odd tics, at most 16, plain box 1024 × 512) and lands near his height; off a ledge it flies too | touching it walking or flying | 240 tics, blinks 80, walks again |
| Arachnut (20, 73, 74) | Runs 128 units every 6 tics (seen), to Keen every 4th step | touching it | 240 tics (no stars), blinks 80, runs again; stunned again by a shot meanwhile |
| Skypest (8, 45, 46) | Flies at random (1 a tic on odd tics, at most 20; turns with tics in 256 a frame); a ceiling sends it down, a wall turns it; lands on a floor and preens 400 tics (seen: 10-tic pictures, 100-tic rest), takes off at −16 | in the air | only pushed (20 the shot's way); **squashed for good when Keen lands on it on his pogo stick while it preens** |
| Wormmouth (7, 51, 52) | A mound sliding 16 a tic to Keen; far from him (over 3 tiles) it sometimes peeks left and right; close in front (right 128-384 units, left 128-512, within a tile up or down) it bites (8, 8, 16, 8, 8 tics) | only the bite, only in front | as a mound nothing; peeking or biting stunned for good |
| Cloud (9) | Sleeps until Keen touches it, wakes 100 tics, drifts after him (1 on odd tics, at most 10); with Keen under it (his head at most 4 tiles below) it lines up on 8 pixels, flashes 8 × 10 tics and strikes at the 4th; the bolt kills 48 tics; then drifts 60 tics | the bolt | nothing (the shot flies through) |
| Berkeloid (5, 49, 50) | Floats 8 a tic along the ground, turning at walls and ledges; its picture bobs between 0 and a tile up (8 a tic); throws (12 × 6 tics, the ball at the 6th) with 8 in 256 a step, or 64 in 256 when Keen is ahead within a tile up or down. The fireball flies 48 sideways from −8 under gravity mid (seen) and burns 102 tics on the ground | touching it, the fireball (flying and burning) | nothing |
| Lick (14, 47, 48) | Hops after Keen: long (32, −32) when he is more than 3 tiles away, else short (16, −16), resting 10 tics before and after; close in front it breathes fire 8 × 4 tics (seen) | only the flame, only in front | stunned for good (hops −8) |
| Mimrock (19) | A rock that looks every 20 tics; Keen within 5 tiles up or down, more than 3 away and facing away: it sneaks 64 every 6 tics; still behind him within 4 tiles it leaps (20, −40, gravity mid) and bounces once (−20); he turns round: it sits | only the leap | sitting nothing; sneaking or leaping stunned for good (hops −16) |
| Bounder (12) | Bounces −50 (gravity high; seen: 39 px, 24 sideways); three bounces in place, then every other one left (100 in 256), right (100 in 256) or up, 24 sideways; walls turn it | never: it pushes Keen out of its way and knocks him off a pole or ledge | stunned for good (hops −32), and then a platform |
| Smirky (18) | Stands 40 tics, looks: jumps (−48) for item tiles up to 3 above, hops (20, −24) where there is ground 4 tiles ahead, else back; after two misses (no ground, or walls) it vanishes in a puff (4 × 20 tics) and appears at an item still lying in the level; with none left it is gone. It eats item tiles and drops its box touches in the air, and items lying as sprites it touches | no | stunned for good (hops −16) |
| Inchworm (11) | Creeps 128 every 30 tics to Keen, out of step; a worm touching 11 others in one frame becomes the Foot (5 tiles higher, four puffs), the other worms are gone | no | nothing |
| The Foot (10, or from the worms) | Stands; Keen walking into it is carried off: the level is done | no | nothing |
| Dart gun (53-56 all, 79-82 Normal, 83-86 Hard: up, right, down, left) | Unseen (part of the tiles); every 150 tics while near the view a dart, 64 a tic, gone at a wall or off the screen | the dart | nothing |

**Riding the Bounder.** Keen lands on a Bounder (or a stunned one) and
rides it: every frame he moves with it, standing on it (Omni
CK_KeenRidePlatform); he leaves it by jumping, walking off its sides or
bumping his head. While he rides a living Bounder, he steers it: standing
more than 64 units left of its box it goes left, right of it right,
otherwise straight up.

## Platforms and switches (D6)

| What (info) | How (Omni unless marked) |
|---|---|
| Platform (27-30: up, right, down, left) | At its tile's corner, always awake, behind everything (priority 0). 12 units a tic (seen: 52 px a second). When its leading edge is about to enter a tile whose info value is a **turn point** (31), it stops on that tile's edge and turns. Going up, a second turn point two tiles below the one ahead holds it there; going down, one two tiles above (it stands still while both are there) |
| The jets (Keen 4) | Going right a side jet at its left; going left one at its right, in front of the platform; going up two jets under it; going down the same two every other 4 tics. Their two pictures change every 4 tics |
| Riding | Keen landing on a platform (walking, jumping, falling, on the pogo) rides it: he moves with it, standing 16 units above its box, his x keeping its lowest bits (D5's riding). A platform that touches him on a pole or ledge makes him fall onto it |
| Falling platform (32) | Floats until Keen stands on it; then sinks 16 a tic; half a tile down it falls under gravity high; its bottom stops on the edge of a turn point below; without Keen it rises 32 a tic to its place and floats; Keen landing on it while it rises makes it fall again. Not clipped by tiles: without a turn point below it falls out of the level |
| Platform switch (misc 5) | Up at it: the switch flips and the turn point at its target (info under the switch: x high byte, y low byte) is turned on or off (info XOR 31), so a platform stops, turns or goes on at once (D4's switch) |
| Bridge switch (misc 15) | The bridge's two rows at its target (the second from a tile further left) move on by their animation offset: the bridge extends or retracts (D4) |
| Mine (69-72, level 17) | Moves like a platform; touching Keen it explodes (two pictures of 30 tics) and kills him; he cannot ride it |

## The council, Lindsey and the wetsuit (D6)

| Who (info) | What (Omni unless marked) |
|---|---|
| Council member (4) | 369 units above his tile, a random facing; shuffles 64 every 10 tics, turning at walls and ledges; at each step he stops to think with a chance of (tics × 8) in 256 (120 tics, then a step of 128). Keen touching him while standing on something (not on a pole, a ledge, in the air) rescues him: the level is done and the boxes follow |
| The janitor (4 in level 14) | Touched like a member: five boxes, then he is gone; he does not count, the level goes on (seen) |
| Princess Lindsey (6) | A tile above her tile, bobbing (1 on odd tics, at most 8 a tic, turning 32 units from her place), four pictures of 20 tics. Keen touching her: her boxes, then she is gone (seen) |
| The wetsuit (35) | A tile above its tile. Keen touching it while standing: his boxes, Keen has the wetsuit (for the world map, D7), the level is done |

## Message windows (D6)

Every box is the original's window (`GalaxyWindow`; seen in the
original: the same pixels): 26 × 8 cells of 8 pixels in the middle of the
320 × 200 screen (inside 56, 64 to 264, 128), white, framed by the masked
8×8 tiles 0-8; the text in the menu font, black, each line centred. The
one who speaks first has his picture at the window's left edge and his
text 6 pixels down beside it; Keen's picture is at the right edge, his
text 12 pixels down. The game stands still while a box shows; every new
key or button press shows the next (F1-F6 still change the picture).

| Box | Screens |
|---|---|
| Council member | The elder's thanks (in level 17 the bubbly version); Keen's answer (eight different ones, by how many were rescued before); the same box with Keen's thumb up |
| The janitor | His first two texts; Keen's reply; his last text; Keen alone with his cross face, no text |
| Lindsey | "Princess Lindsey says:" and her hint (level 7: the wetsuit in Miragia; level 5: the way to the Pyramid of the Forbidden); Keen's thanks; his thumb up |
| The wetsuit | Keen's words; his thumb up |

The texts are the player's own, read from the program; the pictures are
the last ones of the picture range (file-formats.md). In widescreen the
window is in the middle of the wide picture.

## The Well of Wishes (D6)

Level 17 is swum (`Keen4SwimmingKeen`, info 42 at the tile's corner,
facing right, priority 1):

| What | How (Omni unless marked) |
|---|---|
| Moving | Every tic by his speed; every 8th tic the speed relaxes: sideways towards 0 (3 above 12 either way, else 1), up and down towards 4 (3 above 12, 1 above 4, 1 from below 4, 3 below −12); the stick adds 2 the way it is held. Nothing held: he sinks 4 and 5 by turns (seen: 20 px a second) and drifts 2 px a second right (seen); held: about 12 a tic (seen: 50 px a second after a second) |
| Kick | Jump: 18 in each direction held, and his other picture (50 tics each otherwise); with nothing held no change (seen) |
| Clip | A simple box of 640 × 384 units; walls stop him sideways, floors and ceilings up and down |
| Bubbles | One every 60 tics from his head; they rise 24 a tic, wobble, and are gone at the top or off the screen |
| Taking | Items as on land; touching the council member rescues him (the bubbly thanks) |
| Dying | A mine, a sprite or its shot: he flies off in his suit as on land. The Dopefish eats him (not in god mode): he is held in its mouth, swallowed, and 180 tics later the level is lost |
| The view | As on the world map: his box stays between 144 and 192 pixels from the left and 80 and 112 from the top, at most 255 units a frame (seen: the view starts to follow when he sinks below 112) |

| Creature (info) | What it does (Omni) |
|---|---|
| Dopefish (15; 87 from Normal, 88 on Hard) | Three tiles above its tile, priority 2, a box of 1408 × 1024; swims after Keen (1 on odd tics, at most 10 a tic); a wall turns it. Touching a school fish or Keen it eats: swims 32 a tic until its mouth is at the prey (32 beyond its box, a tile above), swallows, rests 60, burps a bubble after 60 more, rests 60, swims back to where it began and on |
| School fish (16) | Swims after Keen like the Dopefish, a box of 256 × 128; harmless |
| Sprite (17; 23 from Normal, 24 on Hard) | Bobs around its place (1 on odd tics, at most 8, turning 32 away); Keen level with it: it faces him, aims 40 tics, and if he is still level shoots (64 a tic sideways, gone at a wall), then rests 30. Touching it or the shot kills |
| Mine (69-72) | See "Platforms and switches" |

## The stun (D5)

A stunner shot that touches a creature calls its contact; the creatures
that can be stunned stop the shot, switch to their stunned action and hop:
their vertical speed −24, at most −48 up (Omni CK_StunCreature; the
Bounder, Mimrock and Smirky add −32 / −16 / −16 themselves, the slug sets
−24 and slides 8, the Lick hops 16 less). A stunned creature counts as
stunned: Keen's checks no longer see the living creature (the stunned
Bounder carries him instead of pushing). Its stunned action falls under
gravity high; when it lands the stunned picture follows. **Stars** turn
over it (sprites 40-42, three frames of 10 tics, in front of everything)
at an offset per kind: slug and Lick half a tile up, Bounder 64 right and
half a tile up, Wormmouth 64 right and 350 up, Smirky half a tile right,
Mimrock none. The Arachnut and the bird show no stars and wake up again
(240 + 80 tics). Stunned creatures give no points. Off the screen a shot
still stuns what sleeps in its way (D4).

## Difficulty (D5)

The info plane places some creatures only from Normal on and some only on
Hard (Omni CK4_ScanInfoLayer; research.md §6); `Keen4Creatures.PLACED`
lists each value with its lowest difficulty. The level session takes the
difficulty as a parameter; until the menu lets the player choose (D10) it
is **Normal**. In v1.0 the info planes of levels 1-16 hold over 300 creature values;
level 1 has two Bounders and two slugs on Easy, a third slug on Normal, two
Licks more on Hard.

## Items and tiles (D4)

| What | Then (Omni) |
|---|---|
| Point items as sprites (info 61-66: soda 100, gum 200, candy bar 500, jawbreaker 1000, doughnut 2000, ice cream cone 5000) | Two frames of 20 tics; touched: the points, and the item's "shadow" (the number) rises 8 a tic for 40 tics in front of everything |
| Gems (info 57-60: red, yellow, blue, green) | One more gem of its colour; the shadow is a plain gem; no points |
| Extra life (info 67, the lifewater flask), stunner (info 68; info 34 only when Keen has fewer than 5 charges) | A life; 5 charges |
| The same items as tiles (misc 21-26 points, 27 life, 28 stunner) | Taken under any part of his box: the tile is gone (tile 0), the shadow rises from it |
| Lifewater drops (misc 4) | One drop; a splash (3 frames of 10 tics); the 100th drop is a life (the count starts again) with a rising 1UP |
| Extra lives from points | At 20,000, then 40,000, 80,000, … (each threshold doubles) |
| Gem holders (misc 7-10) | Standing on one with a gem of its colour: he walks to its spot (−64 from the tile), puts the gem in (6 tics): the holder becomes tile + 18, and the door at the info target under the holder (the column of equal tiles from there down, and the two tiles under it) moves on by one tile three times, 10 tics apart: it opens |
| Gems at the end | Lost when the level ends, also by dying |

Items lie behind Keen (priority 2) and sleep when they are far from the
view (more than 4 tiles); they wake within one tile of it (Omni).

## The neural stunner (D4)

A shot flies 64 units a tic in one of four directions, with four frames of
6 tics, behind everything (priority 0). It stops at the first side of a
solid tile, except a pole hole (top or bottom 17): it moves into the hole's
column and flies on. Where it stops it shows two frames of 12 tics. Off the
screen it still stuns what sleeps in its way (D5); 10 tiles beside or 6
above or below the view it is gone. Without charges nothing comes out (the
original clicks; sound in D9).

## The score box (D4)

The score box is the HUD (decided by the user): the episode's own SCOREBOX
sprite with the numbers drawn into it as the original does (Omni
CK_UpdateScoreBox): the 8×8 digit tiles ('0' is tile 42, a blank 41, so
unused places show the dim "8" of the box), the score right-aligned in 9
places at (8, 4), the lives at (24, 20) and the charges at (64, 20), 2
places each, at most 99. It is drawn 4 pixels from the top-left corner of
the visible picture, in front of everything, in 4:3 and widescreen alike
(in widescreen in the corner of the wide picture). Seen in the original:
the same box, 3 lives and 5 charges at the start.

## Keen at his start

Keen starts where the info plane puts him (`Keen4Start`, `GalaxyKeen.spawn`).

| Info | Keen | Position | Sprite |
|---|---|---|---|
| 1 / 2 | standing, facing right / left | x = tile × 256, y = tile × 256 − 241 (Omni) | 6 / 14 (Omni SPR_KEENSTANDR / L) |
| 3 | on the world map | the tile's corner (Omni, a new game) | 132 (Omni SPR_MAPKEEN_STAND_W) |
| 42 | swimming (level 17) | the tile's corner, facing right (Omni) | 187 (Omni SPR_KEENSWIMR1) |

The standing sprites' hit box ends at 496 units (31 px), so his feet rest
on the last unit of the info tile, on top of the tile below: no fall is
needed. All three are drawn with priority 1 (Omni). In js-dos (seen) Keen
stands at exactly this pixel in levels 1, 4, 11 and 14, and the map Keen
and the swimming Keen too.

## Drawing

- **Three tile layers** (`GalaxyLevelMap`): background tiles; foreground
  tiles behind the sprites; foreground tiles whose TILEINFO misc has bit
  0x80, in front of the sprites. Foreground tile 0 is nothing. Nothing else
  decides what is in front (seen: in level 1 the rock beside Keen's start
  covers his leg when he stands behind it).
- **Sprites** (`GalaxyObjectLayer`) are drawn at position + the sprite's
  origin, on whole pixels: pixel = (position + origin) >> 4 (Omni). With
  smooth motion (F6, off by default) the shared `Interpolation` draws them
  between the last two logic frames.
- **Draw order** (Omni `RFL_DrawSpriteList`): the tiles, then the sprites of
  priority 0, 1 and 2, then the in-front tiles, then priority 3. Within a
  priority the sprite placed last is drawn first (under the others).
- **The whole map is drawn**, its 2-tile border too; the camera never shows
  the border in 4:3, and widescreen covers it (below).
- **Atlases**: one per tile set and level, with only the tiles the level
  can show (its own tiles and every tile of their animation loops); a tile
  put later by `set_tile` that is not in the atlas makes a new atlas.

## Animated tiles

`GalaxyTileAnimator`, with TILEINFO's times (Omni `RFL_AnimateTiles`):

- every tile number that the map starts with gets one cycle, shared by all
  cells that start with it (they move in step);
- a cycle counts down by the tics of each logic frame; at 0 or below it
  moves on to tile + its animation offset (at most one step per frame) and
  adds the new tile's time;
- a tile with an offset but no time (gem holders, bridges) does not move by
  itself; background and foreground tiles alike;
- the map plane holds the tile shown now, so what Keen touches later (D4)
  is the tile on the screen.

The logic frames are the original's: 2 tics each, 35 a second
(`GalaxyClock`), at most 5 tics piled up (the game slows down instead of
skipping). Seen in js-dos (level 1, recorded 6 s): the drops change every
114 ms (8 tics), the tree's eyes after 571 ms and 2,855 ms (40 and 200
tics), a tree every 286 ms (20 tics), a face after 3,140 ms (220 tics):
exactly TILEINFO's times. Only the phase differs from the original (it
depends on when the level started).

## The camera (`GalaxyCamera`)

The original's view is 20 × 13 tiles (320 × 208 pixels; the top 200 are
shown). Everything in units (Omni `id_rf.c`, `ck_play.c`):

- **Map edges**: the view's top left stays between 2 tiles (the border)
  and map size − view − 2 tiles.
- **Scroll blocks**: info 26 is a column, info 25 a row that the view never
  scrolls over (Omni calls 25 a "vertical" block: it stops vertical
  scrolling). The map's border adds blocks at columns 1 and width − 2 and
  rows 1 and height − 2.
- **Putting the view** (reposition): clamp to the edges; then for the first
  block the view covers: when it lies in the left half (columns 0-10 of the
  view, the middle one included) the view goes right of it, when in the
  right half (11-20) the view ends just before it. The same for rows with a
  half of 6.
- **Moving the view** (smooth scroll): when its leading edge reaches a
  block, the view stops on the tile edge; a move of more than one tile puts
  the view again.
- **Start of a level** (Omni CK_CentreCamera): Keen 152 px from the left,
  the bottom of his hit box 140 px from the top (on the world map his
  position 80 px from the top), then put as above. Seen in js-dos: the
  first view of levels 1, 4, 11, 14 and 17 and of the world map is the
  original's to the pixel.
- **Following Keen** (Omni CK_NormalCamera; used from D4): Keen's x stays
  between 144 and 192 px of the view; his feet stay between 33 and 167 px
  from the top; standing (or not clipped, or hanging), the view settles his
  feet back to their place (an eighth of the distance a tic, at most 48, at
  least 16 units a frame), not while he pulls himself up a ledge; looking
  up or down moves 1 px a tic up to 167 / 33; in the air the place goes
  back to 140. At most 255 units a frame. Used from D4 on: before moving,
  Keen's box left of the left limit or right of the right limit plus the
  view ends the level, his feet below the bottom limit plus the view kill
  him; after a death the view stands still. Through a door the view is put
  on him again as at the start.
- **Looking around** (D3, `FreeLook`): the arrows move a point at 240 px/s;
  the view is put on it by the rules above, so it never shows what lies
  beyond a block or the border, and jumps across a block as the original's
  view does when Keen goes through a door.

## Widescreen: covering beyond the scroll area

Decided by the user (19-10-2026): the camera stops at a scroll block as in
4:3, and what the wider view would show beyond it is covered.

- The wide view (426 px with corrected pixels, 356 with square ones) is
  centred on the original's view, then kept inside the **area** between
  the blocks around the view (the nearest block column left of the view's
  middle + 1 to the nearest one right of it, likewise for rows).
- When the area is narrower than the wide view (the Megarocket and the
  high-score map are exactly 320 px wide; level 4 left of its block 416 px)
  the view is centred on the area and the rest is **covered**
  (`GalaxyViewCover`): black, or the picture behind the level when one is
  shown, at the same place as the picture itself, so it runs on.
- The cover is drawn over everything (also the in-front tiles and
  priority-3 sprites). In 4:3 nothing is covered: the picture is the
  original's.

## Pictures behind the levels

An extra, widescreen only, on by default (the shared option). Keen 4's own
pictures go in `assets/backgrounds/keen4/` (none yet), the player's own in
`game_data/keen4/backgrounds/levelNN.png` (they win). Keen 1-3's pictures
are never used.

A Galaxy level's background is pictures made of tiles (trees, hills,
pyramids, rock), not one plain tile, so a picture may only take the place
of **sky** (`GalaxyBackdropPictures`):

- the sky tiles are Keen 4's plain one-colour tiles 1085-1088, 1104, 1105
  (light cyan) and 478 (light blue);
- a level (1-17) may show a picture when the first row the view can show
  (row 2, inside the border) has sky; the most used sky tile there names
  the sky colour;
- the picture shows through that colour where it touches the edge of a
  background tile (around clouds, palm leaves, hill tops), as Keen 1's do;
  colour inside a shape stays.

In v1.0 that gives **levels 5, 7, 8, 9, 10, 11, 12, 13, 14 and 16**. Not
1-4, 6 and 15 (forest, cave or tree tops at the top; level 15 has sky only
between the palms, inside tree tiles), 17 (under water), nor the world map
(its light blue 478 is the lake), 18 and 19. The light blue 478 is the sky
of level 5 but water in levels 8 and 10: there the top row has the cyan
sky, so their water keeps its colour. In level 9 the glass pillars are
sky-coloured inside and let the picture through as well (looked at with a
test picture, not committed).

## Graphics

- **Original**: the tiles and sprites as decoded, on whole pixels.
- **xBRZ** (F5): `GalaxyScaledGraphics` scales the tiles a level shows and
  its sprites six times with the shared `XbrzScaler`, on worker threads
  (~0.6 s for a level on 4 cores), keeps them for the next level, and shows
  the original tiles until they are ready ("Preparing xBRZ graphics...").
- No HD graphics (Real-ESRGAN is skipped for Keen 4).
