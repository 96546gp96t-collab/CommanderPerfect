# Roadmap

Wat elke mijlpaal oplevert. De actuele status staat in
[PROGRESS.md](../PROGRESS.md).

Na mijlpaal 5 is het spel van begin tot eind speelbaar. Mijlpaal 6 en 7 maken
het af en mooi, mijlpaal 8 is een bonus.

## 1. De originele bestanden inlezen

Godot leert de oude bestanden van Keen 1 lezen: levels, tiles (de 16×16-blokjes
waarmee levels gebouwd zijn), sprites (Keen en de vijanden) en afbeeldingen
zoals het titelscherm.

- Een data viewer om alles te bekijken.
- Een exportscript dat alles als PNG opslaat.
- Er beweegt nog niets.

## 2. Levels op het scherm

- Levels echt tekenen in Godot met een `TileMapLayer`.
- Een camera die vloeiend door het level scrollt.
- Keuze tussen 4:3 (origineel) en 16:9 (widescreen).
- Je ziet de wereld, maar Keen staat er nog niet in.

## 3. Keen zelf

- Lopen, springen en pogo-springen.
- Botsen tegen muren en vloeren. De tile-eigenschappen (wat massief is) komen
  uit `KEEN1.EXE`.
- Het doel is dat het springen precies voelt zoals vroeger. Hier zit de meeste
  fijnafstemming.

## 4. Vijanden en spullen

- Yorps, Garg's, Vorticons en robots met hun eigen gedrag.
- Snoep en punten.
- Sleutelkaarten en gekleurde deuren.
- Het straalgeweer met munitie.
- Doodgaan en levens.
- Na deze mijlpaal kun je een los level helemaal uitspelen.

## 5. Het spel compleet maken

- De wereldkaart van Mars.
- Levels in- en uitgaan.
- Scheepsonderdelen verzamelen.
- Het einde van het spel.
- Na deze mijlpaal kun je Keen 1 van begin tot eind uitspelen.

## 6. Geluid, menu's en opslaan

- De originele PC-speaker-geluidjes.
- Titelscherm en menu's.
- Toetsen instellen.
- Opslaan en laden.

## 7. Mooier maken

- Hogere framerate (60 of 120 fps) via interpolatie, vloeiend in plaats van
  schokkerig.
- xBRZ-schaling met een wisselknop tussen origineel en gladde pixels.
- Real-ESRGAN-pipeline die alle graphics naar HD opschaalt. De speler voert die
  lokaal zelf uit; de resultaten worden nooit gedeeld.
- Export naar macOS en Windows.

## 8. Co-op

- Lokaal: twee spelers op één toetsenbord (speler 1 op WASD, speler 2 op de
  pijltjes), op elk moment in of uit te stappen.
- Dynamisch split-screen: samen één scherm, ver uit elkaar twee helften met
  een donkere lijn en een pijltje naar de ander.
- Later eventueel online. Dan is wel een pijltje nodig dat naar de andere
  speler wijst, want elke speler ziet alleen zijn eigen scherm (zie
  [two-players.md](two-players.md#later-online)).
