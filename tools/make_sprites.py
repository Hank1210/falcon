#!/usr/bin/env python3
"""Wandelt Text-Pixelkarten (tools/sprites/*.txt) in PNGs (assets/sprites/*.png).

'.' ist transparent, Buchstaben sind C64-Farben (siehe COLORS). Gegner und Spieler unterscheiden sich im
Original nur durch die Farbe, daher wird die Farbe im Spiel per modulate gesetzt.
Nur Standardbibliothek, keine Abhaengigkeiten.
"""
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "sprites"
DST = ROOT / "assets" / "sprites"

def rgb(hexstr: str) -> tuple[int, int, int, int]:
    return (int(hexstr[0:2], 16), int(hexstr[2:4], 16), int(hexstr[4:6], 16), 255)


# C64-Palette (Pepto), je ein Buchstabe pro Farbe
COLORS = {
    ".": (0, 0, 0, 0),
    "#": rgb("ffffff"),  # weiss
    "k": rgb("000000"),  # schwarz
    "r": rgb("68372b"),  # rot
    "R": rgb("9a6759"),  # hellrot
    "c": rgb("70a4b2"),  # cyan
    "p": rgb("6f3d86"),  # lila
    "g": rgb("588d43"),  # gruen
    "G": rgb("9ad284"),  # hellgruen
    "b": rgb("352879"),  # blau
    "B": rgb("6c5eb5"),  # hellblau
    "y": rgb("b8c76f"),  # gelb
    "o": rgb("6f4f25"),  # orange
    "n": rgb("433900"),  # braun
    "d": rgb("444444"),  # dunkelgrau
    "m": rgb("6c6c6c"),  # mittelgrau
    "l": rgb("959595"),  # hellgrau
}


def chunk(tag: bytes, data: bytes) -> bytes:
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def write_png(path: Path, rows: list[str]) -> None:
    width = len(rows[0])
    if any(len(r) != width for r in rows):
        raise ValueError(f"{path.name}: Zeilen haben unterschiedliche Laenge")
    raw = bytearray()
    for row in rows:
        raw.append(0)  # Filtertyp "None"
        for ch in row:
            raw.extend(COLORS[ch])
    ihdr = struct.pack(">IIBBBBB", width, len(rows), 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def main() -> int:
    DST.mkdir(parents=True, exist_ok=True)
    for src in sorted(SRC.glob("*.txt")):
        rows = [line.rstrip("\n") for line in src.read_text().splitlines() if line.strip()]
        out = DST / (src.stem + ".png")
        write_png(out, rows)
        print(f"{src.name} -> {out.relative_to(ROOT)} ({len(rows[0])}x{len(rows)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
