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
| 4 | Vijanden, items, deuren, sleutelkaarten, straalgeweer | 🔶 Gebouwd, nog speeltesten (branch `milestone-4-items-enemies`) |
| 5 | Wereldkaart, levelovergangen, scheepsonderdelen, einde | |
| 6 | Geluid, menu's, opslaan | |
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
- macOS-build: `tools/build_macos.sh` maakt `build/CommanderPerfect.app` (universeel, ad-hoc ondertekend) met de speldata ernaast; `GameFiles` zoekt de data ook naast een `.app`. Hiervoor is de macOS-template van Godot 4.7.2 geïnstalleerd (alleen macOS; Windows volgt in mijlpaal 7).

Getest met Godot 4.7.2 en de shareware-versie 1.1: alle tests slagen, gdlint
is schoon, en met gescripte invoer zijn level 1 (Yorps, items), level 4
(deur, schieten) en level 8 (robots, ijskanonnen) gespeeld en via
screenshots gecontroleerd. Een level helemaal uitspelen met de hand moet nog.

## Bekende beperkingen

- De natuurkunde-getallen zijn startwaarden (overgenomen van Commander Genius als documentatie, zie `docs/keen-physics.md`). Ze moeten nog naast het origineel (DOSBox) worden gelegd; de lijst met punten staat onderaan dat document.
- Veel getallen voor vijanden zijn schattingen (gemarkeerd met *estimate* in de code); de lijst met wat nog naast het origineel moet staat onderaan `docs/enemies.md`. Vooral: levenspunten van Vorticons (4) en de commandant (105).
- Schakelaars (gedrag 23) en teleporters (24) doen nog niets (mijlpaal 5).
- Er is nog geen geluid. De regel bovenin (score, levens, munitie) is een hulpmiddel; het origineel heeft alleen het statusscherm.
- Na de uitgang ga je direct naar het volgende level; de wereldkaart komt in mijlpaal 5. Level overslaan (cheat of Page Up/Down) houdt de inventaris.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) worden als gewone voorgrond-tiles getekend; Keen 1 gebruikt ze niet.
- In de data viewer wordt de info-laag nog alleen gemarkeerd, zonder namen van de vijanden.
- Bij een venstergrootte die geen heel veelvoud van het beeld is, worden niet alle pixels even breed of hoog getekend (vooral zichtbaar met de 4:3-correctie). Dit lossen we op in mijlpaal 7, samen met xBRZ (bijv. eerst op een heel veelvoud renderen en dan glad verkleinen).
- Instellingen (beeldverhouding, pixelverhouding) worden nog niet onthouden; opslaan volgt in mijlpaal 6.
- Of de wereldkaart ook precies een rand van 2 tiles verbergt, is aangenomen maar niet vergeleken met het origineel.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.

## Volgende stap

1. **Voor de gebruiker:** speel een paar levels met vijanden (bijv. 1, 3, 4 en 8) en kijk of iets vreemd voelt: Yorps die duwen, Garg's die aanvallen, robots, ijs. Vergelijk als het kan met het origineel (DOSBox), vooral de punten onderaan `docs/enemies.md`.
2. Daarna mijlpaal 4 afronden met wat uit die test komt, en mergen.
3. **Mijlpaal 5**: de wereldkaart. Eerst de info-waarden op kaart 80 ontcijferen (welke getallen zijn levelingangen, wat betekenen de waarden met 0x8000), dan Keen over de kaart laten lopen en levels in- en uitgaan.
