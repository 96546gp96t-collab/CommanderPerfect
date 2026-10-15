# Playing online

Two can play together over the network: one hosts, the other joins. This
is an extra of CommanderPerfect; playing alone and two players on one
keyboard ([two-players.md](two-players.md)) stay exactly as they were. The
way it works follows Together Around: the same port, Steam through
GodotSteam with App ID 480, the same kind of password handshake.

## Hosting and joining

Everything is in the menu under **Online Game** (at the title, or with
Escape during a game):

| Choice | What it does |
|---|---|
| Host via Steam | Opens a lobby that only your Steam friends can see. No address, no port: Steam finds the way. No password by default |
| Host via IP | Hosts on UDP port **24800** (the same port as Together Around, so one port forwarded on the router serves both). A password is made up and switched on by default; it can be switched off or made again |
| Join via Steam | The games your Steam friends host; a game with a `*` wants a password |
| Join via IP | Type the host's address (remembered for next time), then the password (empty if none) |
| Your Name | The name the other player sees when playing by IP; asked for the first time. Over Steam your Steam name is used |

Hosting from the title starts a new game; hosting during a game keeps it
going, with your score, lives and ship parts. A window shows how to join:
the addresses on your own network, the address on the internet (looked up
at api.ipify.org, as in Together Around) and the password. Escape > Online
Game shows it again, says who plays along, and has **Stop Hosting**.

Over the internet by IP the host must forward UDP port 24800 on his router
to his computer. Through Steam that is not needed.

When somebody joins, the host hears a short "ping" (a PC speaker sound made
by the game, not one of the original sounds) and "*Name* joined" appears in
the bottom right corner for a few seconds; "*Name* left" when he leaves.
The one who joined sees "Joined *Name*'s game".

## Playing together

- **The Keen of the player who joins always appears next to the host's
  Keen**, wherever the host is in the level: beside him (in front first),
  or on the same spot when there is no room. When the host is on the world
  map, he appears next to the host at the start of the next level.
- Each player has his own screen and his own keys (the keys for playing
  alone). The one who joined plays Keen in player 2's colors (blue helmet).
- **The world map: only the host walks.** The other player sees the host
  walking; pressing an arrow key or a button shows "Only the host can walk
  on the world map".
- Shared inventory, dying and the exit work as with two players on one
  keyboard: when one Keen dies both go back to the map (one life less);
  when one walks out the level is complete for both.
- **An arrow** at the edge of the screen points to the other player while
  he is out of sight, in the color of his helmet (yellow for the host's
  Keen, blue for the other).
- **Nothing pauses** while two play together (a host alone plays as
  always). The menu and the status screen (Enter) are each player's own; the game goes on behind them. The windows of the game (a
  statue's message, "Keens Left", the missing ship parts) show on both
  screens and close by themselves after a few seconds, or with a button.
- Only the host can start a new game, load or save (on the map, as
  always), and the high score table is the host's. Game over and the
  ending show on both screens; each player watches the ending at his own
  pace. Afterwards the one who joined waits at his title until the host
  starts a new game.
- Cheats and F7 (player 2 on the keyboard) do nothing for the player who
  joined; F7 is off for the host while hosting.
- **Leave Game** (in the joined player's menu) or the host stopping takes
  the joined player back to his own title.

## How it works

The host runs the game, exactly as alone; the other player runs nothing of
it. See `src/online/` and `OnlinePlay`, `RemoteGame` in `src/game/`.

- **Getting in** (`JoinHandshake`, `JoinGate`, `JoinTicket`). Before a
  player can send anything, Godot's authentication step: the host sends a
  challenge (game, version, a random nonce, whether there is a password);
  the player answers with the game, the version, the fingerprint of his
  level files (`LevelFingerprint`: a hash of all `LEVELxx.CK1`), his name
  and, if needed, a SHA-256 of the nonce and the password. The password
  itself never travels. The host refuses another version, other level
  files, a wrong password (5 wrong ones keep a player out for a minute) and
  a second player. Each player uses his own game files; they are never
  sent.
- **The joiner's buttons** (`OnlineInput`) go to the host only when they
  change, as a few bits, reliably and in order. The host takes at most one
  change per tick, so a quick tap still lasts a tick. Every 10 ticks the
  joiner also sends what part of the level he sees, so that enemies there
  wake up.
- **The picture of every tick** (`Snapshot`, made by `SnapshotMaker`): the
  Keens (place, sprite, how much of him shows at the exit, dying), every
  other actor with an id of its own (place, sprite), the doors sinking into
  the floor, the inventory and the sounds of that tick. Sent unreliably, 60
  times a second (a few hundred bytes); a lost one is replaced by the next.
  The joiner keeps a small reserve of two (`SnapshotBuffer`) and shows one
  per tick, with the usual smooth motion.
- **Scenes** (`OnlineMessages`): when the host's screen changes (a level,
  the map, game over, the ending, or nothing to play: the title) he sends
  the new scene with every tile that differs from the level file (items
  taken, doors opened, levels marked done). Tiles that change later, and the
  windows of the game, are events. Each has the number of its scene, so a
  late snapshot of the previous level is never shown.
- **Network**: ENet over UDP for IP (`EnetTransport`, two channels: events
  reliable, snapshots unreliable), or Steam's relay (`SteamTransport` with
  `SteamMultiplayerPeer`). `SteamService` is the only place that calls
  Steam; nothing names a Steam class, so the game and the tests also run
  without the plug-in (on Linux, where it is not included).
- Everything that arrives is checked before it is believed: sizes, types
  and ranges; objects are never decoded; a joiner who sends more than 400
  messages a second is cut off.

## Steam

The plug-in is **GodotSteam GDExtension 4.23.1** (MIT), in
`addons/godotsteam/`, committed with only its macOS and Windows libraries,
like in Together Around. It needs Godot 4.4 or newer. Steam must be running
and logged in. App ID 480 is Spacewar, Valve's open test game: Steam shows
you as playing "Spacewar", and the lobby data marks our games so that other
people's Spacewar lobbies are left out. A friends-only lobby is not in
Steam's public lobby list, so the friends' games are found through the
friends list: what each friend plays, and what that lobby says about itself.

On Linux (and in the cloud tests) the plug-in has no library, so Godot
prints that it cannot load it; the Steam choices then say that Steam is not
available.

## Testing on one computer

Two copies of the game on one computer need their own user folder, or they
share their settings. On Linux:

```sh
XDG_DATA_HOME=/tmp/host godot --path . -- --level=1   # host: Escape > Online Game > Host via IP
XDG_DATA_HOME=/tmp/join godot --path .                # join: Online Game > Join via IP > 127.0.0.1
```

`tools/scripted_play.gd` can type text (`type_127.0.0.1`), so both can be
played with scripted keys and screenshots.

## Not yet

- Steam has not been tried with two real accounts yet (the same holds for
  Together Around).
- No prediction: the joining player's own Keen reacts after one round trip
  over the network (on a home network or through Steam in one country
  usually 20-40 ms).
- More than two players, or two on one keyboard plus one online.
- Whether somebody plays online is not saved with a game.
