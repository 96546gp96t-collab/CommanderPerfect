# The world map and the ending

How `MapSession` (`src/map/`) and `EndingSequence` (`src/game/`) play the
world map of Mars and the end of the game. Speeds are in pixels per tick
(1/60 s), as in `docs/keen-physics.md`.

## Sources

The original code is not decompiled (see `CLAUDE.md`). The meaning of the
info values comes from the map itself (`docs/file-formats.md`), the texts from
the player's own `KEEN1.EXE`, the sprites from `EGAHEAD.CK1`. How the map
and the ending behave is taken from the Commander Genius source, used as
documentation only. Values marked *estimate* in the code still have to be
compared with the original.

## Walking

Keen walks in eight directions at a steady speed of 68/32 pixels per tick,
the same as his top speed in a level (*estimate*). His sprite looks up or
down while a vertical direction is held, otherwise left or right; the four
walking frames change every 9 ticks. His collision box is the one from the
sprite table: 8x15 pixels at (2, 1) in the 16x16 sprite. All map tiles are
either solid on every side or not at all.

## Using things

The jump or pogo button uses what is under the middle of Keen's sprite. It
has to be pressed again for every use.

| What | Effect |
|---|---|
| Level entrance | Keen enters the level, unless it is done. Where he stood is remembered |
| Ship | Without all four parts: "Your ship is missing these parts", with pictures of the missing ones. With all parts the ending starts |
| Teleporter | Keen is teleported (below) |

After a level, whether Keen completed it or died, he is back on the map where
he entered it. Dying costs a life; after the last one the game starts over.
Completed levels get a "done" sign (tile 77, or tiles 78-81 for a 2x2
entrance) and cannot be entered again.

**Blocking entrances.** Cells with `0x8000` in their info value are solid
until their level is done: Keen must finish level 1 to get past it from the
start, and level 7 to reach the first teleporter.

**"Keens Left".** When the map appears at the start of a game and after
dying, a window shows a little Keen for every life left. It closes after 3
seconds or with a button.

## Teleporters

| Teleporter (info) | Where | Leads to |
|---|---|---|
| 38 | Ice north of level 7, in the western part | 41 |
| 41 | Ice next to level 8, the eastern part | 38 |
| 46 | Next to level 14, a part that cannot be reached on foot | 41 |
| Level 13 (tiles 481-484, 494-497) | Inside the level | 46 |

So the eastern half of Mars (levels 8-13, 15, 16) is reached through the
teleporter behind level 7, and level 14 only through the secret teleporter in
level 13. Leaving level 13 that way does not count as completing it.

A teleport has three phases: the teleporter flickers through four tiles (20
frames of 2 ticks), Keen travels unseen to the other teleporter at 4 pixels
per tick on each axis while the view follows, and the destination flickers
the same way. Coming out of level 13 starts with the travel.

## The ending

The ending starts as soon as Keen is back on the map with all four ship
parts (joystick in level 4, battery in level 3, vacuum cleaner in level 8,
whiskey in level 16), or when he uses the ship with all of them.

1. On the world map Keen stands right of his ship; a message tells that he
   repairs it.
2. On map 81 the ship flies from Mars to Earth along a fixed script
   (`ShipFlight`): up, a long way down to the right, stop near Earth, a "?",
   left, a "!", back, and down into Earth while the screen fades to black.
   The view stops following the ship while it looks around.
3. The picture of Keen's house (`FINALE.CK1`) with the seven messages of the
   conversation at the bottom, one per button press. The light in the
   bedroom window (bitmap `WINDON`) is on from "Billy...? Are you a--" until
   "Goodnight, dear." (`WINDOFF`).
4. On map 81 again the ship flies up from Earth to the Vorticon mothership,
   then the screen fades.
5. `ENDTEXT.CK1` in a window; up and down scroll it, a button closes it. A
   new game starts.

The speeds of the ship (16/32 pixel per tick, half that downwards) and the
lengths of the script are those of Commander Genius. In total the flight to
Earth takes about 28 seconds.

## Extra levels (not in the original)

With the option *Extra levels* (Options; on by default, the user's choice)
the game has two extras. Switched off, everything is as in the original.

**The ship as a level of its own** (`ShipLevels`, `ShipVisit`,
`ShipRepair`). Using the ship on the map, or standing right next to it
(10 pixels), starts the ship level instead of showing the missing parts:

- *Outside*: the ship of the title screen (tiles 351-383, map 90) on the
  ground of Mars, with smoke rising from it (`ShipSmoke`), and the picture
  of level 1 behind it when backgrounds are on. Keen walks out of sight at
  the left or right to go back to the map, where he stood. Walking into the
  back of the ship (two cells that work as an exit door without being
  drawn) takes him inside with the walk of the exit doors; to go on to the
  right he jumps over them.
- *Inside*: a small cabin drawn by the engine (`ShipInterior`,
  `ShipPicture`: pixel art of our own in the EGA palette), with a place
  for each part: the Everclear at the fuel tank, the battery, the vacuum
  cleaner, the joystick at the controls. An empty place shows the gray
  picture of its part (tiles 321-324); walking into it with the part puts
  it in (tile of the part, `GOTPARTSND`), without it a short note says it is
  still missing. A light above each place is red or green. The parts that
  are in are kept in the saved game (`installed_parts`). Out through the
  hatch at the left, Keen is outside again next to the ship.
- *The ending* starts a moment (90 ticks) after the last part is in, on the
  map as always. The ending no longer starts by itself when Keen has all
  four parts.

The cabin's walls are solid cells of their own (`LevelCollision.solid_cells`)
and its tiles are only background, which is left out of the tiles as for
the pictures behind the levels, so that the drawing shows through.

**The pogo level again.** Level 5, where the pogo stick lies, can be entered
again after it is done, as long as Keen does not have the pogo stick. Items
there then give no points; the raygun still gives charges.

## Still to compare with the original

- Keen's walking speed on the map, and whether diagonal walking is as fast.
- The speed and duration of the teleporter flicker and travel.
- Whether Keen is hidden while he travels between teleporters.
- The timing of the ship flights (Commander Genius may run at a different
  tick rate) and where the "?" and "!" float.
- Where the windows of the ending appear on the screen.
- Whether the parents' question and Keen's answer are one window or two.
