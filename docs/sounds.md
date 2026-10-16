# Sounds

Keen 1 plays all its sounds on the PC speaker, one at a time. The sounds
come from the player's own `SOUNDS.CK1` (format in
[file-formats.md](file-formats.md)); CommanderPerfect turns them into square
waves (`SpeakerSynth`) and plays them on one channel (`SoundPlayer`). Just
like the single speaker, a new sound only cuts off the one that is playing
when its priority is at least as high.

## Which sound goes with what

The names tell what most sounds are for. Where the name leaves room, the
choice below is a guess and is marked so; check those against the original.

| Sound | When |
|---|---|
| `WLDWALKSND` | Footstep on the world map (every other walking frame) |
| `WLDBLOCKSND` | Walking into something on the world map |
| `WLDENTERSND` | Entering a level from the map |
| `KEENWALKSND`, `KEENWLK2SND` | Footsteps in a level, the two feet alternating |
| `KEENBLOKSND` | Walking into a wall |
| `KEENJUMPSND` | Jumping |
| `KEENLANDSND` | Landing (not on the pogo stick) |
| `KEENPOGOSND` | Every bounce on the pogo stick |
| `BUMPHEADSND` | Hitting the ceiling |
| `KEENFIRESND` | Firing the raygun |
| `GUNCLICK` | Pulling the trigger without charges |
| `SHOTHIT` | A shot hits a wall or an enemy (only walls in sight) |
| `KEENDIESND` | Keen dies |
| `PLUMMETSND` | Keen falls out of the level *(guess)* |
| `keencicle` | Keen is frozen by an ice chunk |
| `GOTBONUSSND` | Picking up points |
| `GOTITEMSND` | Picking up the raygun or the pogo stick *(guess)* |
| `GETCARDSND` | Picking up a keycard |
| `GOTPARTSND` | Picking up a ship part |
| `EXTRAMANSND` | An extra life |
| `DOOROPENSND` | A door opens |
| `LVLDONESND` | Keen walks through the exit door |
| `YORPBUMPSND` | Walking into a Yorp |
| `YORPBOPSND` | Jumping on a Yorp's head |
| `YORPSCREAM`, `GARGSCREAM`, `vortscream` | A Yorp, Garg or Vorticon dies |
| `TANKFIRE` | A tank robot fires (only in sight) |
| `CANNONFIRE` | An ice cannon fires (only in sight) |
| `CHUNKSMASH` | An ice chunk shatters (only in sight) |
| `SLAMSND` | The stone in level 16 lands *(guess)* |
| `TELEPORTSND` | A teleporter on the map starts |
| `keensleft` | The "Keens Left" window |
| `GAMEOVERSND` | Game over |
| `HISCORESND` | A new high score |

Online, the host hears a "ping" when somebody joins: two short rising tones
made with the same PC speaker synthesis (`PingSound`), not one of the sounds
of `SOUNDS.CK1`. It plays on its own, next to the game's one channel.

Not used yet: `CLICKSND`, `CRYSTALSND` and `GOINDOORSND`; it is not known
what they are for in Keen 1.

## Still to compare with the original

- Whether the sound timer really runs at 140 Hz (the length and pitch of
  the sounds depend on it).
- The guesses in the table above.
- How loud the speaker is relative to the rest (there is only one volume).
- Whether cannons, tanks and splashes out of sight are really silent.
