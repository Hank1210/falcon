#!/usr/bin/env python3
"""Erzeugt icon.png (256x256): der Jet gross auf C64-Blau. Nur Standardbibliothek."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_sprites import COLORS, ROOT, chunk  # noqa: E402
import struct
import zlib

SIZE = 256
BG = COLORS["b"]
SCALE = 12


def main() -> int:
    rows = [l for l in (ROOT / "tools" / "sprites" / "jet.txt").read_text().splitlines() if l.strip()]
    w, h = len(rows[0]), len(rows)
    ox, oy = (SIZE - w * SCALE) // 2, (SIZE - h * SCALE) // 2
    ground = oy + h * SCALE + 24
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)
        for x in range(SIZE):
            px = COLORS["y"] if y >= ground else BG
            sx, sy = (x - ox) // SCALE, (y - oy) // SCALE
            if 0 <= sx < w and 0 <= sy < h and x >= ox and y >= oy:
                c = COLORS[rows[sy][sx]]
                if c[3]:
                    px = c
            raw.extend(px)
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    (ROOT / "icon.png").write_bytes(png)
    print("icon.png 256x256")
    return 0


if __name__ == "__main__":
    sys.exit(main())
