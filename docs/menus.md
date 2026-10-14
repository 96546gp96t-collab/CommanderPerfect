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
| New Game | Starts at the world map with 4 lives |
| Continue Game | Picks one of the 9 saved games (also with the keys 1-9) |
| Save Game | Only during a game, and only on the world map (like the original). A taken position asks before it is overwritten |
| Story | `STORYTXT.CK1`; up/down and Page Up/Page Down scroll |
| High Scores | The table |
| Controls | Pick an action, then press its new key. The new key replaces the first key of the action; a key belongs to one action only. Escape and F1-F4 cannot be used. "Reset to defaults" puts all keys back |
| Options | Sound, widescreen and 4:3 pixels on or off |
| Quit to Title | Only during a game |
| Quit | Closes the program |

Escape goes back one menu. The controller can use the menus too (d-pad,
A to pick, B to go back).

## What is remembered

Everything is kept in the user folder of Godot; on the Mac that is
`~/Library/Application Support/Godot/app_userdata/CommanderPerfect/`.

| File | Contents |
|---|---|
| `settings.cfg` | Widescreen, 4:3 pixels, sound, and the keys |
| `saves/slotN.json` | Saved game N: score, lives, raygun charges, pogo stick, ship parts, completed levels and Keen's place on the map |
| `high_scores.json` | The high score table |

The saved games are our own format, not the `SAVEDn.CK1` files of the
original.

## Differences from the original

- The original has Escape for "Quit (Y/N)?", F1 for help, F2 for sound, F3
  and F4 for the keyboard and the joystick and F5 for saving. Here Escape
  opens the menu, which has all of that; F1-F3 keep their own jobs (help
  line, widescreen, pixels).
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
