# Falcon Patrol Remake

Privates Remake des C64-Klassikers *Falcon Patrol* (Virgin Games, 1983) in Godot 4.7.
Planung und Originalregeln: [docs/PRD.md](docs/PRD.md), [docs/ORIGINAL-RULES.md](docs/ORIGINAL-RULES.md).

<img width="1068" height="669" alt="Bildschirmfoto 2026-10-28 um 21 55 19" src="https://github.com/user-attachments/assets/7306d0fd-0fdc-40bd-9b63-d4ef6d6fc9d0" />


## Hinweise zur Nutzung

- **Nur private Nutzung.** Dieses Projekt ist ein nicht-kommerzielles Fan-Remake zum Lernen und Ausprobieren.
  Weitergabe, Veroeffentlichung von Builds, kommerzielle Nutzung und der Vertrieb in App-Stores sind nicht gestattet.
  Mit dem Quelltext ist keine Lizenz zur Weiterverbreitung verbunden.
- **Keine fertige App.** Es werden bewusst keine kompilierten Versionen (`.app`, `.exe`, Binaries) bereitgestellt.
  Wer das Spiel spielen will, muss es selbst aus dem Quelltext bauen oder direkt mit Godot starten
  (siehe "Starten" und "Export" unten).
- **Eigene Assets.** Sprites, Schrift und Sounds sind selbst erzeugt (`tools/`); aus dem Original wurde nichts uebernommen.
  *Falcon Patrol* gehoert den jeweiligen Rechteinhabern; dieses Projekt ist nicht mit ihnen verbunden oder von ihnen autorisiert.
- Bereitstellung ohne Gewaehrleistung, auf eigene Gefahr.

## Starten

Voraussetzung: [Godot 4.7](https://godotengine.org/) und Python 3 (nur zum Neuerzeugen der Assets). Die erzeugten Sprites und Sounds liegen bereits im Repo.

```bash
godot --headless --path . --import   # einmalig, importiert die Assets
godot --path .
```

## Steuerung

| Taste | Aktion |
|---|---|
| Pfeil links/rechts | Drehen und beschleunigen, Gegenschub bremst |
| Pfeil hoch/runter | Steigen und Sinken (Hoehe bleibt ohne Gegenschub erhalten) |
| Leertaste | Rakete feuern (Titelbild: Spiel starten) |
| P oder Esc | Pause |
| C | Scanlines (CRT-Effekt) ein/aus |
| T | Titelbild/Pause: Tanksequenz am Lebensanfang ueberspringen ein/aus |
| F | Vollbild ein/aus |

Landen: im Stand ueber einem intakten Flugplatz aufsetzen, dann wird getankt und
aufmunitioniert. Abheben mit "hoch".

## Aufloesung

Spiellogik und Koordinaten laufen in 320x200 logischen Pixeln (wie der C64). Gezeichnet wird in
voller Fensteraufloesung (`stretch/mode=canvas_items`): Sprites sind mit doppelter Pixeldichte
gezeichnet (`Art.SCALE = 0.5`), die 5x7-Schrift wird beim Start geglaettet (`scripts/pixel_font.gd`).

## Entwicklung

- Gameplay-Werte: `data/params.json` (alle Zahlen sind Schaetzungen, siehe ORIGINAL-RULES.md)
- Sprites: Text-Pixelkarten in `tools/sprites/*.txt` (Buchstaben = C64-Farben, doppelte Pixeldichte), daraus per `python3 tools/make_sprites.py` PNGs
- Sounds: `python3 tools/make_sounds.py` synthetisiert alle WAVs nach `assets/audio/`; Lautstaerken in `scripts/sfx.gd` und `_update_audio()` in `scripts/main.gd`
- Selbsttest: `godot --headless --path . --quit-after 3000 -- --selftest` (Ausgabe `SELFTEST OK`)
- Testlauf mit Eingabeskript und Frame-Ausgabe:
  `godot --path . --write-movie /tmp/frames/f.png --fixed-fps 60 --quit-after 400 -- --autoplay`

## Export (macOS) - eigenen Build erzeugen

Es gibt keine vorkompilierte App zum Download; der Build ist selbst zu erzeugen. Voraussetzung: Export-Vorlagen fuer Godot 4.7.2 (Editor > Export-Vorlagen verwalten, oder
`Godot_v4.7.2-stable_export_templates.tpz` von GitHub nach `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` entpacken).

Das Signieren scheitert, wenn die App direkt in einem Ordner unter `~/Documents` entsteht (macOS haengt
Finder-Attribute an). Daher ausserhalb exportieren und mit `ditto` ins Projekt kopieren:

```bash
godot --headless --path . --export-release "macOS" /tmp/export/FalconPatrolRemake.app
ditto --noextattr --norsrc /tmp/export/FalconPatrolRemake.app build/FalconPatrolRemake.app
codesign -v build/FalconPatrolRemake.app   # muss ohne Ausgabe durchlaufen
```

Die App (ca. 160 MB) ist nur ad-hoc signiert (privater Gebrauch). Beim ersten Start auf einem anderen Mac:
Rechtsklick > Oeffnen. JSON-Dateien aus `data/` muessen im Export enthalten sein (`include_filter` in
`export_presets.cfg`). Der Selbsttest laeuft auch in der exportierten App:
`"build/FalconPatrolRemake.app/Contents/MacOS/Falcon Patrol Remake" --headless --quit-after 3000 -- --selftest`.
