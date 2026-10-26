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
| Up | W | Up |
| Down | S | Down |

Up and down came last (milestone D12, approved by the user on
19-10-2026): Keen 4 needs them in its levels (poles, doors, looking up and
down). Keen 1-3 do not use them in a level; on their world map the keys of
playing alone (which include W/S and the arrows) already steered, so they
play exactly as before; their Controls pages show the two new lines.

Enter (status) and Escape (menu) are shared. Each player's keys have their
own page in Controls. Keys are stored by their place on the keyboard
(physical keycode), together with the side for keys such as Shift that are
on both sides (`KeyBindings`, stored as keycode + side << 32).

Ctrl is deliberately not used for two players: on a Mac, Ctrl + an arrow key
switches desktops, which would happen when player 1 jumps while player 2
walks.

## Controllers

Each of the two players can play with a game controller of his own (milestone
`milestone-controller`, the user's wish of 26-10-2026), in every game: over
USB or Bluetooth, Godot sees both the same way. `PlayerControllers` keeps
the choice; it is stored in `settings.cfg` (`[controls] controllers`).

- **Playing alone** every controller steers Keen, as before.
- **When two play**, each player's actions (`p1_*`, `p2_*`) also take the
  controller buttons and the stick of the matching action of playing alone
  (d-pad or left stick to walk, A jump, B pogo, X fire), but only from that
  player's own controller (Godot's device number on the input event). His
  keys keep working next to it. Start (status) and Back (menu) are shared,
  as Enter and Escape are.
- **Automatic** (the default): player 1 gets the first connected
  controller, player 2 the next one. With one controller, player 1 has it
  and player 2 plays on the keyboard.
- **Chosen**: in Controls > Controllers (Keen 1-3) or Configure > Two
  Players (Keen 4 and 5: Player 1 Pad / Player 2 Pad, Both Pads Auto),
  pick a player and press any button on his controller. A controller
  belongs to one player only: choosing it for the other makes the first
  automatic again. A chosen controller is remembered by its GUID (make and
  model) and which of the connected ones of that kind it was, so two
  controllers of the same kind stay apart. While it is not connected the
  menu says "(OFF)" (Keen 4-5: "OFF") and that player has no controller.
- Controllers that connect or disconnect while playing (Bluetooth) are
  picked up straight away (`Input.joy_connection_changed`).
- On the world map, where one Keen walks, every controller steers him, as
  every key does.

## Keen 2 and Keen 3

Keen 2 (milestone B9) and Keen 3 (milestone C10) have two players the
same way, with the same keys, the shared inventory and the same split
screen; what is their own is in [keen2/gameplay.md](keen2/gameplay.md)
and [keen3/gameplay.md](keen3/gameplay.md). In Keen 3 each Keen has his
own ankh (a panel per Keen in the HUD, both times on the status screen),
and on the world map the one Keen rides Messie and goes through the
teleporters with the keys of either player.

## Keen 4

Keen 4 (milestone D12, [keen4/gameplay.md](keen4/gameplay.md), "Two
players") has two players too, with the same keys (now with up and down),
the shared inventory, one Keen on the world map and the same split screen
(`GalaxySplitView` uses `SplitScreen`), each view kept inside its Keen's
area between the scroll blocks. Its control panel has them under
Configure > Two Players (Add Player 2, each player's keys); F7 as in Keen
1-3. Keen 4's Keens look up and down; since D13.2 each half of a split
screen moves for its own Keen's look, as the view does alone (one shared
view does not). Also since D13.2: while one of them is in a small area (less
than 1.2 views wide or high, such as a room behind a door), the line turns
into a standing one through the middle of the screen, the player further
left on the left, and his area is in the middle of his own half instead of
the screen's; when both are out again it turns back to the slanting line.
Keen 1-3 have no looking and no scroll blocks, and `SplitScreen` is
unchanged.

## Keen 5

Keen 5 (milestone E11, [keen5/gameplay.md](keen5/gameplay.md), "Two
players") has Keen 4's two players through the shared Galaxy screens
(`GalaxyCoopScreen`): the same keys, F7 and Configure > Two Players, the
same split screen. The keycard is part of the shared inventory (either
takes it, either uses it); either breaks the fuses; on the world map the
one Keen rides the teleporter and the elevators for both.

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

There is no arrow pointing to the other player: on one screen each player
can see from the split which way his partner is (tried and taken out on
request of the user, 14-10-2026).

## Online

Playing online is described in [online.md](online.md). The player who
joins is player 2 in the host's level, without a split screen (each has a
screen of his own), and an arrow at the edge of the screen points to the
other player while he is out of sight (`PartnerArrow`).
