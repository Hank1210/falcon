#!/usr/bin/env python3
"""Synthetisiert alle Soundeffekte (SID-aehnlich: Rechteck, Saege, Rauschen)
nach assets/audio/*.wav. Mono, 16 Bit, 22050 Hz. Nur Standardbibliothek.

Alle Klaenge sind eigene Synthese, nichts stammt aus dem Original.
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

SR = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def square(phase: float, duty: float = 0.5) -> float:
    return 1.0 if (phase % 1.0) < duty else -1.0


def saw(phase: float) -> float:
    return 2.0 * (phase % 1.0) - 1.0


def write(name: str, samples: list[float], gain: float = 0.8) -> None:
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s / peak * gain)) * 32767)) for s in samples)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(f"{name}.wav  {len(samples) / SR:.2f}s")


def sweep(duration, f0, f1, wave_fn, env, vibrato=0.0, vib_hz=7.0):
    """Frequenz laeuft exponentiell von f0 nach f1."""
    n = int(duration * SR)
    out, phase = [], 0.0
    for i in range(n):
        t = i / SR
        u = t / duration
        f = f0 * (f1 / f0) ** u
        f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_hz * t)
        phase += f / SR
        out.append(wave_fn(phase) * env(u))
    return out


def noise(duration, cutoff0, cutoff1, env, seed=1):
    """Rauschen mit gleitendem Tiefpass (Einpol), cutoff als Koeffizient 0..1."""
    rng = random.Random(seed)
    n = int(duration * SR)
    out, y = [], 0.0
    for i in range(n):
        u = i / n
        a = cutoff0 + (cutoff1 - cutoff0) * u
        y += a * (rng.uniform(-1, 1) - y)
        out.append(y * env(u))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def beeps(pattern, wave_fn=square):
    """pattern: Liste (freq oder 0, Dauer s); weiche Huellkurve pro Ton."""
    out, phase = [], 0.0
    for freq, dur in pattern:
        n = int(dur * SR)
        for i in range(n):
            if freq:
                phase += freq / SR
                edge = min(1.0, i / (0.004 * SR), (n - i) / (0.004 * SR))
                out.append(wave_fn(phase) * edge)
            else:
                out.append(0.0)
    return out


def main() -> int:
    decay = lambda p: (lambda u: (1 - u) ** p)

    write("shot", mix(
        sweep(0.18, 2400, 260, lambda p: square(p, 0.5), decay(1.5)),
        [s * 0.25 for s in noise(0.18, 0.9, 0.5, decay(2.0), seed=2)],
    ))
    write("explosion", mix(
        noise(0.6, 0.55, 0.04, decay(1.4), seed=3),
        [s * 0.5 for s in sweep(0.4, 90, 40, lambda p: square(p, 0.5), decay(1.5))],
    ))
    write("explosion_big", mix(
        noise(1.1, 0.45, 0.03, decay(1.2), seed=4),
        [s * 0.6 for s in sweep(0.9, 70, 30, lambda p: square(p, 0.5), decay(1.2))],
    ))
    # Absturz: langgezogenes Heulen des beschaedigten Triebwerks
    howl = sweep(1.6, 760, 55, saw, lambda u: (1 - u) ** 0.6, vibrato=0.07, vib_hz=6.5)
    tail = [0.0] * int(1.2 * SR) + noise(0.4, 0.25, 0.03, decay(1.0), seed=5)
    write("crash", mix(howl, tail))
    # fallende Bombe: abwaerts gleitender Pfeifton
    write("bomb_drop", sweep(1.0, 1700, 650, lambda p: square(p, 0.35), lambda u: 0.6 + 0.4 * (1 - u), vibrato=0.02, vib_hz=12))

    # Triebwerk: exakt periodisch (1 s), daher nahtlos loopbar
    rng = random.Random(6)
    comps = [(f, rng.uniform(0, 2 * math.pi), 1.0 / math.sqrt(f)) for f in range(35, 320, 1)]
    engine = []
    for i in range(SR):
        t = i / SR
        v = sum(a * math.sin(2 * math.pi * f * t + ph) for f, ph, a in comps)
        v += 3.0 * saw(55 * t)
        engine.append(v)
    write("engine", engine, gain=0.7)

    alarm_pat = [(1000, 0.12), (0, 0.13), (1400, 0.12), (0, 0.13)]
    write("alarm", beeps(alarm_pat), gain=0.5)
    write("refuel", beeps([x for i in range(5) for x in ((300 + i * 70, 0.08), (0, 0.02))]), gain=0.45)
    write("standby", beeps([(880, 0.1), (0, 0.05), (880, 0.1), (0, 0.05), (1320, 0.18)]), gain=0.6)
    write("extra", beeps([(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.25)], lambda p: square(p, 0.25)), gain=0.6)
    write("beep", sweep(0.15, 440, 440, lambda p: square(p, 0.5), decay(0.8)), gain=0.6)

    # Titelfanfare (eigene Komposition): Pulsbreite schwingt, kurzer Nachklang
    note = {"C4": 261.63, "D4": 293.66, "E4": 329.63, "G4": 392.0, "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99}
    melody = [("G4", .5), ("G4", .25), ("G4", .25), ("C5", 1.0), ("E5", .5), ("D5", .25), ("C5", .25), ("G5", 1.75)]
    beat = 0.45
    out, phase, low = [], 0.0, 0.0
    for name, beats in melody:
        n = int(beats * beat * SR)
        f = note[name]
        for i in range(n):
            t = i / SR
            phase += f / SR
            low += f / 2 / SR
            duty = 0.4 + 0.1 * math.sin(2 * math.pi * 5 * t)
            env = min(1.0, i / (0.01 * SR), (n - i) / (0.06 * SR))
            out.append((square(phase, duty) + 0.4 * square(low, 0.5)) * env)
    write("fanfare", out, gain=0.6)
    return 0


if __name__ == "__main__":
    sys.exit(main())
