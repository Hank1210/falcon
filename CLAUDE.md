# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Privates Remake des C64-Spiels *Falcon Patrol* (Virgin Games, 1983) in Godot 4.7 / GDScript. Sprache in Code-Kommentaren, Docs und Commit-Nachrichten: Deutsch. Ziel ist moeglichst grosse Originaltreue. Der Quelltext ist oeffentlich (GitHub `Hank1210/falcon`), aber nur fuer private Nutzung; es werden keine fertigen Builds bereitgestellt (`build/` bleibt in `.gitignore`, keine Binaries committen). Nur eigene Assets (nichts aus dem Original uebernehmen); der Titel "Falcon Patrol Remake" bleibt bestehen.

## Befehle

```bash
godot --path .                                   # Spiel starten
godot --headless --path . --import               # nach neuen/geaenderten Assets oder neuen class_name-Skripten PFLICHT
godot --headless --path . --quit-after 3000 -- --selftest   # kompletter Selbsttest, Erfolg = Zeile "SELFTEST OK"
python3 tools/make_sprites.py                    # tools/sprites/*.txt -> assets/sprites/*.png
python3 tools/make_sounds.py                     # synthetisiert assets/audio/*.wav
godot --path . --resolution 1280x800 --write-movie /tmp/f/f.png --fixed-fps 60 --quit-after 400 -- --autoplay   # Frames zum Ansehen
```

- Es gibt keinen Linter und kein Test-Framework; der **Selbsttest** (`_selftest()` am Ende von `scripts/main.gd`) ist der einzige Test. Einzelne Faelle laufen nicht getrennt: neue Checks werden dort in die Sequenz eingefuegt (`check.call(bool, "Beschreibung")`, `run.call(sekunden)` fuer Spielzeit). Das Ergebnis ist der Exit-Code plus `SELFTEST OK`/`SELFTEST FEHLER: ...`. Immer `--quit-after` mitgeben, sonst kann ein Skriptfehler den Prozess haengen lassen (Exit-Code 0 trotz Fehler: auf `SCRIPT ERROR`/fehlendes `SELFTEST OK` pruefen).
- Neue `class_name`-Skripte sind erst nach `--import` bekannt (sonst "Could not find type ...").
- `--autoplay` ersetzt die Tastatur durch ein festes Skript in `scripts/controls.gd` (Start nach 5 Frames, Abheben bei 12 s). Mit `--write-movie` entstehen PNG-Frames, die man mit dem Read-Tool ansehen kann.
- Export (macOS): Vorlagen 4.7.2 sind installiert. Nicht direkt nach `build/` exportieren (liegt unter `~/Documents`, Signierung scheitert an Finder-Attributen), sondern ausserhalb exportieren und mit `ditto --noextattr --norsrc` kopieren (Befehle in `README.md`). `export_presets.cfg` muss `data/*.json` im `include_filter` behalten, sonst fehlt `params.json` in der App. Die Binary heisst `Falcon Patrol Remake` (mit Leerzeichen).

## Architektur

**Koordinaten.** Spiellogik laeuft in logischen 320x200 Pixeln (wie der C64). Gerendert wird in voller Fensteraufloesung (`stretch/mode=canvas_items`); Sprites sind mit doppelter Pixeldichte gezeichnet und werden mit `Art.SCALE = 0.5` dargestellt. Texturgroessen in Spielcode immer ueber `Art.w/h/size()` umrechnen, nie `texture.get_width()` direkt. Die Welt ist ein Ring der Breite `world.width` (1920 px, 6 Bildschirme); Abstaende immer mit `Wrap.dx(a, b)` berechnen, Positionen mit `fposmod` wrappen. Positionen von Sprites/Entities sind die **linke obere Ecke** in Weltkoordinaten (x) bzw. Bildschirm-y; Mittelpunkte ueber `center_x()/center_y()`.

**Datenfluss.** `scripts/main.gd` ist der Spielablauf und besitzt alle Zustaende (`State`-Enum: TITLE, PLAYING, PAUSED, GAME_OVER, NAME_ENTRY), Listen der Entities (enemies, missiles, debris, explosions) und die Spielregeln (Kollisionen, Wellen, Punkte, Leben). `_tick(dt)` verteilt nach Zustand, `_step(dt)` ist ein Spielschritt (fester 60-Hz-Schritt aus `_physics_process`). `Jet`, `Enemy`, `Missile`, `Debris`, `Explosion` haben jeweils nur ihre eigene Bewegung (`step`) und Hitbox-Helfer; Entscheidungen (Treffer, Bomben abwerfen, Absturz) trifft `main.gd`. `World` (`world.gd`) zeichnet Himmel, Boden, Strassen, Flugplaetze, Dekor und das komplette HUD per `_draw`; `main.gd` schiebt jedes Frame die Werte hinein (`_update_view`). `World` besitzt auch den Zustand der sechs Flugplaetze (intakt/zerstoert) und die Abfragen dazu (`pad_index_at`, `nearest_pad`, ...). `Overlay` (Menuetexte mit Panel), `Crt` (Scanlines), `Sfx` (Sounds) sind eigene Nodes.

**Konfiguration.** Alle Gameplay-Zahlen stehen in `data/params.json` und werden ueber `Params.val(section, key)` bzw. `Params.arr` gelesen. Fast alle Werte sind **Schaetzungen**, weil das Original keine Messwerte liefert (siehe `docs/ORIGINAL-RULES.md`, Abschnitt "Zu verifizieren"). Spielgefuehl wird dort nachjustiert, nicht im Code. Neue Zahlen als Param anlegen, nicht hartcodieren.

**Original-Regeln und Layout** stehen in `docs/ORIGINAL-RULES.md` (aus C64-Wiki, Lemon64, MobyGames und Screenshots des Longplays); die Planung in `docs/PRD.md`. Bei Abweichungen vom Original (z. B. Wracks zerstoeren Flugplaetze, Zielfehler der Bomben, kuerzeres Tanken) dort dokumentieren.

**Assets werden aus Text erzeugt.** Sprites sind Textkarten in `tools/sprites/*.txt` (Buchstaben = C64-Farben, siehe `COLORS` in `tools/make_sprites.py`), die PNGs daraus liegen im Repo. Die Spieler-Sprites sind weiss/grau und werden im Spiel per `modulate` eingefaerbt (Jet dunkelblau, Gegner hellrot). Sounds werden komplett von `tools/make_sounds.py` synthetisiert (eigene Klaenge). Nach Aenderungen am Skript/Textkarte: Generator ausfuehren, danach `--import`.

**Schrift.** `PixelFont` enthaelt eine 5x7-Bitmapschrift (nur Grossbuchstaben, Ziffern, `.-:!_ `). Unbekannte Zeichen werden zu Leerzeichen; neue Zeichen in `GLYPHS` ergaenzen. Glyphen werden einmalig per Scale2x geglaettet und als Textur gecacht.

**Persistenz** (user://): `highscores.json` (Top 5) und `settings.json` (Scanlines, Tanksequenz ueberspringen). Der Selbsttest ueberschreibt `Highscores.path` und `Settings.path` auf eigene Testdateien und loescht sie am Ende; neue Tests, die Dateien schreiben, muessen das ebenso tun.

## Fallstricke

- Controls (`scripts/controls.gd`) fragen die Tastatur per Polling ab (`is_physical_key_pressed`) mit eigener Flankenerkennung; `start_pressed`/`pause_pressed` werden in jedem `_tick` aufgerufen, damit die Flanke nie veraltet.
- Der Jet bremst absichtlich staerker als er beschleunigt und rastet bei ~0 kurz ein (`_axis_step` in `jet.gd`); das ist Voraussetzung fuer die Landung (Stillstand ueber Flugplatz, Sinktempo und Resttempo begrenzt).
- Beim Abschuss eines Gegners entsteht ein Wrack (`Debris.Kind.WRECK`), das beim Aufprall einen Flugplatz zerstoeren kann; Bomben treffen Flugplaetze mit Vorhalt (Gegner rechnen die Fallzeit aus). Ein gelandeter Jet geht mit seinem Flugplatz hoch.
- `main.gd` ist gross, weil der Selbsttest dort liegt; Spiellogik und Test sind getrennt durch den Kommentarkopf `# --- Selbsttest`.
