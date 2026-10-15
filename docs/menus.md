# Title, menus and saving

How CommanderPerfect starts, which menus it has and what it remembers. The
look follows the original: windows with the pipe border, the 8x8 font, and
the spinning ball of the font (characters 9-15) as the cursor.

## From start to finish

1. **Title.** Keen next to his ship (a screen of map 90, see
   [file-formats.md](file-formats.md)) with the `TITLE` bitmap above. Left
   alone, the title and the high scores take turns every 8 seconds. Any key
   or controller button opens the main menu.
2. **Playing.** Escape (or Back on the controller) opens the menu; the game
   stands still meanwhile.
3. **Game over.** After the last life the `GAMEOVER` bitmap appears with
   `GAMEOVERSND`, for 4 seconds or until a key.
4. **High scores.** After game over and after the ending: a score above one
   in the table asks for a name ("You got first place!", the place words come
   from `KEEN1.EXE`), then the table is shown. Then the title returns.

## The main menu

| Choice | What it does |
|---|---|
| Return to Game | Only during a game: closes the menu |
| Add Player 2 / Remove Player 2 | Only during a game, not online: a second player joins or leaves (the same as F7), see [two-players.md](two-players.md) |
| New Game | Starts at the world map with 4 lives |
| Continue Game | Picks one of the 9 saved games (also with the keys 1-9) |
| Online Game | Host or join a game over the network, by IP or through Steam; while hosting, how others can join and Stop Hosting. See [online.md](online.md) |
| Save Game | Only during a game, and only on the world map (like the original). A taken position asks before it is overwritten |
| Story | `STORYTXT.CK1`; up/down and Page Up/Page Down scroll |
| High Scores | The table |
| Controls | Three sets of keys: "One player", and "Two players: player 1" and "player 2". Pick an action, then press its new key. The new key replaces the first key of the action; a key belongs to one action only among the keys used at the same time (one player's keys and two players' keys may overlap; Status is in both). Left and right Shift, Alt and Ctrl count as different keys. Escape and F1-F7 cannot be used. "Reset to defaults" puts all keys back |
| Options | Sound, widescreen, 4:3 pixels, full screen and smooth motion on or off; graphics original, xBRZ or HD (HD only once the player has made it, see [graphics.md](graphics.md)) |
| Quit to Title | Only during a game |
| Quit | Closes the program |

Escape goes back one menu. The controller can use the menus too (d-pad,
A to pick, B to go back).

The player who joined someone's online game has a menu of his own: Return
to Game, Leave Game, Story, Controls, Options and Quit. Online the game does
not stand still behind the menu.

## The line with the keys

A line at the bottom lists the keys. It is hidden at the start; F1 shows or
hides it while playing.

## Extra information in widescreen

In widescreen there is room next to the original picture, so while Keen is
on the map or in a level two small baby blue panels show in the top corners
(`Hud`): on the left Keen (the figure of the "Keens Left" window) with the
number of lives, and "Score" with the score; on the right the raygun with its charges and
the keycards Keen has. The original has nothing like this. With the panels
on the screen, the help line at the top only shows short messages, in the
middle.

## What is remembered

Everything is kept in the user folder of Godot; on the Mac that is
`~/Library/Application Support/Godot/app_userdata/CommanderPerfect/`.

| File | Contents |
|---|---|
| `settings.cfg` | Full screen, widescreen, 4:3 pixels, graphics, smooth motion, sound, the keys, and for playing online your name and the last address you joined |
| `saves/slotN.json` | Saved game N: score, lives, raygun charges, pogo stick, ship parts, completed levels and Keen's place on the map |
| `high_scores.json` | The high score table |

The saved games are our own format, not the `SAVEDn.CK1` files of the
original.

## Differences from the original

- The original has Escape for "Quit (Y/N)?", F1 for help, F2 for sound, F3
  and F4 for the keyboard and the joystick and F5 for saving. Here Escape
  opens the menu, which has all of that; F1-F6 have their own jobs (help
  line, widescreen, pixels, full screen, graphics, smooth motion).
- The help text (`HELPTEXT.CK1`) is not shown, because it describes the keys
  of the original.
- Not included: the demo, "About ID...", "Ordering Info" and "Previews!".
- The intro (the Apogee and id screens of map 90) is not shown yet.

## Still to compare with the original

- The scores in a new high score table (100 for every place now).
- Where the table, its headings and the ship parts sit in the red frame, and
  whether the names are drawn on white.
- How long the title stays before the high scores come.
- Where the menu window and the GAMEOVER window appear.
