# Pictures behind the levels of Keen 1 and Keen 2: milestones

Branch `milestone-a-b-backgrounds` (from `main`, 22-10-2026). Research and
the user's choices: [research.md](research.md). As for the other episodes:
the architect writes the assignments and checks the work; agents build in
their own git worktrees; Keen 1-3's behaviour does not change (the 4:3
picture is always the original, the regressions stay at 0 differences in
4:3).

## AB1. Research (done)

Every level of both episodes looked at and measured; the user chose how the
backgrounds move and what is on them (research.md, section 6).

## AB2. The fixed wall (developer + tester)

1. **Holes of two kinds** (`GraphicsTextures`): besides today's colour rule
   (sky), a wall rule per episode: Keen 2 the lattice pattern (tile 143,
   in the dark 147) and its shadow one step darker; Keen 2's level 12 the
   plain teal (276, colour rule); Keen 1 black (155, colour rule). Holes
   only where they touch a tile's edge, as today; the shadow pixels are a
   second, half-dark kind of hole. xBRZ: the holes cut out of the larger
   tiles, as today.
2. **`LevelWall`** (shared, new): a layer just below the tiles with the
   same cells; per tile the wall's mask (lit and shadow); a shader fills it
   with a repeating texture by world position (1:1, fixed to the level),
   the shadow at a fixed darkness. On the level's canvas, so Keen 2's
   darkness dims it. In a split screen each half shows it by itself, as the
   tiles.
3. **Keen 2**: every level gets its wall (no more "only level 12"); the
   texture per level from the table in the painter (kind of room).
4. **Keen 1**: the black of a level is wall; the grey is sky only outside:
   a table of outside levels (1, 3, 4, 7, 8, 13, 14, 15, 16 and the outside
   parts of 9, 10, 12), and inside a mixed level only the grey joined to
   the sky (not the cones under a lamp). Level 1 as today.
5. **Files**: `assets/backgrounds/keen2/wallNN.webp` (or by kind of room),
   `assets/backgrounds/wallNN.webp` for Keen 1; the player's
   `backgrounds/` folder wins, as for the pictures.
6. **Tests** (tester): the masks of tile 143, a shadow tile, an item, the
   riveted box (no X) and a sign board; the wall moves 1:1 with the view;
   Keen 1's light cones stay grey in level 2 and inside the castle of 16;
   4:3 unchanged; the option off shows the original.

## AB3. The pictures (painter, at the same time as AB2)

1. **Keen 2's walls**, seamless, in game pixels: corridors and halls
   (1, 2, 3), Tantalus Centers (4, 6, 7, 9, 11, 13, 15, 16), Home A and B
   (8, 10), Weaponry A and B (14, 12) and the dark shaft (5). Darker and
   quieter than the items.
2. **Keen 1's skies** (levels 3, 4, 7, 8, 13, 14, 15, 16, and 9, 10, 12
   for their outside part) in the mood of level 1's picture (a starry
   Martian night, mountains, the plain), per city its own (ice, green, red
   rock, the castle).
3. **Keen 1's walls**: rock for the Red Rock Shrines and the Pogo Shrine,
   cold stone for the ice shrines, dark stone for the castle and the tunnel
   of 13.
4. Painted by our own tools (`tools/make_keen1_backgrounds.py`,
   `tools/make_keen2_walls.py`, on `tools/background_painter.py`); nothing
   from the game files, and nothing that follows a level's shape.

## AB4. Together and checked (architect)

Merge AB2 and AB3, screenshots of every level in widescreen (scripted play)
next to the original, the full tests and gdlint, the Keen 1 and Keen 2
regressions (4:3: 0 differences), PROGRESS.md and `docs/doorlooptijden.md`.

| Milestone | Estimate |
|---|---|
| AB1 Research | ~1 h (done) |
| AB2 The fixed wall | ~1 h 15 |
| AB3 The pictures | ~1 h (at the same time) |
| AB4 Together | ~30 min |
