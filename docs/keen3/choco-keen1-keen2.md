# Keen 1 and Keen 2 next to Chocolate Keen (information only)

Collected in milestone C1 while researching Keen 3. Chocolate Keen
(github.com/jamesfmackenzie/chocolatekeen) is a reconstruction of the
original v1.31 code; since C1 its facts and numbers may be used (see
`CLAUDE.md`). This file compares it with the estimates of Keen 1 and Keen 2.

**Nothing in Keen 1 or Keen 2 is changed because of this file**: their code
stays as it is (the user's rule). It is here in case the user later wants a
separate milestone to fix those games.

Units: Choco numbers are converted to ours (n/32 pixel per tick at 60
ticks/s; times in our ticks) as explained at the top of
[research.md](research.md). ✓ = Chocolate Keen agrees, ✗ = it contradicts,
~ = close.

## Jump heights: measured in the original Keen 2 (17-10-2026)

In another session the user had Keen measured pixel by pixel in the original
`KEEN2.EXE` (v1.31) in a DOS emulator (js-dos), and compared with our
`src/keen/keen_physics.gd`, which Keen 1, Keen 2 (and Keen 3) share:

| Jump | Original Keen 2 | Ours | Chocolate Keen (converted) |
|---|---|---|---|
| Normal jump, button held | about 54-55 px | 58 px | 55.7 px (up-speed 216) |
| Pogo without the jump button | 50 px | 58 px | about 48 px |
| Pogo with the jump button held | about 104 px | 109 px | about 104 px |
| First bounce with the button ("impossible pogo") | not measured | 122 px | — |

- One bounce takes as long as ours (original 1.1 s low and 1.55 s high,
  ours 1.08 s and 1.53 s): Keen goes up just as long but too far. Probably
  our start speed is a little too high, or the original pulls harder.
- Keen 1 could not be measured (Keen kept landing on a stack of cans and a
  Yorp pushed him away). Keen 1 and 2 share the engine and Commander Genius
  gives them the same pogo, so Keen 1 is most likely just as high.
- The measurements agree with Chocolate Keen's numbers (see "Keen 1" below:
  pogo ~48 px, with jump ~104 px; one gravity for rising and falling), so
  the cause is known: our physics follow Commander Genius.
- **Not changed** (the user's decision, 17-10-2026: write it down, decide
  later). `KeenBody` is shared, so a fix changes Keen 1 and Keen 2 too, and
  Keen 3 inherits the same jumps. The choices are in `PROGRESS.md` (open
  decisions).

## Keen 2 (estimates in `docs/keen2/gameplay.md`)


**World map and ending**

| Estimate | Choco | |
|---|---|---|
| City saved when its level is done | The city flag is set when **anything touches the Tantalus spark** (Keen, Keen's shot, an enemy shot…); only Keen's shot destroys it. Dying in that level clears the flag again. An exit without touching it saves nothing | ✗ (answers open question 14) |
| Status-screen cities | Left column (col 0): London row 7, Cairo 8, Sydney 9, New York 10; right column (**col 10**): Paris 7, Rome 8, Moscow 9, "Wash D.C." 10 | ✗ |
| Status keycards | tiles 424-427 at columns **21, 25**, rows 7 and 9 | ✗ (by one column) |
| At most 7 little Keens | **9** | ✗ |
| Raygun tile 414 col 21 row 3, charges col 24 | same | ✓ |
| Ship flight: wait 10, 672 ticks at (32, 12.8)/32 then 150 at (0, 8)/32 | Map 81 view (0,0); ship (sprite smallshipr) at tile (7, 3); first text typed, wait **300 retraces**; then **120 frames** flying +648 px, +312 px in equal steps (≈ 70/32 and 34/32 per 60 Hz tick, ~4.9 s), view following; wait 120; fade | ✗ |
| Mothership from (8, 26), view (0, 300), 80 ticks at (−32, −12.8)/32 | view (0, 192 px); ship at (160, 272) px; text then wait 120; **120 frames** moving −1 px, −1 px per frame (≈ −13/32 each) | ✗ |
| Texts closed by a press | All ending texts are **timed** (pauses of 300/120 retraces), no key until the end text | ✗ |
| `TO BE CONTINUED....` last page, then the end text | box (12,3)-(32,5), wait 400; then end text (short viewer, KEENSLEFT, full viewer) | ✓ |
| "Keens Left" 3 s | 60 retraces (0.86 s) or a button; at most 6 Keens | ✗ |
| Title / high scores 8 s each | 2400 ticks = **16.5 s** each, cycle Title → About ID → High scores → Ordering info (a Scrub crawling round the screen) | ✗ |
| GAME OVER 4 s (from gameplay.md) | 360 retraces = 5.1 s or a button | ✗ |

**Enemies**

| Estimate | Choco | |
|---|---|---|
| Chances n+1 in 1000 per tick | "byte < k × sync" per frame, k = 1-3 → ≈ 9.5·k in 1000 per 60 Hz tick | different model |
| Grunt 1 HP | 1 | ✓ |
| Grunt walk 28/32 | 90 → 27/32; plus random speed toggles 90 ↔ 120 (36/32), chance 2 | ✓ / ✗ (missing toggle) |
| Grunt 5 ticks a frame | 16 ticks → 6.6 | ~ |
| Look 2 × 16 ticks | 80 ticks → 33, after **every landing** (not at walls) | ✓ duration |
| Jump chance 20 | k = 2 → ≈19 | ✓ |
| Jump 90-149/32 | random 0..300 → 0..167/32 | ✗ |
| Trapped < 160 ticks → jump | no such rule: at a wall it just reverses at 90 | ✗ |
| Turns to Keen within 8 tiles | after every look, no distance limit | ✗ |
| Dying frame 26 ticks | 40 ticks → 16.5 | ✗ |
| Youth 1 HP, run 77/32, 7 ticks a frame | 1; 250 → 76; 16 → 6.6 | ✓ |
| Youth hop chance 100 / 200 at a wall | k = 3 (≈28); no wall chance (it reverses) | ✗ |
| Hops 80/32 or 200/32 | random 0..400 → 0..222/32 | ✗ |
| Frying 21 ticks; corpse slides 20/32 | 40 ticks (16.5); corpse has sideways speed 0 | ✗ |
| Stun 250 ticks | 400 ticks → 165 | ✗ |
| Knocked up 120/32 | takes the youth's velocity (±250 sideways, its vertical speed), slides to a stop | ✗ |
| Stun frames 26 ticks; getting up 20 | 32 ticks → 13.2; 40 → 16.5 | ✗ |
| A shot leaves 20 ticks of stun | a shot **kills** a stunned Keen; in Keen 2 god mode does not stop the stun either | ✗ |
| Elite 4 HP (CG unused 3) | health 2 checked after decrement → **3 shots** | ✗ (CG's 3 is right) |
| Elite walk 31/32, 7 ticks a frame | 100 → 30; 16 → 6.6 | ✓ |
| Elite charge 62/32 when Keen within 2 / 6 tiles | random chance 2: speed toward Keen 200 (61/32) **only if Keen's feet are exactly level with its own**, else 100; no distance rule | ✗ |
| Elite jump chance 15, 90-149/32 | k = 2 (≈19) with lights; random 0..300 | ~ / ✗ |
| Elite aims chance 8, ≥ 26 ticks apart, faces Keen 4 in 5, gun out 23 + 21 | chance k = 2 (only if no jump/charge this frame), **also in the dark**, fires the way it walks, gun out 30 ticks (12.4) then fires, walks on after 50 (20.6); sound **TANKFIRE** (not KEENFIRESND) | ✗ |
| Elite shot 9 px below its top, 1 in front | 8 px below, at its own x | ~ |
| Elite dying frame 46 | 40 → 16.5 | ✗ |
| Scrub crawl 25/32, 12 ticks a frame | 80 → 24; 32 → 13.2 | ✓ |
| Scrub dies popping up 10/32 | no pop: shot frame, next after 40 ticks, then falls | ✗ |
| Guard robot 31/32, 7 ticks a frame; starts right | 100 → 30; 16 → 6.6; right | ✓ |
| Look at a wall 26 ticks, 5 a frame | > 50 ticks → 20.6; frames every 16 → 6.6 | ✗ |
| Volleys: first after 200, later 31-199 | random chance k = 1 every frame | ✗ |
| 4 shots 13 ticks apart, 25 still before/after, floats on while firing | stands still for the whole volley: 50 ticks (20.6) of nothing, then a shot every 24 ticks (≈10) until 150 ticks → **4 shots**, then walks | ✓ count / ✗ timing |
| Shot 5 px below its top, 4 in front | 5 px below, at its own x | ✓ / ✗ |
| Platform 23/32, waits 51, 16 ticks a frame, 4 px above its cell | 75 → 23; waits > 75 ticks → **31**; frames 32 → 13.2; − 4 px | ✓ / ✗ / ~ / ✓ |
| Enemy shots 108/32 | 350 → 106 | ✓ |
| Enemy shots hurt other enemies | they kill grunts, youths, Scrubs; they **fly through** Elites and Guard robots (both ways), splash on platforms and the spark | ✓ mostly; ✗ "Guard stops an Elite's shot" |

**Switches and the Tantalus Ray**

| Estimate | Choco | |
|---|---|---|
| Tiles 270, 480↔493, 492, 505, 506, 533, 546-549 | all used the same way | ✓ |
| Earth gone = tile 561 | tile **155** (3 × 3 at (47, 22), at explosion frame 20) | ✗ |
| Elder light 429 → 182 | no such rule: any behaviour-22 tile shows the level's message (empty box outside levels 8/10) and becomes 143 | ✗ |
| Elder: level 8 first, level 10 second | level 8 "never jumps in the dark", level 10 the Grand Intellect hint; box 22 × 13, waits for Enter only | ✓ |
| Light switch = behaviour 23 with info 0 | the switch is recognised by **tile 271**; darkness = palette 1 | ~ |
| Switch search in 8-px steps | any switch tile overlapped by Keen's box during the tile check | ✗ |
| Bridge: tile every 4 ticks, first after 4 | every 12 ticks (4.9), first after 12 | ~ |
| Bridge stops at a solid side | stops when the next cell is no longer the start tile | ✗ |
| Tantalus fires | when tile 479 is at (switch x + 3, y + 5) | (new fact) |
| Shake 2 s, 2 px | 79 frames (~3.3 s), random offset up to ±32 px; then an "Oops." box (5 × 1) for 100 retraces | ✗ |
| Spark 6 ticks a frame | 8 ticks → 3.3 | ✗ |
| Wreck 26 ticks a step; 10,000 × 3 | 40 ticks → 16.5; **10,000 once**, at the shot; first step 40 ticks after the shot: dome → 143, glass → 546-548, lever → 506; then (mx−2,my) → 492, (mx+2,my) → 492, (mx, my+3..5) → 505, columns mx+3..mx+6 rows my+3..5 → 549, (mx−7..mx−5, my+2..4) → 533; SHOTHIT + splash each | ✗ / ✓ (the "maybe once" guess) |
| Beam from (4, 9), 252/32 × 108/32 per tick to column 47 | from tile (6, 5) to (47, 22) in 20 equal steps (21 frames), sprites alternate | ✗ |
| Explosion steps | 60 frames (each sync + 3 retraces): 8 small chunks from frame 15 (10 px / 5 px per frame), 4 big chunks from frame 20 (8 px per frame diagonally), 9 fireballs from EXE tables | ✗ in detail |
| EARTHPOW when the beam hits | yes, the original plays it | ✓ |
| Start charges 3 (B10) | 3 | ✓ |

---

## Keen 1 (`docs/keen-physics.md`, `docs/enemies.md`)

- Vorticon 3 HP (dies on the 4th shot) ✓; commander 104 (105 shots) ✓.
- Walk accel 2.7/32 per tick² (doc 3.5), ground friction 4.05/32 (doc 14:
  Keen needs ~16 ticks to stop, not 5) ✗.
- One gravity 4.05/32 for rising and falling (doc: 8/32 when falling after a
  jump) ✗; max fall 111/32 (doc 104) ~.
- Pogo bounce without jump ≈ 48 px (doc 58) ✗; with jump held ≈ 104 px (doc
  109) ~; compression 22 ticks ≈ 9-10 @60 (doc 11) ~.
- Exit walk 18/32 (doc 12/32) and the level ends when Keen reaches 2 tiles
  right of the exit tile (doc: 200 ticks) ✗.
- Door sinks 1 px per 5 ticks ≈ 1 px per 2 @60 ✓.
- Ice chunks: 200 per axis (61/32) both straight and diagonal (doc 80/32
  straight) ✗.
- Keens Left 0.86 s, GAME OVER 5.1 s, attract screens 16.5 s (shared code).
