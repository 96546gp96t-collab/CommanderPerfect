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
| 6 | Geluid, menu's, opslaan | 🔶 Gebouwd, nog speeltesten (branch `milestone-6-sound-menus`) |
| 7 | Hogere framerate (interpolatie), xBRZ met wisselknop, Real-ESRGAN-pipeline | |
| 8 | Lokale co-op, later eventueel online | |

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
- **Instellingen onthouden.** `UserSettings` bewaart breedbeeld, 4:3-pixels, geluid aan/uit en de toetsen in `settings.cfg`. F2/F3 slaan ook op.
- **Game over en highscores.** Na het laatste leven het GAMEOVER-plaatje, daarna (en ook na het einde) de highscores: met een goede score vraagt het spel om een naam ("You got first place!"). `HighScores` (7 plaatsen, naam, score, scheepsonderdelen) wordt bewaard in `high_scores.json`. De standaardnamen en de woorden voor de plaatsen komen uit de eigen `KEEN1.EXE` (`ScoreTexts`).
- `GraphicsTextures`: gedeelde cache van texturen (lettertype, tiles, sprites, bitmaps) voor `GameWindow` en de nieuwe `PictureLayer` (plaatjes en tekst op een map). `GameWindow` kan nu ook bitmaps tonen.
- `tools/scripted_play.gd`: speelt het spel met gescripte toetsen en maakt screenshots (uitleg bovenin het script). Let op: dat schrijft wel naar de echte instellingen, saves en highscores.
- Tests: `test_sounds.gd` (geluidsbestand, synthese, prioriteit, welke gebeurtenissen geluid maken), `test_saving.gd` (voortgang, saves, highscores, toetsen, instellingen), `test_menus.gd` (cursor, hoofdmenu, opslaan, overschrijven, laden, toets wijzigen, opties, naam typen, story), een kaartgeluid-test in `test_world_map.gd`, `LevelData.crop` in `test_level_rendering.gd`, en op de echte data in het nieuwe `test_keen1_extras.gd`: alle geluiden bestaan, de highscoreteksten worden gevonden, de schermen van map 90 en de plaatjes bestaan, en de story past in het venster.

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn het titelscherm, het hoofdmenu,
Controls, Continue, Story, game over, een naam invullen, de highscores (ook
in breedbeeld) en opslaan + laden op de wereldkaart via screenshots
gecontroleerd. Het geluid is nog niet met het oor naast het origineel gelegd.

## Bekende beperkingen

- De natuurkunde-getallen zijn startwaarden (overgenomen van Commander Genius als documentatie, zie `docs/keen-physics.md`). Ze moeten nog naast het origineel (DOSBox) worden gelegd; de lijst met punten staat onderaan dat document.
- Veel getallen voor vijanden zijn schattingen (gemarkeerd met *estimate* in de code); de lijst met wat nog naast het origineel moet staat onderaan `docs/enemies.md`. Vooral: levenspunten van Vorticons (4) en de commandant (105).
- Gedrag 23 (lichtschakelaar) wordt door geen enkel level van Keen 1 gebruikt en doet niets.
- Veel getallen op de kaart en in het einde zijn overgenomen van Commander Genius of geschat: loopsnelheid op de kaart, de teleporter, de vluchten van het schip (de vlucht naar de aarde duurt nu ~28 s). De lijst staat onderaan `docs/world-map.md`.
- De doelen van de teleporters staan in de code van `KEEN1.EXE`, niet in een tabel; ze zijn als vaste waarden in `MapSession` gezet (volgens de documentatie van Commander Genius wijst elk doel precies naar een andere teleporter). Mods met andere doelen werken dus niet.
- In de EXE zijn de vraag van de ouders en Keens antwoord ("Aw, Mom...") één bericht; het origineel toont ze misschien als twee vensters.
- De regel bovenin (score, levens, munitie) en de toetsenregel onderin zijn hulpmiddelen; het origineel heeft alleen het statusscherm. De toetsenregel noemt de standaardtoetsen, ook als ze zijn veranderd.
- De snelheid van de geluiden (140 Hz) komt uit openbare documentatie en is nog niet met het oor vergeleken. Een paar koppelingen van geluid aan gebeurtenis zijn gokken (zie `docs/sounds.md`); `CLICKSND`, `CRYSTALSND` en `GOINDOORSND` worden niet gebruikt.
- Niet nagebouwd: de intro (Apogee- en id-schermen), de demo, "About ID...", "Ordering Info" en "Previews!". De helptekst (`HELPTEXT.CK1`) wordt niet getoond, omdat die de toetsen van het origineel beschrijft.
- De scores in een nieuwe highscorelijst (100) en de plek van de tabel in de rode lijst zijn geschat.
- Level overslaan (cheat of Page Up/Down) houdt de inventaris, en een level dat zo gekozen is telt wel mee als het wordt uitgespeeld.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) worden als gewone voorgrond-tiles getekend; Keen 1 gebruikt ze niet.
- In de data viewer wordt de info-laag nog alleen gemarkeerd, zonder namen van de vijanden.
- Bij een venstergrootte die geen heel veelvoud van het beeld is, worden niet alle pixels even breed of hoog getekend (vooral zichtbaar met de 4:3-correctie). Dit lossen we op in mijlpaal 7, samen met xBRZ (bijv. eerst op een heel veelvoud renderen en dan glad verkleinen).
- Of de wereldkaart ook precies een rand van 2 tiles verbergt, is aangenomen maar niet vergeleken met het origineel.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.

## Volgende stap

1. **Voor de gebruiker:** speel de nieuwe build (`build/CommanderPerfect.app`): luister of de geluiden kloppen (toonhoogte, lengte, welke wanneer), probeer het menu (Escape), toetsen wijzigen, opslaan op de kaart en weer laden, en een game over met de highscores. Vergelijk als het kan met het origineel (DOSBox), vooral de punten onderaan `docs/sounds.md` en `docs/menus.md`.
2. Mijlpaal 6 afronden met wat uit die test komt, en mergen naar `main`.
3. **Mijlpaal 7**: hogere framerate via interpolatie, xBRZ met wisselknop, de Real-ESRGAN-pipeline, en een Windows-build. Daar hoort ook bij: pixels netjes schalen bij vensters die geen heel veelvoud zijn.
