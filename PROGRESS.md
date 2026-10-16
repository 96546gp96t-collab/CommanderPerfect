# Voortgang

Dit bestand is het geheugen van het project tussen sessies. Werk het aan het
eind van elke sessie bij.

## Mijlpalen

Wat elke mijlpaal precies inhoudt, staat in [docs/roadmap.md](docs/roadmap.md).

| # | Mijlpaal | Status |
|---|---|---|
| 1 | Originele bestanden inlezen in Godot (graphics, levels) + data viewer | ✅ Klaar (branch `milestone-1-data-loading`) |
| 2 | Levels tekenen met TileMapLayer, scrollen, widescreen-camera | ✅ Klaar (branch `milestone-2-level-view`) |
| 3 | Keen: lopen, springen, pogo, botsingen (tile-eigenschappen uit KEEN1.EXE) | ✅ Klaar en gemerged; de besturing voelt goed volgens de gebruiker (14-10-2026), naast DOSBox leggen staat nog open |
| 4 | Vijanden, items, deuren, sleutelkaarten, straalgeweer | ✅ Gemerged naar `main` (PR #4); speeltesten loopt nog |
| 5 | Wereldkaart, levelovergangen, scheepsonderdelen, einde | ✅ Getest door de gebruiker en gemerged naar `main` (PR #5) |
| 6 | Geluid, menu's, opslaan | ✅ Getest door de gebruiker en gemerged naar `main` (PR #6) |
| 7 | Hogere framerate (interpolatie), xBRZ met wisselknop, Real-ESRGAN-pipeline, Windows-build | ✅ Gemerged naar `main` (PR #7) |
| 8 | Twee spelers op één toetsenbord, dynamisch split-screen | ✅ Gemerged naar `main` (PR #8) |
| 9 | Online co-op: hosten en joinen via Steam of IP | ✅ Gemerged naar `main` (PR #9); speeltest online loopt nog |
| 10 | Startscherm met een icoon per spel | ✅ Gemerged naar `main` (PR #10) |
| 11 | Fixes: crash bij "Choose Game", nieuw app-icoon, achtergronden achter levels | 🔶 Gebouwd en getest door de gebruiker (branch `milestone-11-fixes`) |
| 11.2 | Extra: het schip als eigen level (onderdelen monteren), pogo-level opnieuw, onderdelen op de kaart | 🔶 In test bij de gebruiker (branch `milestone-11.2-extra-mini-game`) |

## Mijlpaal 1: wat er nu is

- `GameFiles`: vindt de spelbestanden (`--data-dir=`, `game_data/keen1/`, of naast de exe) en negeert hoofd/kleine letters.
- `LzwDecompressor` en `RlewDecompressor`: de twee compressievormen van Keen 1.
- `EgaHeader`: inhoudsopgave van alle graphics, ondersteunt ook versie 1.34.
- `EgaGraphics`: font (256), tiles (611), bitmaps (18) en sprites (119, met transparantie).
- `LevelData`: tile- en info-laag van elk level en de wereldkaart.
- Data viewer: levels, tiles, sprites, bitmaps en font bekijken, met zoom. Openen met `godot --path . res://src/viewer/data_viewer.tscn`.
- `tools/export_graphics.gd`: alles als PNG naar `exported/`, de basis voor Real-ESRGAN later.
- Tests: `tests/run_tests.gd` (decompressie, EGA-decodering en de echte Keen 1-data).

Getest met de shareware-versie 1.1 en Godot 4.7.2: alle tests slagen, en de
geëxporteerde PNG's (titelscherm, level 1, wereldkaart, tiles, sprites) zijn
visueel gecontroleerd. De Steam-versie is nog niet getest. Probeer die op je
Mac: zet de bestanden in `game_data/keen1/` en open het project in Godot.

## Mijlpaal 2: wat er nu is

- `LevelView` (`src/game/`) is nu de hoofdscène: je kijkt rond in een level met pijltjes/WASD of de controller, en bladert met Page Up/Down door alle levels en de wereldkaart. Start in een ander level met `-- --level=N`.
- Het level wordt op de originele resolutie getekend in een `SubViewport` en daarna naar het venster geschaald. Zo blijven de pixels scherp en kan xBRZ later als shader op dat beeld.
- `LevelTileSet` en `LevelMap` (`src/level/`): alle tiles in één atlas, een `TileMapLayer` per level.
- `LevelCamera`: scrollt vloeiend en laat nooit iets buiten het level zien. De rand van 2 tiles rond elk level wordt niet getekend; het origineel laat die ook nooit zien. Smalle levels staan in widescreen in het midden met zwarte balken.
- `DisplaySettings`: F2 wisselt tussen origineel (320x200) en widescreen (426x200, 16:9). F3 wisselt tussen pixels zoals op een 4:3-monitor (1,2x zo hoog) en vierkante pixels (dan is widescreen 356x200).
- `FreeLook`: het punt dat de camera volgt. In mijlpaal 3 neemt Keen die rol over. De bewegingsacties heten al `move_left` enz., zodat Keen ze kan hergebruiken.
- `LevelData` kent nu het speelbare gebied (`playable_rect`) en Keens startpositie (info-waarde 255). Beide staan in `docs/file-formats.md`.
- Tests: `tests/test_level_rendering.gd` (zonder speldata), plus nieuwe controles op de echte data: elk level heeft één startpositie en is minstens 320x200 pixels groot.

Getest met Godot 4.7.2 en de shareware-versie 1.1. Alle tests slagen, en de
screenshots van level 1, 2, 90 en de wereldkaart in alle vier de
beeldinstellingen zijn visueel gecontroleerd.

## Mijlpaal 3: wat er nu is

- `DosExecutable` en `LzexeDecompressor` (`src/data/`): pakken `KEEN1.EXE` uit (LZEXE 0.91, eigen implementatie). Alleen datatabellen worden gelezen, geen code.
- `TileProperties`: per tile welke kanten massief zijn, vloertype (gewoon, glad, ijs), gedrag (dodelijk, deur, voorgrond, …) en animatie. De tabel staat in versie 1.1 op 0x131F8 in de uitgepakte EXE; voor onbekende versies (zoals 1.34) wordt hij gezocht aan zijn vorm. `KEEN1.EXE` is nu een verplicht bestand.
- `LevelMap` tekent voorgrond-tiles op een eigen laag vóór Keen en laat geanimeerde tiles (vuur, water, sterren, …) bewegen.
- `LevelCollision` (`src/level/`): botsingen per tilekant, dus ook platforms waar je van onderaf doorheen springt. Buiten het speelveld is muur, behalve onderin: daar val je uit het level.
- `src/keen/`: `KeenBody` (de logica, los testbaar), `KeenPhysics` (alle getallen op één plek), `KeenInput` en de `Keen`-node die tekent. Lopen, springen met aanloop (langer indrukken = hoger), pogo (Alt of X; springknop vasthouden = hoge sprong). Springen kan ook met Z, omdat Ctrl+pijltje op de Mac van bureaublad wisselt, ijs en gladde vloeren, hoofd stoten. Vaste ticks van 1/60 s, los van de framerate.
- Keen loopt in levels 1-16; op de wereldkaart en de speciale kaarten kijk je nog vrij rond (`FreeLook`), want lopen op de kaart is mijlpaal 5. De camera volgt Keen met een kleine dode zone.
- Raakt Keen iets dodelijks of valt hij uit het level, dan begint hij opnieuw bij de start (doodgaan en levens: mijlpaal 4).
- Uitleg en herkomst van alle getallen: `docs/keen-physics.md`. Het EXE-formaat en de gevonden gedragswaarden: `docs/file-formats.md`.
- Tests: `test_tile_properties.gd` en `test_keen_movement.gd` (zonder speldata, met kleine zelfgemaakte levels), plus op de echte data: de tabel wordt gevonden en Keen landt veilig aan het begin van elk level.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en level 1 is met gescripte invoer gespeeld (lopen, springen, pogo)
en via screenshots gecontroleerd. Het gevoel van de besturing is nog niet
naast het origineel gelegd.

## Mijlpaal 4: wat er nu is

- `Inventory` (`src/game/`): score, levens (4 bij de start, extra leven per 20.000 punten), ladingen van het straalgeweer, pogo-stick, sleutelkaarten (alleen binnen een level) en scheepsonderdelen (kwijt als Keen doodgaat in het level waar hij ze vond).
- `LevelSession` (`src/game/`): één poging aan een level, in vaste ticks, zonder nodes, dus volledig testbaar. Items oppakken, deuren openen met de juiste sleutelkaart, de uitgang, schieten, vijanden plaatsen vanuit de info-laag en alle botsingen tussen Keen, schoten en vijanden. Willekeur gebruikt een vaste seed, dus elke poging begint hetzelfde.
- `src/actors/`: `Actor` (basis), `RaygunShot`, `OpeningDoor` (zakt in de vloer), `Enemy` met `Yorp`, `Garg`, `Vorticon`, `Robot` (`ButlerRobot`, `TankRobot`), `IceCannon` met `IceChunk` en `IceBit`, en `StoneChain` (de ketting met de steen in level 16). `ActorLayer` tekent ze.
- `KeenBody`: begint zonder pogo-stick, schiet (met het geweer-frame; op de grond staat hij dan even stil), gaat dood met de `KEENISDEAD`-animatie en vliegt van het scherm, kan bevriezen door ijs, en kan geduwd worden door Yorps en robots.
- `LevelView`: de tick-lus zit nu hier (niet meer in de `Keen`-node, die alleen nog tekent). HUD met score, levens, munitie, pogo, sleutelkaarten en scheepsonderdelen. Doodgaan start het level opnieuw met één leven minder; na het laatste leven begint het spel opnieuw. De uitgang gaat naar het volgende level (tot de wereldkaart er in mijlpaal 5 is).
- Nieuwe knop: vuren met Spatie, C of X op de controller.
- De info-laag is ontcijferd (1-10 en 255), zie `docs/file-formats.md`. Gedrag en herkomst van alle getallen: `docs/enemies.md`.
- Tests: `test_keen_actions.gd` (schieten, pogo vinden, doodgaan), `test_level_session.gd` (items, deuren, uitgang, schoten, levens), `test_enemies.gd` (alle vijanden), plus op de echte data: elke deur heeft een sleutelkaart van zijn kleur in hetzelfde level, en geen enkele vijand valt bij de start uit het level.

Na de eerste speeltest van de gebruiker (14-10-2026) toegevoegd:

- Statusscherm op Enter (of Start op de controller): score, levens, volgende extra leven, straalgeweer met ladingen, pogo, sleutelkaarten en scheepsonderdelen, in de stijl van het origineel (`GameWindow` met de buisrand en het lettertype uit `EGALATCH`, `StatusScreen`). Het spel pauzeert zolang het open is.
- De beeldjes van Yorps en de Garg tonen hun bericht uit `KEEN1.EXE` (`HintTexts`), één keer per poging; daarna gloeien ze niet meer.
- Cheats om te testen: Shift+N / Shift+P (vorig/volgend level, naast Page Up/Down, die op een MacBook Fn+pijltje zijn), Shift+I (alle sleutelkaarten, pogo, 99 ladingen) en Shift+G (god mode).
- Bug opgelost: bij doodgaan sprong de camera even naar linksboven. De camera werd verhangen in de scèneboom, en in dat ene frame had de viewport geen camera. Nu hangt hij vast aan een eigen anker (`CameraAnchor`).
- De uitgang werkt nu zoals in het origineel: alleen als Keen op de grond staat (niet op de pogo-stick of met het geweer in de hand) loopt hij vanzelf langzaam de deur in, verdwijnt er stukje bij beetje achter, en na 200 ticks is het level klaar. Niets kan hem dan nog doden.
- Bug opgelost: in breedbeeld stonden vijanden net buiten het gewone beeld stil en een beetje in de lucht. Vijanden worden nu wakker zodra ze in het echte beeld komen (de view geeft zijn rechthoek door aan `LevelSession`), en ze landen bij de start van het level meteen op de vloer onder hun cel.
- macOS-build: `tools/build_macos.sh` maakt `build/CommanderPerfect.app` (universeel, ad-hoc ondertekend) met de speldata ernaast; `GameFiles` zoekt de data ook naast een `.app`. Hiervoor is de macOS-template van Godot 4.7.2 geïnstalleerd (alleen macOS; Windows volgt in mijlpaal 7).

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn level 1 (Yorps, items), level 4
(deur, schieten) en level 8 (robots, ijskanonnen) gespeeld en via
screenshots gecontroleerd. Een level helemaal uitspelen met de hand moet nog.

## Mijlpaal 5: wat er nu is

- De info-laag van de wereldkaart is ontcijferd (`MapInfo`): 1-16 zijn levelingangen, met `0x8000` erbij blokkeert de cel de weg tot het level klaar is (rechterhelft van level 1, bovenhelft van level 7), 20 is het schip, 38/41/46 zijn teleporters, 255 de start. Zie `docs/file-formats.md` en het nieuwe `docs/world-map.md`.
- `src/map/`: `MapSession` (de kaart in vaste ticks, zonder nodes, testbaar), `MapKeen` (lopen in acht richtingen met de MAPKEEN-sprites), `MapCollision` (tiles plus blokkerende ingangen) en `MapTeleport` (flikkeren, reizen, flikkeren).
- Springen of pogo op een ingang start het level; Keen komt daarna terug waar hij het level in ging, of hij het nu uitspeelde of doodging. Voltooide levels krijgen een DONE-bord (tile 77, of 78-81 voor grote ingangen) en kunnen niet meer in.
- Teleporters: 38 (achter level 7) ↔ 41 (ijs bij level 8, de oostkant van Mars); 46 (bij level 14) → 41. De teleporter in level 13 (gedrag 24) brengt Keen naar 46: zo bereik je level 14. Een test bewijst dat alle 16 levels vanaf de start bereikbaar zijn.
- `GameProgress`: inventaris, voltooide levels en de plek op de kaart. Doodgaan in een level kost een leven en brengt Keen terug naar de kaart; bij de start en na doodgaan verschijnt het "Keens Left"-venster.
- Het schip: zonder alle onderdelen het bericht "Your ship is missing these parts" met plaatjes van wat ontbreekt. Met alle vier de onderdelen begint het einde zodra Keen terug is op de kaart.
- Het einde (`EndingSequence`, `ShipFlight`): Keen repareert zijn schip, vlucht van Mars naar de aarde op kaart 81 (met "?" en "!"), het plaatje van zijn huis uit `FINALE.CK1` (`FinaleImage`) met het gesprek en het licht in de slaapkamer (`WINDON`/`WINDOFF`), de vlucht naar het moederschip en tot slot `ENDTEXT.CK1` (`TextDocument`, scrollen met omhoog/omlaag). Daarna begint een nieuw spel.
- Alle teksten komen uit de eigen `KEEN1.EXE` van de speler (`EndingTexts`, met de gedeelde helper `ExeStrings`, die ook `HintTexts` nu gebruikt).
- `LevelView` speelt nu het hele spel: kaart → level → kaart → einde. Het spel start standaard op de wereldkaart. Nieuwe optie `-- --ending` om meteen het einde te zien. Shift+N/P bladeren nu door alle kaarten.
- `tools/export_graphics.gd` exporteert ook het FINALE-plaatje.
- Tests: `test_world_map.gd` (lopen, ingangen, blokkades, DONE-borden, teleporters, schip), `test_ending.gd` (vluchten, de stappen van het einde, tekstopmaak, FINALE-decoder, teksten uit de EXE), een teleporter-test in `test_level_session.gd`, en op de echte data: alle ingangen bestaan, elk level is bereikbaar, Keen loopt level 1 in, alleen level 13 heeft een teleporter, en de eindbestanden zijn leesbaar.

- Bug opgelost (speeltest 14-10-2026): bij de start van een level viel Keen 8 pixels naar beneden. De startcel zet de bovenkant van zijn 24 pixels hoge sprite bovenaan de cel; nu staat hij meteen op de vloer eronder.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn de kaart (Keens Left, statusscherm,
het schipbericht, level 1 in) en het hele einde opgenomen en via screenshots
gecontroleerd. Het spel helemaal met de hand uitspelen moet nog.

## Mijlpaal 6: wat er nu is

- **Geluid.** `SoundFile` leest `SOUNDS.CK1` (41 geluiden met prioriteit; formaat in `docs/file-formats.md`). `SpeakerSynth` maakt van elk geluid een blokgolf zoals de PC-speaker (140 stappen per seconde, met een zacht laagdoorlaatfilter), en `SoundPlayer` speelt ze op één kanaal: een nieuw geluid onderbreekt alleen een geluid met een lagere of gelijke prioriteit. Keen (lopen, springen, landen, pogo, hoofd stoten, schieten, doodgaan, bevriezen), items, deuren, de uitgang, vijanden, de kaart (stappen, botsen, level in, teleporter), "Keens Left", game over en highscores hebben hun geluid. Welk geluid waarbij hoort (en wat nog een gok is) staat in `docs/sounds.md`.
- **Titelscherm.** Het spel start nu op het titelscherm: Keen bij zijn schip uit map 90 met het TITLE-plaatje erboven. Na 8 seconden wisselt het af met de highscores. Een toets opent het hoofdmenu. `Backdrops` snijdt de schermen uit map 90 (`LevelData.crop`), zodat breedbeeld zwarte balken geeft. `-- --level=N` start nog steeds direct in een level.
- **Menu's** (`src/menu/`): `Menu` (keuzes en cursor, testbaar), `MenuView` (tekent in een `GameWindow` met het draaiende bolletje uit het lettertype als cursor) en `MenuController` (alle schermen). Escape opent het menu tijdens het spel; het spel pauzeert dan. Keuzes: Return to Game, New Game, Continue Game, Save Game, Story (`STORYTXT.CK1`, scrollen), High Scores, Controls, Options, Quit to Title, Quit. Zie `docs/menus.md`.
- **Opslaan en laden.** `SaveGames`: 9 plekken, alleen op de wereldkaart (zoals het origineel), met een vraag voor overschrijven. `GameProgress` en `Inventory` kunnen zichzelf naar JSON schrijven en teruglezen. Bestanden in de gebruikersmap van Godot (op de Mac `~/Library/Application Support/Godot/app_userdata/CommanderPerfect/`).
- **Toetsen instellen.** `KeyBindings`: per actie de eerste toets vervangen; een toets hoort bij één actie; terugzetten kan. Controllerknoppen blijven zoals ze zijn.
- **Instellingen onthouden.** `UserSettings` bewaart volledig scherm, breedbeeld, 4:3-pixels, geluid aan/uit en de toetsen in `settings.cfg`. F2/F3/F4 slaan ook op.
- **Extra informatie in breedbeeld** (op verzoek van de gebruiker, 14-10-2026): op de kaart en in levels staan in breedbeeld twee kleine babyblauwe balkjes (de grijze achtergrond van de icoontjes is weggehaald) in de bovenhoeken (`Hud`): links Keen met het aantal levens en "Score" met de score, rechts het straalgeweer met de ladingen en de sleutelkaarten die je hebt (als icoontjes). De hulpregel bovenin toont dan alleen nog korte berichten, in het midden.
- De regel met toetsen onderin staat standaard uit (op verzoek van de gebruiker); F1 laat hem zien of verbergt hem.
- Met een menu open is de bovenkant van het scherm leeg (geen hulpregel meer erachter).
- **Volledig scherm** (op verzoek van de gebruiker, 14-10-2026): het spel start standaard in volledig scherm. F4 of Options > Full screen wisselt naar een venster en terug; de keuze wordt onthouden.
- **Game over en highscores.** Na het laatste leven het GAMEOVER-plaatje, daarna (en ook na het einde) de highscores: met een goede score vraagt het spel om een naam ("You got first place!"). `HighScores` (7 plaatsen, naam, score, scheepsonderdelen) wordt bewaard in `high_scores.json`. De standaardnamen en de woorden voor de plaatsen komen uit de eigen `KEEN1.EXE` (`ScoreTexts`).
- `GraphicsTextures`: gedeelde cache van texturen (lettertype, tiles, sprites, bitmaps) voor `GameWindow` en de nieuwe `PictureLayer` (plaatjes en tekst op een map). `GameWindow` kan nu ook bitmaps tonen.
- `tools/scripted_play.gd`: speelt het spel met gescripte toetsen en maakt screenshots (uitleg bovenin het script). Let op: dat schrijft wel naar de echte instellingen, saves en highscores.
- Tests: `test_sounds.gd` (geluidsbestand, synthese, prioriteit, welke gebeurtenissen geluid maken), `test_saving.gd` (voortgang, saves, highscores, toetsen, instellingen), `test_menus.gd` (cursor, hoofdmenu, opslaan, overschrijven, laden, toets wijzigen, opties, naam typen, story), een kaartgeluid-test in `test_world_map.gd`, `LevelData.crop` in `test_level_rendering.gd`, en op de echte data in het nieuwe `test_keen1_extras.gd`: alle geluiden bestaan, de highscoreteksten worden gevonden, de schermen van map 90 en de plaatjes bestaan, en de story past in het venster.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn het titelscherm, het hoofdmenu,
Controls, Continue, Story, game over, een naam invullen, de highscores (ook
in breedbeeld) en opslaan + laden op de wereldkaart via screenshots
gecontroleerd. Het geluid is nog niet met het oor naast het origineel gelegd.

## Mijlpaal 7: wat er nu is

Afspraak met de gebruiker (14-10-2026): het origineel blijft zoals het is.
Alle extra's zijn opties die standaard **uit** staan; alleen breedbeeld (met
de HUD-balkjes) staat standaard aan. Uitleg van alles: `docs/graphics.md`.

- **Instellingen.** Options heeft twee nieuwe regels: *Smooth motion* (aan/uit, of F6) en *Graphics* (ORIGINAL / XBRZ / HD, of F5). HD is pas kiesbaar als de speler HD-graphics heeft gemaakt. Beide worden onthouden in `settings.cfg`. F5 en F6 kunnen niet aan een spelactie worden gegeven.
- **Tekenen.** Bij het originele beeld is alles zoals het was (320x200 of 356x200, hele pixels). Anders tekent de `World`-viewport op een heel veelvoud (2-8x) van de spelresolutie, ongeveer zo groot als het scherm, zodat fijnere graphics en tussenposities te zien zijn. Daarna rekt `even_pixels.gdshader` het beeld uit met alle spelpixels even groot, ook bij vensters die geen heel veelvoud zijn (dat was een bekende beperking).
- **xBRZ** (`src/graphics/xbrz_scaler.gd`): een eigen implementatie van het idee van xBRZ, 6x, per plaatje. Alle graphics worden op de achtergrond over alle kernen gemaakt (`GraphicsLoader`, onder een seconde); het spel loopt intussen door.
- **HD-graphics met Real-ESRGAN.** `tools/make_hd_graphics.sh` zet alle graphics op een paar grote vellen (`HdPack`, `GraphicsSheet`), laat `realesrgan-ncnn-vulkan` ze 4x vergroten (model `realesrgan-x4plus-anime`) en zet het resultaat in `game_data/keen1/hd/` (en naast de Mac-app). De doorzichtigheid van de sprites gaat op een apart masker-vel mee. Op verzoek van de gebruiker is Real-ESRGAN v0.2.5.0 (macOS) gedownload naar `tools/realesrgan/` (genegeerd door git); het script gebruikt die map vanzelf. Draaien duurt ~7 s op de M5; het resultaat werkt in het spel, maar per tile wijkt de kleur van vlakke stukken een klein beetje af, waardoor je op de kaart en rond items zwakke vierkantjes ziet.
- **Alle textures via één plek.** `GraphicsTextures` levert nu ook de tile-atlas (met een rand per tile tegen naden), de deuren, het plaatje van het huis en de sprites voor Keen en de vijanden. Grotere plaatjes krijgen de maat van het origineel (`set_size_override`), zodat de rest van het spel niets hoeft te weten.
- **Vloeiende beweging** (`Interpolation`): Keen, vijanden, schoten, het schip en de tekens worden elk frame tussen de laatste twee ticks getekend; de camera volgt de getekende positie. Een sprong van meer dan 24 pixels (nieuw level, teleporter) wordt niet tussendoor getekend. De snap van Godot werkt in spelpixels en staat daarom alleen aan bij het originele beeld.
- **Windows.** `tools/build_windows.sh` maakt op de Mac `build/windows/CommanderPerfect.exe` (64-bit, alles in één .exe) met de speldata ernaast in `game_data/keen1`. De Windows-templates van Godot 4.7.2 zijn geïnstalleerd (alleen de twee .exe-bestanden uit het officiële pakket).
- Tests: `test_graphics.gd` (xBRZ: vlakken en rechte randen blijven, diagonalen worden glad, doorzichtigheid; kleurafstand; vellen heen en terug; HD-pakket heen en terug met een nep-upscaler; textures houden hun maat; randen van de atlas; interpolatie; wisselen van graphics), plus de nieuwe standaardinstellingen en opties in `test_level_rendering.gd`, `test_menus.gd` en `test_saving.gd`.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn level 1, het titelscherm en het
optiemenu in origineel, xBRZ, (nep-)HD en met vloeiende beweging via
screenshots gecontroleerd. De Windows-build is gemaakt maar nog niet op een
Windows-pc gestart. Vloeiende beweging moet met het oog beoordeeld worden.

## Mijlpaal 8: wat er nu is

Afspraken met de gebruiker (14-10-2026): twee spelers op één toetsenbord
(geen controllers), op elk moment in- en uitstappen, gedeelde voorraad,
doodgaan zoals het origineel (één Keen dood = allebei terug naar de kaart),
op de kaart loopt speler 1 alleen. Alleen spelen blijft precies zoals het
was, ook de toetsen. Uitleg van alles: `docs/two-players.md`.

- **Meedoen.** F7 of "Add Player 2" / "Remove Player 2" in het menu tijdens een spel. In een level verschijnt Keen 2 bij Keen 1; op de kaart doet hij mee vanaf het volgende level. Keen 2 heeft andere kleuren (alle tinten een halve kleurcirkel gedraaid, `player_colors.gdshader`): blauwe helm.
- **Toetsen** (`KeyBindings`): drie sets. Alleen: zoals altijd. Speler 1: WASD, linker Shift springen, Z vuren, ` pogo. Speler 2: pijltjes, . springen, / pogo, rechter Shift vuren. Linker en rechter Shift zijn verschillende toetsen (Godot `location`); een toets wordt bewaard als keycode + kant. Controls heeft nu drie pagina's. Op de kaart sturen alle toetsen samen speler 1 (`KeenInput.combine`). Geen Ctrl voor twee spelers: Ctrl+pijltje wisselt op de Mac van bureaublad.
- **Level-logica** (`LevelSession`): `keens` (speler 1 is nog steeds `keen`), `add_player`, `remove_player`, `step_players`. Items, deuren, schieten, beelden en de uitgang werken voor beide Keens. Vijanden gaan op de dichtstbijzijnde levende Keen af en raken beide; ze worden wakker in het beeld van elk van beide spelers (`view_rects`). De uitgang gaat niet open terwijl de andere Keen doodgaat; wie de uitgang in loopt, maakt het level voor allebei af.
- **Split-screen** (`SplitScreen` rekent, `TwoPlayerView` tekent): samen één beeld; als een speler verder komt dan halverwege het midden en de rand, glijden de camera's uit elkaar en splitst het scherm met een donkere lijn door het midden, loodrecht op de lijn tussen de spelers (draait mee). Bij de rand van een level blijft het langer één scherm, en het komt pas weer samen 8 pixels verder (geen flikkeren). Een tweede viewport (`World2`) deelt het level met `World`; `split_screen.gdshader` legt zijn beeld over de helft van speler 2, onder de HUD. Er is geen pijltje naar de andere speler: na de speeltest wilde de gebruiker het weg (je ziet aan de split welke kant je op moet). Voor online multiplayer is het wel nodig; dat staat beschreven in `docs/two-players.md` onder "Later: online".
- `LevelView` werd te lang: het twee-spelersdeel staat in `TwoPlayerView`, de hulpregel in `StatusLine`, het instellen van een viewport in `DisplaySettings.set_up_viewport`.
- `tools/scripted_play.gd` kent nu `LeftShift` / `RightShift`.
- Tests: `test_two_players.gd` (twee Keens: meedoen, eigen besturing, gedeelde items en munitie, doodgaan, uitgang, vijanden, wakker worden, vertrekken, god mode; de standaardtoetsen, linker/rechter Shift, overlappende sets, opslaan met kant, gecombineerde invoer op de kaart), `test_split_screen.gd` (één scherm, splitsen, geen sprong, binnen het level, bij de rand, smal level, dode speler, dode zone), plus menutests (speler 2 toevoegen, toets van speler 2 wijzigen).

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer is in level 1 gecontroleerd dat speler 2
erbij komt, apart bestuurd wordt (pijltjes en .), andere kleuren heeft, en
dat het scherm splitst met de lijn. De gebruiker heeft het gespeeld en vindt
het er goed uitzien (14-10-2026); alleen de pijltjes naar de andere speler
moesten weg.

## Mijlpaal 9: wat er nu is

Afspraken met de gebruiker (15-10-2026), zoals in Together Around: hosten
via Steam (alleen vrienden, App ID 480) of via IP met dezelfde poort (UDP
24800). Online twee Keens (host + 1), F7 doet dan niets. Optioneel
wachtwoord (via IP standaard aan, via Steam uit), basiscontrole op alle
berichten, geen kick-knop of security-log. Hosten kan vanuit het
hoofdmenu (nieuw spel) en vanuit het Escape-menu (huidig spel loopt door).
Naam: de Steam-naam, of via IP één keer intypen. Bij joinen een nieuwe
ping (eigen PC-speakergeluid) en "*Naam* joined" rechtsonder. Wie joint
staat altijd naast de Keen van de host. Op de kaart loopt alleen de host;
drukt de ander een pijltje of knop, dan "Only the host can walk on the
world map". Online pauzeert niets (zolang er echt samen gespeeld wordt; hosten zonder
dat iemand gejoind is gedraagt zich als alleen spelen). Pijltje naar de ander als hij uit beeld
is (alleen online). De host controleert een checksum van de levels en
weigert een andere versie. Uitleg van alles: `docs/online.md`.

- **Menu** (`MenuController`, `OnlineMenuInfo`): "Online Game" in het
  hoofdmenu met Host via Steam, Host via IP, Join via Steam (lijst van
  spellen van vrienden, `*` = wachtwoord), Join via IP (adres wordt
  onthouden) en Your Name. Tijdens hosten: de adressen (LAN, internet via
  api.ipify.org, poort, wachtwoord), wie meespeelt, en Stop Hosting. Wie
  joint heeft een eigen hoofdmenu: Return to Game, Leave Game, Story,
  Controls, Options, Quit. Tekstinvoer voor naam, adres en wachtwoord.
- **Netwerk** (`src/online/`): `OnlineSession` (eigen `SceneMultiplayer`,
  zelf gepold, dus testbaar zonder scèneboom), `EnetTransport` en
  `SteamTransport`, de handshake (`JoinHandshake`, `JoinGate`,
  `JoinTicket`: nonce + SHA-256, het wachtwoord gaat nooit over de lijn,
  5 keer fout = 1 minuut buiten), `LevelFingerprint`, `SteamService` en
  `SteamLobby` (overgenomen van Together Around, aangepast), `HostAddresses`.
- **Synchronisatie**: de host rekent alles. Elke tick een `Snapshot`
  (Keens, actors met een vast id, zinkende deuren, voorraad, geluiden),
  onbetrouwbaar verstuurd; scènes (kaart, level, game over, einde, wachten)
  met alle tiles die afwijken van het levelbestand; tile-wijzigingen en
  vensters (beeldje, Keens Left, scheepsonderdelen, "Level n completed!")
  als events. Wie joint stuurt alleen zijn knoppen als ze veranderen
  (`OnlineInput`, één wijziging per tick, dus een tikje blijft een tik) en
  af en toe wat hij ziet (vijanden worden daar wakker). `SnapshotBuffer`
  houdt 2 plaatjes reserve.
- **Spelscherm**: `LevelView` werd te lang (gdlint max 1000 regels); wat er
  op het scherm staat en hoe het getekend wordt (beeld, graphics, F1-F6,
  statusregel, HUD, vensters) staat nu in de basisklasse `GameScreen`
  (letterlijk verplaatst, niets aan veranderd). Online: `OnlinePlay`
  (netwerk, menukeuzes, meldingen, ping), `RemoteGame` (wat wie joint ziet,
  in de nieuwe mode `REMOTE`, en het pijltje), `OnlineNotice`,
  `PartnerArrow`, `OnlineSpawn` (naast de host, eerst ervoor),
  `PingSound`. `TwoPlayerView` kan nu ook zonder split-screen (online) en
  tekent de eigen Keen van wie joint.
- **Steam-plug-in**: GodotSteam GDExtension 4.23.1 in `addons/godotsteam/`,
  meegecommit met alleen de macOS- en Windows-bibliotheken (zoals in
  Together Around). Op Linux zegt Godot dat hij hem niet kan laden; dat is
  verwacht.
- `tools/scripted_play.gd` kan nu tekst typen (`type_127.0.0.1`).
- Tests: `test_online_session.gd` (handshake: wachtwoord, buitensluiten,
  andere versie/levels, vol, rommel; een echte host en joiner via ENet op
  deze machine, verkeerd wachtwoord, geen antwoord), `test_online_sync.gd`
  (snapshot heen en terug, kapotte berichten, kopieën van actors, knoppen,
  tikje, flood, buffer, berichten, gewijzigde tiles, plek naast de host,
  pijltje, Steam-lobbydata, adressen, ping), `test_online_menus.gd`
  (hoofdmenu's, hosten via IP/Steam, joinen via IP/Steam, hostinfo), plus
  naam en adres in `test_saving.gd` en de checksum op de echte data.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met twee instanties op deze machine (elk een eigen
gebruikersmap) is via het menu gehost en gejoind via IP: de Keen van wie
joint staat naast de host, beweegt bij de host mee, "GUEST joined" en
"Joined HOST's game" verschijnen, Shift+N (ander level) en New Game (de
kaart met Keens Left) komen bij wie joint aan, de kaartmelding verschijnt,
de pijltjes wijzen naar de ander, en als de host stopt gaat wie joint terug
naar zijn titel met "The host has left the game". Steam kon hier niet
getest worden (geen Steam in de cloud) en is ook in Together Around nog
niet met twee echte accounts geprobeerd. De ping is niet beluisterd.

## Mijlpaal 10: wat er nu is

Afspraken met de gebruiker (15-10-2026): het spel begint altijd op een
startscherm met het aangeleverde CommanderPerfect-plaatje, heel en zo groot
als past, met daaronder een donkergrijze balk die altijd ruimte heeft
(minstens 10% van de hoogte; op 16:9 wordt het plaatje iets kleiner met
grijs ernaast). Linksonder een icoon per spel (Keen 1 helemaal links, op
verzoek van de gebruiker), nu alleen "Keen 1" (niet
"Commander Keen", zie CLAUDE.md), met Keen uit de eigen speldata. Hover
of kiezen met pijltjes/controller maakt het icoon iets donkerder; klik,
Enter of A opent het bestaande hoofdmenu. Zonder speldata een grijs icoon
met uitleg. "Quit to Title" blijft naar de Keen 1-titel gaan; nieuw in het
hoofdmenu is "Choose Game" (terug naar het startscherm). Met `--level=N` of
`--ending` wordt het startscherm overgeslagen.

- `src/launcher/`: `Launcher` (de scène, nu de hoofdscène in
  `project.godot`), `LauncherLayout` (waar plaatje, balk en iconen komen),
  `GameIcon` (het icoon, getekend in icoonpixels en met een heel getal
  vergroot), `GameCatalog` (de spellen; hier komen latere delen bij) en
  `GameLaunch` (geeft door dat het hoofdmenu meteen open moet, en welke
  opstartopties het startscherm overslaan).
- Het plaatje staat in `assets/launcher/background.png` (eigen plaatje van
  de gebruiker, mag in de repo).
- Escape op het startscherm: "Press Escape again to quit"; nog een keer
  Escape sluit het programma. Volledig scherm volgt de instelling van het
  spel.
- `tools/scripted_play.gd`: `SCENE=` voor een andere scène (zoals het
  startscherm), `mouse_X_Y` en `click_X_Y`, en de scène wordt nu echt de
  huidige scène (anders bleef bij wisselen de oude staan).
- Tests: `test_launcher.gd` (indeling op 16:10 en 16:9, iconen linksonder,
  donkerder onder de muis, grijs zonder bestanden, de uitleg, alleen
  "Keen 1", het hoofdmenu één keer openen, opstartopties, "Choose Game").

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn het startscherm (1280x800 en
1600x900), hover en het pijltje, klik en Enter naar het hoofdmenu, "Choose
Game" terug naar het startscherm en de Escape-melding via screenshots
gecontroleerd.

## Mijlpaal 11: wat er nu is

Gemeld door de gebruiker (16-10-2026) na het mergen van mijlpaal 10.

- **Crash bij "Choose Game"** (macOS en Windows) opgelost. De scène wisselde
  terwijl `LevelView` de toets nog afhandelde; Godot haalt de oude scène dan
  meteen uit de boom, en de rest van de afhandeling liep op een node zonder
  viewport (hier een scriptfout, in de builds een crash). Beide wissels die
  vanuit invoer gebeuren (naar en van het startscherm) gaan nu met
  `call_deferred`. Nagespeeld met gescripte invoer: "Choose Game" vanuit een
  lopend spel en vanuit het titelmenu, en daarna weer Keen 1.
- **Nieuw app-icoon** (Dock en taakbalk). Eerst een pixel-Keen met "CP" op
  grijs; de gebruiker vond Keen lelijk, dus nu alleen de letters "CP" (dik,
  geel met rode diepte en zwarte rand, zoals het logo op het startplaatje)
  voor een kleurrijke sterrenhemel met planeet, paarse bergen en grijze
  grond, pixel-art op 64x64. Niets uit de originele bestanden.
  `tools/make_app_icon.py` (Python + Pillow) tekent het en schrijft `assets/icon/app_icon.png` (macOS-build),
  `assets/icon/app_icon.ico` (Windows-build) en `icon.svg` (venster en
  editor). In `export_presets.cfg` staan de iconen nu ingesteld; voor
  Windows staat `modify_resources` daarvoor aan (Godot zet het icoon dan zelf
  in de .exe).

- **Achtergronden achter levels** (op verzoek van de gebruiker, met zijn
  eigen plaatje voor level 1): in widescreen toont een level met een eigen
  plaatje dat achter zich in plaats van de egale achtergrond. Optie
  *Backgrounds* in Options; **standaard aan** (keuze van de gebruiker, een
  uitzondering op "extra's standaard uit", ook in CLAUDE.md gezet), in 4:3
  altijd uit (niet te kiezen). Zonder plaatje: het origineel.
  - Plaatjes: `assets/backgrounds/levelNN.png/.webp/.jpg` (nu
    `level01.webp`, 1536x1024). Om te proberen zonder te bouwen: een
    plaatje met dezelfde naam in `backgrounds/` naast de speldata (bijv.
    `game_data/keen1/backgrounds/level01.png`) gaat voor.
  - De egale achtergrond-tile van een level wordt gevonden (meest gebruikt,
    één kleur, nergens op te staan; level 1: tile 143, lichtgrijs). Die
    kleur wordt uit alle tiles weggelaten waar hij de rand raakt, zodat het
    grijs rond snoep, pilaren en platforms weg is en grijs binnen in dingen
    blijft (`GraphicsTextures.backdrop_tile_atlas`; voor xBRZ/HD worden de
    gaten mee vergroot).
  - Het plaatje bedekt het beeld (15% ruimer), bovenkant aan de bovenkant
    (lucht en horizon altijd in beeld), en schuift van links naar rechts
    mee met hoe ver je in het level bent (`LevelBackdrop`, ook in de tweede
    helft van het split-screen).
  - Het plaatje is 3:2; daardoor schuift het weinig (een breder plaatje,
    zoals 3840x1080, geeft meer diepte) en de zijkanten sluiten niet
    naadloos aan (maakt niet uit: het herhaalt niet).
- Tests: `test_backdrops.gd` (achtergrond-tile, gaten alleen rond dingen,
  plaats van het plaatje links/rechts/smal level, standaard aan en alleen
  in widescreen, onthouden, menu-optie, eigen map gaat voor, level 1 heeft
  een plaatje).
- **Builds pakten te veel in.** `.gitignore` geldt niet voor Godot: de
  export ("all_resources") nam ook de plaatjes uit `exported/` en `build/`
  mee in het pakket (afgeleid van de originele bestanden). Beide presets
  sluiten nu `build/*, exported/*, game_data/*` uit; het spel laadt daar
  niets uit via `res://` (de speldata wordt naast de app gelezen). App
  184 → 172 MB, .exe 119 → 106 MB.

Getest: alle tests slagen, gdlint is schoon; met gescripte invoer is level 1
met de achtergrond bekeken (lopen, origineel, xBRZ, 4:3 = origineel, optie
uit = origineel). Op de Mac (16-10-2026) beide builds gemaakt: geen
meldingen over het icoon, `icon.icns` in de app is het "CP"-icoon, en de
gebouwde app start level 1 met de achtergrond. De gebruiker heeft
"Choose Game" in de gebouwde app geprobeerd: geen crash meer.

## Mijlpaal 11.2: wat er nu is

Op verzoek van de gebruiker (16-10-2026). Alles valt onder de nieuwe optie
**Extra levels** in Options, standaard aan (keuze van de gebruiker); uit =
het origineel. Details in `docs/world-map.md` onder "Extra levels".

- **Het schip als level** (nummers 100 buiten, 101 binnen; `ShipLevels`,
  `ShipVisit`, `ShipRepair`, `ShipSmoke`, `ShipInterior`, `ShipPicture`).
  Op de kaart start het schip het level, ook als Keen ernaast staat (idee
  van de gebruiker). Buiten: het schip van het titelscherm met rook op
  Mars; links/rechts uit beeld = terug naar de kaart; achter in het schip
  loopt Keen naar binnen met de animatie van de einddeuren (onzichtbare
  ingang, op verzoek van de gebruiker; eerst stond er een zichtbare deur).
  Binnen: een kleine getekende cabine (ramen, buizen, kabels, tank,
  cockpit met radar en knipperlampjes); vier plekken met grijze
  silhouetten; met het onderdeel loop je ertegenaan en het gaat erin, zonder
  verschijnt een bordje "... still missing". Door het luik links weer
  naar buiten. Na het vierde onderdeel begint het einde (keuze van de
  gebruiker: niet meer vanzelf bij vier onderdelen). Ingebouwde onderdelen
  staan in het opgeslagen spel (`installed_parts`, oude saves werken).
- Opgelost na de eerste test van de gebruiker: in de cabine liep Keen
  zonder animatie, kon hij niet springen en "gleed" hij (de eigen vaste
  cellen telden niet als vloer, dus Keen viel steeds; vermoedelijk ook het
  harde gekraak: elke tick een landingsgeluid). De meldingen staan nu als
  één bordje bovenaan in het midden (`ScreenNote`); een nieuwe vervangt de
  oude.
- De melding "Level N completed!" is weg (hoorde niet bij het origineel,
  besluit van de gebruiker); na een level is er alleen het "done"-bord.
- **Level 5 (pogo) opnieuw** zolang Keen de pogo niet heeft; punten tellen
  dan niet, munitie wel (keuze van de gebruiker).
- **Onderdelen in de HUD** rechtsboven, op de kaart en in het schip.
- `level_view.gd` liep over de 1000 regels: het volgen van de camera staat
  nu in `GameScreen`.
- Tests: `test_ship.gd` (zonder speldata) en `test_keen1_ship.gd` (speelt de
  echte scheepslevels).

## Bekende beperkingen

- De natuurkunde-getallen zijn startwaarden (overgenomen van Commander Genius als documentatie, zie `docs/keen-physics.md`). Ze moeten nog naast het origineel (DOSBox) worden gelegd; de lijst met punten staat onderaan dat document.
- Veel getallen voor vijanden zijn schattingen (gemarkeerd met *estimate* in de code); de lijst met wat nog naast het origineel moet staat onderaan `docs/enemies.md`. Vooral: levenspunten van Vorticons (4) en de commandant (105).
- Gedrag 23 (lichtschakelaar) wordt door geen enkel level van Keen 1 gebruikt en doet niets.
- Veel getallen op de kaart en in het einde zijn overgenomen van Commander Genius of geschat: loopsnelheid op de kaart, de teleporter, de vluchten van het schip (de vlucht naar de aarde duurt nu ~28 s). De lijst staat onderaan `docs/world-map.md`.
- De doelen van de teleporters staan in de code van `KEEN1.EXE`, niet in een tabel; ze zijn als vaste waarden in `MapSession` gezet (volgens de documentatie van Commander Genius wijst elk doel precies naar een andere teleporter). Mods met andere doelen werken dus niet.
- In de EXE zijn de vraag van de ouders en Keens antwoord ("Aw, Mom...") één bericht; het origineel toont ze misschien als twee vensters.
- In 4:3-beeld staat de hulpregel linksboven (levelnaam, beeldinstelling, score, levens, munitie) alleen nog onder F1 (besluit van de gebruiker, 16-10-2026); zonder F1 alleen korte meldingen in het midden. De regel bovenin en de toetsenregel onderin zijn hulpmiddelen; het origineel heeft alleen het statusscherm. De toetsenregel noemt de standaardtoetsen, ook als ze zijn veranderd.
- De snelheid van de geluiden (140 Hz) komt uit openbare documentatie en is nog niet met het oor vergeleken. Een paar koppelingen van geluid aan gebeurtenis zijn gokken (zie `docs/sounds.md`); `CLICKSND`, `CRYSTALSND` en `GOINDOORSND` worden niet gebruikt.
- Niet nagebouwd: de intro (Apogee- en id-schermen), de demo, "About ID...", "Ordering Info" en "Previews!". De helptekst (`HELPTEXT.CK1`) wordt niet getoond, omdat die de toetsen van het origineel beschrijft.
- De scores in een nieuwe highscorelijst (100) en de plek van de tabel in de rode lijst zijn geschat.
- Level overslaan (cheat of Page Up/Down) houdt de inventaris, en een level dat zo gekozen is telt wel mee als het wordt uitgespeeld.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) worden als gewone voorgrond-tiles getekend; Keen 1 gebruikt ze niet.
- In de data viewer wordt de info-laag nog alleen gemarkeerd, zonder namen van de vijanden.
- Zodra het beeld niet het originele is (xBRZ, HD of vloeiende beweging), scrolt de camera ook in delen van een spelpixel, ook als vloeiende beweging uit staat. Sprites staan dan wel op hele spelpixels.
- Real-ESRGAN is gemaakt voor foto's en tekeningen, niet voor pixelart; of `realesrgan-x4plus-anime` mooi is, moet blijken. Een ander model kiezen kan met `MODEL=`.
- Op schermen hoger dan 1200 pixels (Retina) wordt xBRZ (6x) nog een beetje glad vergroot.
- Vloeiende beweging toont alles één tick (17 ms) later.
- Of de wereldkaart ook precies een rand van 2 tiles verbergt, is aangenomen maar niet vergeleken met het origineel.
- Twee spelers: de controller bestuurt alleen speler 1; twee controllers worden nog niet uit elkaar gehouden. Of speler 2 meespeelt, wordt niet in een opgeslagen spel bewaard. De toetsenregel (F1) noemt alleen de toetsen voor één speler.
- Met 4:3-pixels is de scheidslijn liggend iets dikker dan staand (hij wordt in spelpixels getekend).
- Online: geen voorspelling, de eigen Keen van wie joint reageert één rondreis later (thuisnetwerk of Steam in Nederland meestal 20-40 ms). Maximaal twee spelers; niet lokaal en online tegelijk. Wie joint ziet het einde in zijn eigen tempo, en op de kaart tijdens het einde ontbreken bij hem de DONE-borden. Of er online gespeeld wordt, gaat niet mee in een opgeslagen spel.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.
- **HD met nieuwe details (generatieve AI)**, besproken op 14-10-2026, voor nu geparkeerd door de gebruiker. Oordeel van de gebruiker: de Real-ESRGAN-HD is "best lelijk", xBRZ ziet er mooier uit, maar hij mist nieuwe details. Real-ESRGAN kan geen details verzinnen; daarvoor is een generatief model nodig. Het plan staat in `docs/graphics.md` onder "Plan: HD with new details". Eerste stap als de gebruiker verder wil: toestemming vragen om Stable Diffusion 1.5 + ControlNet Tile te downloaden (~6 GB, Hugging Face, naar een map die git negeert) en een proef doen met ~10 plaatjes naast xBRZ.

## Volgende stap

1. **Voor de gebruiker:** de scheepslevels proberen in
   `build/CommanderPerfect.app` (nieuwe binnenkant, onzichtbare ingang,
   bordjes bij de plekken) en zeggen wat er beter kan; daarna committen en
   pushen naar `milestone-11.2-extra-mini-game`.
2. Mijlpaal 9 (online): probeer via IP op het thuisnetwerk en via Steam met
   een vriend.
3. Eventueel een breder plaatje voor level 1 en plaatjes voor andere
   levels (in `assets/backgrounds/`), en de openstaande
   punten (natuurkunde en vijanden naast DOSBox leggen, de intro, de
   hulpregel in 4:3, xBRZ/vloeiende beweging bekijken).
