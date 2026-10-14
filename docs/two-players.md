# Two players

Two players can play on one keyboard. This is an extra of CommanderPerfect;
the original is for one player. Playing alone stays exactly as it was.

## Joining and leaving

F7, or "Add Player 2" / "Remove Player 2" in the menu during a game, lets a
second player join or leave at any moment. In a level his Keen appears
where player 1's Keen is; on the world map he joins from the next level on.
The choice is not saved with a game.

## Who does what

- **In the levels** both play. Player 2's Keen has every color turned half
  way around the color wheel (`player_colors.gdshader`), so his helmet is
  blue instead of yellow.
- **On the world map** (and in the ending) only player 1 walks. The keys of
  playing alone and the keys of both players all steer him there, so either
  player can walk to the next level.
- **The inventory is shared**: one score, one stock of lives, one raygun
  with its charges, the pogo stick, keycards and ship parts. Either Keen can
  pick things up and open doors.
- **Dying works as in the original**: as soon as one Keen dies, the attempt
  is over (after his dying animation), it costs one life and both are back
  on the map. While one Keen is dying the other cannot walk out through the
  exit.
- **The exit**: when one Keen walks out, the level is complete for both.
  Once a Keen is on his way out, nothing can stop that any more.
- **Enemies** go after the nearest living Keen, and can hurt either. They
  wake up when they come into either player's view.
- The teleporter in level 13 takes both to the map.

## Keys

| | Player 1 | Player 2 |
|---|---|---|
| Walk | A / D | Left / Right |
| Jump | Left Shift | . (period) |
| Pogo | ` (backquote; on a Mac with an ISO keyboard the key next to left Shift) | / (slash) |
| Fire | Z | Right Shift |

Enter (status) and Escape (menu) are shared. Each player's keys have their
own page in Controls. Keys are stored by their place on the keyboard
(physical keycode), together with the side for keys such as Shift that are
on both sides (`KeyBindings`, stored as keycode + side << 32).

Ctrl is deliberately not used for two players: on a Mac, Ctrl + an arrow key
switches desktops, which would happen when player 1 jumps while player 2
walks.

The controller still steers player 1 only.

## The split screen

`SplitScreen` decides where the two cameras look; `TwoPlayerView` draws it.

- Each player has a focus point that follows him with the same dead zone as
  the camera for one player.
- While both players' own cameras would be within the *reach* of the shared
  view's middle (half way from the middle to the edge of the screen, along
  the line between the players), both cameras look at the shared view: one
  screen.
- Further apart, each camera keeps its player at that reach from the middle
  of the screen, on the side of his partner. The screen is split by a line
  through its middle at right angles to the line between the players: the
  line turns as the players move around each other.
- Near the edges of a level the shared view cannot be centered, so the
  players may be further apart and still share it. It joins again only when
  both are 8 pixels further in than where it split, so it does not flicker.
- The cameras glide (the same smoothing as for one player), so the picture
  never jumps; the dark line fades in over the first 4 pixels the cameras
  move apart.
- In a narrow level both cameras end up at the same place, so the screen
  never splits there.

Drawing: the `World2` viewport shares the level with `World` (same
`World2D`) and has its own camera. While the screen is split, its picture
is laid over player 2's half of `World`'s picture by `split_screen.gdshader`
(on the `SplitView` in the UI layer, so the HUD and windows stay on top),
with the dark line. `World2` only draws while the screen is split.

`PartnerArrows` draws a small arrow next to each Keen, pointing at the
other one, in the other one's color (yellow for player 1, blue for player
2). The arrows are drawn in the level, so each half only shows its own
player's arrow.
