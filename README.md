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

Landen: im Stand ueber einem intakten Flugplatz aufsetzen, dann wird getankt und
aufmunitioniert. Abheben mit "hoch".

## Entwicklung

- Gameplay-Werte: `data/params.json` (alle Zahlen sind Schaetzungen, siehe ORIGINAL-RULES.md)
- Sprites: Text-Pixelkarten in `tools/sprites/*.txt`, daraus per `python3 tools/make_sprites.py` PNGs
- Selbsttest: `godot --headless --path . --quit-after 3000 -- --selftest` (Ausgabe `SELFTEST OK`)
- Testlauf mit Eingabeskript und Frame-Ausgabe:
  `godot --path . --write-movie /tmp/frames/f.png --fixed-fps 60 --quit-after 400 -- --autoplay`
