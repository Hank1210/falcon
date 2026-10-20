#!/usr/bin/env python3
"""Wandelt Text-Pixelkarten (tools/sprites/*.txt) in PNGs (assets/sprites/*.png).

'.' ist transparent, '#' ist weiss. Gegner und Spieler unterscheiden sich im
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

COLORS = {
    ".": (0, 0, 0, 0),
    "#": (255, 255, 255, 255),
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
