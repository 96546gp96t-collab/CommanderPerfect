# Voortgang

Dit bestand is het geheugen van het project tussen sessies. Werk het aan het
eind van elke sessie bij.

## Mijlpalen

Wat elke mijlpaal precies inhoudt, staat in [docs/roadmap.md](docs/roadmap.md).

| # | Mijlpaal | Status |
|---|---|---|
| 1 | Originele bestanden inlezen in Godot (graphics, levels) + data viewer | ✅ Klaar (branch `milestone-1-data-loading`) |
| 2 | Levels tekenen met TileMapLayer, scrollen, widescreen-camera | ⏳ Volgende |
| 3 | Keen: lopen, springen, pogo, botsingen (tile-eigenschappen uit KEEN1.EXE) | |
| 4 | Vijanden, items, deuren, sleutelkaarten, straalgeweer | |
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
- Data viewer (hoofdscène): levels, tiles, sprites, bitmaps en font bekijken, met zoom.
- `tools/export_graphics.gd`: alles als PNG naar `exported/`, de basis voor Real-ESRGAN later.
- Tests: `tests/run_tests.gd` (decompressie, EGA-decodering en de echte Keen 1-data).

Getest met de shareware-versie 1.1 en Godot 4.7.2: alle tests slagen, en de
geëxporteerde PNG's (titelscherm, level 1, wereldkaart, tiles, sprites) zijn
visueel gecontroleerd. De Steam-versie is nog niet getest. Probeer die op je
Mac: zet de bestanden in `game_data/keen1/` en open het project in Godot.

## Bekende beperkingen

- Gemaskeerde tiles (voorgrond), geanimeerde tiles en tile-gedrag staan in `KEEN1.EXE`. Die worden pas in mijlpaal 3 ingelezen. In de viewer zie je de tiles daarom nog zonder transparantie en animatie.
- De info-laag wordt nu alleen gemarkeerd; wat elk getal betekent, volgt in mijlpaal 4 en 5.

## Open beslissingen

- **Licentie** voor de code (bijv. MIT of GPL-3.0): nog kiezen voordat de repo publiek wordt.

## Volgende stap

Mijlpaal 2: een `LevelView`-scène die een level met een `TileMapLayer` tekent, met een camera die vloeiend scrollt en een instelbare beeldverhouding (4:3 origineel, 16:9 widescreen).
