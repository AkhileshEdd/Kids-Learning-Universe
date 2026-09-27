#!/usr/bin/env python3
"""Generates the app's sound effects and background music.

All audio in Kids Learning Universe is synthesized by this script, so there are
no third-party audio licenses to worry about. Re-run it after tweaking a sound:

    python3 tool/generate_sounds.py

Requires numpy.
"""
import os
import wave

import numpy as np

SR = 22050
ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env_adsr(n, a=0.005, d=0.05, s=0.6, r=0.1):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, n - a_n - d_n - r_n)
    e = np.concatenate([
        np.linspace(0, 1, a_n, endpoint=False),
        np.linspace(1, s, d_n, endpoint=False),
        np.full(s_n, s),
        np.linspace(s, 0, r_n),
    ])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


def bell(freq, dur, decay=6.0, bright=1.0):
    t = t_axis(dur)
    partials = [(1, 1.0), (2.0, 0.45 * bright), (3.01, 0.22 * bright), (4.2, 0.1 * bright)]
    sig = sum(a * np.sin(2 * np.pi * freq * m * t) * np.exp(-decay * m * t) for m, a in partials)
    attack = np.minimum(1, t / 0.003)
    return sig * attack


def marimba(freq, dur):
    t = t_axis(dur)
    sig = np.sin(2 * np.pi * freq * t) * np.exp(-7 * t)
    sig += 0.25 * np.sin(2 * np.pi * freq * 4 * t) * np.exp(-20 * t)
    sig += 0.1 * np.sin(2 * np.pi * freq * 10 * t) * np.exp(-40 * t)
    return sig * np.minimum(1, t / 0.002)


def pad(freqs, dur):
    t = t_axis(dur)
    sig = np.zeros_like(t)
    for f in freqs:
        for detune in (-0.8, 0.8):
            sig += np.sin(2 * np.pi * (f + detune) * t)
            sig += 0.2 * np.sin(2 * np.pi * 2 * (f + detune) * t)
    return sig * env_adsr(len(t), a=0.4, d=0.3, s=0.8, r=0.6) / (len(freqs) * 2)


def note(name):
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    base = names[name[0]]
    octave = int(name[-1])
    semis = base + (1 if "#" in name else 0) + (octave - 4) * 12
    return 440.0 * 2 ** (semis / 12)


def place(buf, sig, start):
    i = int(start * SR)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[: end - i]


def normalize(sig, peak=0.8):
    m = np.max(np.abs(sig))
    return sig if m == 0 else sig / m * peak


def fade_out(sig, dur=0.02):
    n = int(dur * SR)
    sig[-n:] *= np.linspace(1, 0, n)
    return sig


def save(path, sig, peak=0.8):
    sig = normalize(sig, peak)
    data = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with wave.open(full, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"wrote {path} ({len(data) / SR:.2f}s)")


def lowpass(sig, alpha):
    out = np.zeros_like(sig)
    acc = 0.0
    for i, x in enumerate(sig):
        acc += alpha * (x - acc)
        out[i] = acc
    return out


rng = np.random.default_rng(7)

# --- tap: a soft wooden "tock" ---
t = t_axis(0.09)
freq = 900 * np.exp(-8 * t)
tap = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-45 * t)
save("sfx/tap.wav", fade_out(tap), 0.55)

# --- pop: bubble pop (rising blip) ---
t = t_axis(0.12)
freq = 350 + 1400 * (t / 0.12) ** 0.6
pop = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-28 * t)
pop[: int(0.004 * SR)] += rng.normal(0, 0.4, int(0.004 * SR))
save("sfx/pop.wav", fade_out(pop), 0.7)

# --- correct: bright two-note chime ---
buf = np.zeros(int(SR * 0.9))
place(buf, bell(note("E6"), 0.6, 5), 0.0)
place(buf, bell(note("C7"), 0.8, 4), 0.11)
save("sfx/correct.wav", fade_out(buf), 0.75)

# --- wrong: gentle, friendly "boop-boop" (never scary) ---
t = t_axis(0.18)
b1 = np.sin(2 * np.pi * np.cumsum(330 - 60 * t / 0.18) / SR) * env_adsr(len(t), 0.01, 0.05, 0.7, 0.08)
buf = np.zeros(int(SR * 0.42))
place(buf, b1, 0)
place(buf, np.sin(2 * np.pi * np.cumsum(250 - 60 * t / 0.18) / SR) * env_adsr(len(t), 0.01, 0.05, 0.7, 0.08), 0.2)
save("sfx/wrong.wav", fade_out(lowpass(buf, 0.35)), 0.45)

# --- star: sparkly ascending arpeggio ---
buf = np.zeros(int(SR * 1.0))
for i, n in enumerate(["C6", "E6", "G6", "C7", "E7"]):
    place(buf, bell(note(n), 0.5, 7, 0.6) * (0.6 + 0.1 * i), i * 0.055)
save("sfx/star.wav", fade_out(buf), 0.6)

# --- win: happy fanfare ---
buf = np.zeros(int(SR * 1.8))
for i, n in enumerate(["C5", "E5", "G5"]):
    place(buf, marimba(note(n), 0.35) + 0.5 * bell(note(n) * 2, 0.35, 8), i * 0.13)
for n in ["C5", "E5", "G5", "C6"]:
    place(buf, marimba(note(n), 1.2) + 0.4 * bell(note(n) * 2, 1.2, 3), 0.42)
save("sfx/win.wav", fade_out(buf), 0.75)

# --- flip: card swish ---
t = t_axis(0.16)
noise = rng.normal(0, 1, len(t))
flip = lowpass(noise, 0.25) * np.sin(np.pi * t / 0.16) ** 2
save("sfx/flip.wav", fade_out(flip), 0.4)

# --- whoosh: rocket / page transition ---
t = t_axis(0.45)
noise = rng.normal(0, 1, len(t))
whoosh = np.zeros_like(noise)
acc = 0.0
for i, x in enumerate(noise):
    alpha = 0.03 + 0.25 * np.sin(np.pi * i / len(noise))
    acc += alpha * (x - acc)
    whoosh[i] = acc
whoosh *= np.sin(np.pi * t / 0.45) ** 1.5
save("sfx/whoosh.wav", fade_out(whoosh), 0.45)

# --- sticker: magic twinkle (descending pentatonic) ---
buf = np.zeros(int(SR * 1.3))
for i, n in enumerate(["A7", "E7", "D7", "C7", "A6", "G6", "E6"]):
    place(buf, bell(note(n), 0.6, 6, 0.4) * (1 - i * 0.08), i * 0.06)
save("sfx/sticker.wav", fade_out(buf), 0.55)

# --- page turn: soft paper slide ---
t = t_axis(0.25)
noise = rng.normal(0, 1, len(t))
page = lowpass(noise, 0.12) * np.exp(-10 * t) * np.minimum(1, t / 0.02)
save("sfx/page.wav", fade_out(page), 0.35)

# --- background music: calm marimba loop over soft pads ---
bpm = 92
beat = 60 / bpm
bars = 8
loop_len = bars * 4 * beat
buf = np.zeros(int(SR * (loop_len + 3)))
chords = [
    ["C4", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"],
    ["C4", "E4", "G4"], ["A3", "C4", "E4"], ["F3", "A3", "C4"], ["G3", "B3", "D4"],
]
for bar, ch in enumerate(chords):
    place(buf, pad([note(n) for n in ch], 4 * beat + 0.6) * 0.35, bar * 4 * beat)
    place(buf, marimba(note(ch[0]) / 2, 1.5) * 0.35, bar * 4 * beat)
    place(buf, marimba(note(ch[0]) / 2, 1.5) * 0.25, bar * 4 * beat + 2 * beat)
melody = [
    ("E5", 0), ("G5", 1), ("A5", 2), ("G5", 3),
    ("E5", 4), ("C5", 5.5), ("D5", 6), ("E5", 7),
    ("C5", 8), ("D5", 9), ("E5", 10), ("G5", 11),
    ("D5", 12), ("B4", 13.5), ("D5", 14.5),
    ("E5", 16), ("G5", 17), ("A5", 18), ("C6", 19),
    ("A5", 20), ("G5", 21.5), ("E5", 22), ("G5", 23),
    ("A5", 24), ("G5", 25), ("E5", 26), ("D5", 27),
    ("C5", 28), ("D5", 29), ("E5", 30), ("D5", 31),
]
for n, b in melody:
    place(buf, marimba(note(n), 1.2) * 0.55, b * beat)
    place(buf, bell(note(n) * 2, 0.8, 5, 0.3) * 0.08, b * beat)
# Wrap the tail around so the loop is seamless.
n_loop = int(SR * loop_len)
music = buf[:n_loop].copy()
music[: len(buf) - n_loop] += buf[n_loop:]
save("music/space_lullaby.wav", music, 0.5)
