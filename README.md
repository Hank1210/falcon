# Falcon Patrol Remake

Privates Remake des C64-Klassikers *Falcon Patrol* (Virgin Games, 1983) in Godot 4.7.
Planung und Originalregeln: [docs/PRD.md](docs/PRD.md), [docs/ORIGINAL-RULES.md](docs/ORIGINAL-RULES.md).

## Starten

```bash
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

## Export (macOS)

Voraussetzung: Export-Vorlagen fuer Godot 4.7.2 (im Editor: Editor > Export-Vorlagen verwalten > Herunterladen).

```bash
godot --headless --path . --export-release "macOS" build/FalconPatrolRemake.app
```

Die App ist nur ad-hoc signiert (privater Gebrauch). Beim ersten Start auf einem anderen Mac:
Rechtsklick > Oeffnen. Hinweis: JSON-Dateien aus `data/` muessen im Export enthalten sein
(`include_filter` in `export_presets.cfg`).
