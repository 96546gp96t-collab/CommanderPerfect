# Voortgang

Dit bestand is het geheugen van het project tussen sessies. Werk het aan het
eind van elke sessie bij.

## Mijlpalen

Wat elke mijlpaal precies inhoudt, staat in [docs/roadmap.md](docs/roadmap.md).

| # | Mijlpaal | Status |
|---|---|---|
| 1 | Originele bestanden inlezen in Godot (graphics, levels) + data viewer | ✅ Klaar (branch `milestone-1-data-loading`) |
| 2 | Levels tekenen met TileMapLayer, scrollen, widescreen-camera | ✅ Klaar (branch `milestone-2-level-view`) |
| 3 | Keen: lopen, springen, pogo, botsingen (tile-eigenschappen uit KEEN1.EXE) | ✅ Klaar, vergelijken met het origineel staat nog open (branch `claude/commanderperfect-milestone-3-vm67b1`) |
| 4 | Vijanden, items, deuren, sleutelkaarten, straalgeweer | ⏳ Volgende |
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

## Bekende beperkingen

- De natuurkunde-getallen zijn startwaarden (overgenomen van Commander Genius als documentatie, zie `docs/keen-physics.md`). Ze moeten nog naast het origineel (DOSBox) worden gelegd; de lijst met punten staat onderaan dat document.
- Keen heeft voorlopig altijd de pogo-stick; in het origineel moet je hem eerst vinden (mijlpaal 4).
- Deuren zijn altijd dicht, ook met sleutelkaart (mijlpaal 4). Items, schakelaars en teleporters doen nog niets.
- De betekenis van gedragswaarden 6-24 is afgeleid uit hoe de tiles eruitzien en nog niet bevestigd.
- De data viewer toont tiles nog zonder animatie en zonder voorgrond-markering.
- Gemaskeerde tiles (gedrag -2) worden als gewone voorgrond-tiles getekend; Keen 1 gebruikt ze niet.
- De info-laag wordt nu alleen gemarkeerd; wat elk getal betekent, volgt in mijlpaal 4 en 5.
- Bij een venstergrootte die geen heel veelvoud van het beeld is, worden niet alle pixels even breed of hoog getekend (vooral zichtbaar met de 4:3-correctie). Dit lossen we op in mijlpaal 7, samen met xBRZ (bijv. eerst op een heel veelvoud renderen en dan glad verkleinen).
- Instellingen (beeldverhouding, pixelverhouding) worden nog niet onthouden; opslaan volgt in mijlpaal 6.
- Of de wereldkaart ook precies een rand van 2 tiles verbergt, is aangenomen maar niet vergeleken met het origineel.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.

## Volgende stap

1. **Voor de gebruiker:** speel level 1-3 in CommanderPerfect en in het origineel (DOSBox) naast elkaar en noteer wat anders voelt (zie de lijst in `docs/keen-physics.md`). Test ook de Steam-versie (1.34): wordt de tile-tabel gevonden?
2. **Mijlpaal 4**, beginnen met items: de info-laag van de levels ontcijferen (welke getallen zijn Yorps, Garg's, enz.), dan punten-items en de pogo-stick oppakken (gedrag 6-10 en 16), sleutelkaarten en deuren (18-21 en 2-5), en doodgaan met de `KEENISDEAD`-sprites in plaats van direct opnieuw beginnen.
