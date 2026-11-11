"""Bakes every sound of Donut Cove offline: three music loops, the ambience and the effects.

Original audio, synthesised with numpy (no samples, no chiptune voices): plucked strings, marimba, soft
percussion, a reed organ and low drums. Loops are rendered with their tails folded back onto the start, so they repeat
without a seam, and encoded to OGG Vorbis with ffmpeg; short effects are WAV.

Run from the project root:  C:\\Python314\\python.exe -E -P tools/bake_audio.py
Output: assets/audio/music/*.ogg, assets/audio/sfx/*.wav
"""
from __future__ import annotations

import math
import subprocess
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
ROOT = Path(__file__).resolve().parent.parent
MUSIC = ROOT / "assets" / "audio" / "music"
SFX = ROOT / "assets" / "audio" / "sfx"
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ helpers
def hz(midi: float) -> float:
    return 440.0 * 2.0 ** ((midi - 69.0) / 12.0)


def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(SR * seconds)) / SR


def env_ad(n: int, attack: float, decay: float) -> np.ndarray:
    t = np.arange(n) / SR
    return np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-t * decay)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    b, a = signal.butter(2, min(cutoff, SR * 0.45) / (SR * 0.5), "low")
    return signal.lfilter(b, a, x)


def highpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    b, a = signal.butter(2, cutoff / (SR * 0.5), "high")
    return signal.lfilter(b, a, x)


def bandpass(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    b, a = signal.butter(2, [lo / (SR * 0.5), hi / (SR * 0.5)], "band")
    return signal.lfilter(b, a, x)


def noise(n: int) -> np.ndarray:
    return rng.uniform(-1.0, 1.0, n)


# ------------------------------------------------------------------ voices
def pluck(freq: float, seconds: float, bright: float = 1.0) -> np.ndarray:
    """A nylon string: harmonics that die faster the higher they are, with a soft finger noise."""
    t = t_axis(seconds)
    out = np.zeros_like(t)
    for n in range(1, 9):
        out += np.sin(2 * np.pi * freq * n * t) * (1.0 / n ** 1.2) * np.exp(-t * (2.2 + 1.1 * n / bright))
    out += lowpass(noise(len(t)), 3000) * np.exp(-t * 90) * 0.25
    return out * np.minimum(t / 0.004, 1.0)


def marimba(freq: float, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    out = np.sin(2 * np.pi * freq * t) * np.exp(-t * 5.5)
    out += 0.35 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t * 16)
    out += 0.12 * np.sin(2 * np.pi * freq * 9.2 * t) * np.exp(-t * 40)
    return out * np.minimum(t / 0.003, 1.0)


def bass(freq: float, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    out = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t * 6)
    return out * np.minimum(t / 0.008, 1.0) * np.exp(-t * 3.0)


def reed(freq: float, seconds: float) -> np.ndarray:
    """A small reed organ: detuned odd rich harmonics with a slow breath."""
    t = t_axis(seconds)
    out = np.zeros_like(t)
    for detune in (-0.004, 0.0, 0.005):
        for n in range(1, 10):
            out += np.sin(2 * np.pi * freq * (1 + detune) * n * t) / (n ** 1.4)
    env = np.minimum(t / 0.04, 1.0) * np.minimum((seconds - t) / 0.06, 1.0).clip(0, 1)
    return lowpass(out, 2600) * env * (1.0 + 0.06 * np.sin(2 * np.pi * 5.2 * t)) * 0.35


def whistle(freq: float, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    vib = 1.0 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(t / 0.15, 1.0)
    out = np.sin(2 * np.pi * freq * vib * t) + 0.12 * np.sin(2 * np.pi * freq * 2 * vib * t)
    out += bandpass(noise(len(t)), freq * 0.8, freq * 1.6) * 0.08
    return out * np.minimum(t / 0.03, 1.0) * np.minimum((seconds - t) / 0.05, 1.0).clip(0, 1)


def strings(freq: float, seconds: float) -> np.ndarray:
    t = t_axis(seconds)
    out = np.zeros_like(t)
    for detune in (-0.006, 0.0, 0.007):
        phase = (freq * (1 + detune) * t) % 1.0
        out += 2.0 * phase - 1.0
    return lowpass(out, 1800) * np.minimum(t / 0.05, 1.0) * np.minimum((seconds - t) / 0.08, 1.0).clip(0, 1) * 0.3


def kick(seconds: float = 0.3, top: float = 110.0, low: float = 46.0) -> np.ndarray:
    t = t_axis(seconds)
    f = low + (top - low) * np.exp(-t * 28)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11)


def shaker(seconds: float = 0.07) -> np.ndarray:
    n = int(SR * seconds)
    return highpass(noise(n), 5200) * env_ad(n, 0.004, 60)


def rim(seconds: float = 0.1) -> np.ndarray:
    n = int(SR * seconds)
    t = np.arange(n) / SR
    return (bandpass(noise(n), 1500, 4200) * 0.7 + np.sin(2 * np.pi * 820 * t) * 0.5) * np.exp(-t * 45)


def timpani(freq: float, seconds: float = 0.9) -> np.ndarray:
    t = t_axis(seconds)
    f = freq * (1.0 + 0.25 * np.exp(-t * 30))
    out = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.4 * np.sin(2 * np.pi * np.cumsum(f * 1.5) / SR) * np.exp(-t * 8)
    return (out + lowpass(noise(len(t)), 900) * np.exp(-t * 40) * 0.5) * np.exp(-t * 4.5)


# ------------------------------------------------------------------ mixing
class Track:
    def __init__(self, seconds: float):
        self.n = int(SR * seconds)
        self.buf = np.zeros((self.n + SR * 4, 2))

    def add(self, at: float, mono: np.ndarray, gain: float = 1.0, pan: float = 0.0) -> None:
        start = int(at * SR)
        if start < 0:
            return
        end = min(start + len(mono), len(self.buf))
        part = mono[: end - start] * gain
        self.buf[start:end, 0] += part * math.cos((pan + 1) * math.pi / 4)
        self.buf[start:end, 1] += part * math.sin((pan + 1) * math.pi / 4)

    def render(self, reverb: float = 0.18, peak: float = 0.82) -> np.ndarray:
        dry = self.buf
        if reverb > 0:
            length = int(SR * 1.3)
            tail = noise(length) * np.exp(-np.arange(length) / SR * 5.0)
            wet = np.stack([signal.fftconvolve(dry[:, c], tail, "full")[: len(dry)] for c in range(2)], axis=1)
            wet /= max(np.abs(wet).max(), 1e-6)
            dry = dry + wet * reverb * np.abs(dry).max()
        loop = dry[: self.n].copy()
        over = dry[self.n :]
        loop[: len(over)] += over[: self.n]  # fold the tail onto the start: a seamless loop
        loop /= max(np.abs(loop).max(), 1e-6)
        return np.tanh(loop * 1.15) * peak


CHORDS = {
    "C": (48, [60, 64, 67, 72]), "G": (43, [59, 62, 67, 71]), "Am": (45, [57, 60, 64, 69]), "F": (41, [57, 60, 65, 69]),
    "Dm": (38, [57, 62, 65, 69]), "Em": (40, [59, 64, 67, 71]), "A": (45, [57, 61, 64, 69]), "Bb": (46, [58, 62, 65, 70]),
    "Gm": (43, [58, 62, 67, 70]),
}


def island() -> np.ndarray:
    """Breezy island tune: ukulele strum, marimba melody, light percussion. 24 bars at 100 bpm, 57.6 s."""
    beat = 60.0 / 100.0
    bars = ["C", "G", "Am", "F", "C", "G", "F", "G",
            "F", "C", "Dm", "G", "Em", "Am", "F", "G",
            "C", "G", "Am", "F", "C", "Em", "F", "G"]
    tr = Track(len(bars) * 4 * beat)
    melody_a = [(0, 76, 1), (1, 79, 0.5), (1.5, 81, 0.5), (2, 79, 1), (3, 76, 1),
                (4, 74, 1), (5, 76, 0.5), (5.5, 79, 0.5), (6, 74, 2),
                (8, 72, 1), (9, 76, 0.5), (9.5, 79, 0.5), (10, 81, 1), (11, 84, 1),
                (12, 81, 1), (13, 79, 0.5), (13.5, 76, 0.5), (14, 77, 1.5), (15.5, 76, 0.5),
                (16, 76, 1), (17, 79, 1), (18, 84, 1), (19, 83, 0.5), (19.5, 79, 0.5),
                (20, 77, 1), (21, 81, 1), (22, 79, 1.5), (23.5, 77, 0.5),
                (24, 76, 1), (25, 72, 0.5), (25.5, 74, 0.5), (26, 76, 1), (27, 79, 1),
                (28, 74, 1.5), (29.5, 71, 0.5), (30, 74, 2)]
    melody_b = [(0, 81, 1), (1, 84, 1), (2, 81, 0.5), (2.5, 79, 0.5), (3, 77, 1),
                (4, 76, 1), (5, 79, 1), (6, 84, 1.5), (7.5, 79, 0.5),
                (8, 77, 1), (9, 81, 0.5), (9.5, 77, 0.5), (10, 74, 1), (11, 77, 1),
                (12, 79, 1), (13, 83, 0.5), (13.5, 79, 0.5), (14, 74, 2),
                (16, 79, 1), (17, 76, 0.5), (17.5, 79, 0.5), (18, 83, 1), (19, 79, 1),
                (20, 76, 1), (21, 72, 0.5), (21.5, 76, 0.5), (22, 81, 2),
                (24, 81, 1), (25, 77, 0.5), (25.5, 81, 0.5), (26, 84, 1), (27, 81, 1),
                (28, 79, 1), (29, 83, 0.5), (29.5, 86, 0.5), (30, 79, 2)]
    for b, name in enumerate(bars):
        root, tones = CHORDS[name]
        t0 = b * 4 * beat
        for e in range(8):  # strum: down on the beats, lighter up strokes
            at = t0 + e * beat * 0.5
            down = e % 2 == 0
            if e in (1,) and b % 2 == 0:
                continue
            order = tones if down else tones[::-1]
            for i, tone in enumerate(order):
                tr.add(at + i * 0.011, pluck(hz(tone + 12), 0.9, 1.3), 0.11 if down else 0.07, -0.35)
        tr.add(t0, bass(hz(root), 1.0), 0.5, 0.0)
        tr.add(t0 + 2 * beat, bass(hz(root + 7), 0.8), 0.36, 0.0)
        tr.add(t0 + 3.5 * beat, bass(hz(root), 0.4), 0.28, 0.0)
        for e in range(8):
            tr.add(t0 + e * beat * 0.5, shaker(), 0.12 if e % 2 == 0 else 0.07, 0.4)
        tr.add(t0, kick(), 0.42, 0.0)
        tr.add(t0 + 2 * beat, kick(), 0.3, 0.0)
        tr.add(t0 + beat, rim(), 0.16, 0.25)
        tr.add(t0 + 3 * beat, rim(), 0.16, 0.25)
    for section, notes in ((0, melody_a), (8, melody_b), (16, melody_a)):
        for at, note, length in notes:
            tr.add((section * 4 + at) * beat, marimba(hz(note - 12 if section == 16 and at >= 16 else note), length * beat + 0.6),
                   0.3, 0.3)
            if section == 16:
                tr.add((section * 4 + at) * beat, marimba(hz(note - 8), length * beat + 0.5), 0.1, 0.5)
    return tr.render(0.16)


def sea() -> np.ndarray:
    """Bolder sea shanty: 6/8 stomp, reed organ, plucked bass and a whistle tune. 36 bars, 47 s."""
    beat = 60.0 / 92.0  # dotted quarter
    eighth = beat / 3.0
    bars = ["Dm", "C", "Dm", "A", "Dm", "C", "F", "A", "F", "C", "Dm", "A"] * 3
    tr = Track(len(bars) * 2 * beat)
    tune = [(0, 74, 2), (2, 77, 1), (3, 76, 2), (5, 72, 1), (6, 74, 2), (8, 69, 1), (9, 73, 3),
            (12, 74, 2), (14, 77, 1), (15, 79, 2), (17, 76, 1), (18, 77, 2), (20, 81, 1), (21, 76, 3),
            (24, 81, 2), (26, 77, 1), (27, 79, 2), (29, 76, 1), (30, 77, 2), (32, 74, 1), (33, 73, 3)]
    for b, name in enumerate(bars):
        root, tones = CHORDS[name]
        t0 = b * 2 * beat
        tr.add(t0, kick(0.35, 120, 44), 0.55, 0.0)
        tr.add(t0 + beat, rim(0.12), 0.26, 0.2)
        tr.add(t0 + beat + 2 * eighth, kick(0.2, 100, 50), 0.22, 0.0)
        tr.add(t0, bass(hz(root), 0.7), 0.5, 0.0)
        tr.add(t0 + beat, bass(hz(root + 7), 0.6), 0.36, 0.0)
        for i, tone in enumerate(tones[:3]):
            tr.add(t0 + 0.02, reed(hz(tone), beat * 0.9), 0.16, -0.3 + i * 0.1)
            tr.add(t0 + beat, reed(hz(tone), beat * 0.6), 0.13, -0.3 + i * 0.1)
        for e in range(6):
            tr.add(t0 + e * eighth, pluck(hz(tones[e % 4] + 12), 0.5, 1.5), 0.07, 0.45)
    for rep in range(3):
        for at, note, length in tune:
            if rep == 0 and at >= 24:
                continue
            voice = whistle if rep != 1 else reed
            tr.add((rep * 24 + at) * eighth * 1.0 + rep * 0, voice(hz(note + (0 if rep != 1 else -12)), length * eighth * 0.95), 0.3 if rep != 1 else 0.4, 0.1)
    return tr.render(0.2)


def kraken() -> np.ndarray:
    """Tense Kraken variant: low drums, a string ostinato and stabs in D minor. 26 bars at 130 bpm, 48 s."""
    beat = 60.0 / 130.0
    bars = ["Dm", "Dm", "Bb", "A", "Dm", "Gm", "Bb", "A", "Dm", "Dm", "Gm", "A", "Dm"] * 2
    tr = Track(len(bars) * 4 * beat)
    for b, name in enumerate(bars):
        root, tones = CHORDS[name]
        t0 = b * 4 * beat
        for e, pos in enumerate((0, 0.75, 1.5, 2, 2.75, 3.5)):
            tr.add(t0 + pos * beat, timpani(hz(root - 12 if e % 3 == 0 else root - 5), 0.7), 0.5 if e % 3 == 0 else 0.32, 0.0)
        for e in range(8):
            tone = tones[(e * 3) % 4]
            tr.add(t0 + e * beat * 0.5, strings(hz(tone), beat * 0.42), 0.34, -0.3 if e % 2 else 0.3)
        tr.add(t0, strings(hz(root), 4 * beat), 0.3, 0.0)
        if b % 2 == 1:
            for tone in tones:
                tr.add(t0 + 3 * beat, reed(hz(tone - 12), beat * 0.8), 0.22, 0.0)
        for e in range(16):
            if e % 4 != 0:
                tr.add(t0 + e * beat * 0.25, shaker(0.04), 0.06, 0.5)
    return tr.render(0.22)


def ambience() -> np.ndarray:
    """Waves washing in and out and a few gulls. 32 s."""
    seconds = 32.0
    tr = Track(seconds)
    t = t_axis(seconds)
    wash = lowpass(noise(len(t)), 900) * (0.55 + 0.45 * np.sin(2 * np.pi * t / 8.0 - 1.2)) ** 2
    hiss = bandpass(noise(len(t)), 1500, 5000) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 8.0 - 0.4)) ** 4 * 0.5
    tr.add(0.0, wash, 0.7, -0.2)
    tr.add(0.0, hiss, 0.35, 0.3)
    for at, pitch in ((3.0, 1900), (3.5, 2100), (14.2, 1750), (14.6, 1950), (15.0, 1700), (25.5, 2050)):
        g = t_axis(0.32)
        f = pitch * (1.0 + 0.25 * np.exp(-g * 9) - 0.18 * g)
        call = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * g / 0.32) ** 2
        tr.add(at, call, 0.12, 0.6 if at < 10 else -0.5)
    return tr.render(0.25, 0.6)


# ------------------------------------------------------------------ effects
def fx(seconds: float) -> np.ndarray:
    return np.zeros(int(SR * seconds))


def put(buf: np.ndarray, at: float, part: np.ndarray, gain: float = 1.0) -> None:
    start = int(at * SR)
    end = min(start + len(part), len(buf))
    buf[start:end] += part[: end - start] * gain


def pop(freq: float, seconds: float = 0.16) -> np.ndarray:
    t = t_axis(seconds)
    f = freq * (1.0 + 0.9 * np.exp(-t * 45))
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 26)


def chime(freq: float, seconds: float = 0.5) -> np.ndarray:
    t = t_axis(seconds)
    out = np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * 9) + 0.25 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * 18)
    return out * np.exp(-t * 8) * np.minimum(t / 0.002, 1.0)


def effects() -> dict[str, np.ndarray]:
    out: dict[str, np.ndarray] = {}
    out["pickup"] = pop(520) + 0.35 * marimba(784, 0.16)
    out["pickup_soft"] = (pop(440) + 0.25 * marimba(660, 0.16)) * 0.6
    out["serve"] = pop(360, 0.14) + 0.3 * marimba(523, 0.14)
    out["donut_land"] = lowpass(noise(int(SR * 0.12)), 700) * env_ad(int(SR * 0.12), 0.002, 40) + 0.6 * pop(180, 0.12)
    out["coin"] = chime(1568, 0.45)
    out["coin"][: int(SR * 0.4)] += 0.6 * chime(2093, 0.4)
    out["coin_drop"] = chime(1175, 0.25) * 0.8 + np.pad(chime(1397, 0.2) * 0.4, (int(SR * 0.04), int(SR * 0.01)))
    out["pad_tick"] = pop(700, 0.07) * 0.8
    out["reject"] = (np.sign(np.sin(2 * np.pi * 150 * t_axis(0.22))) * 0.25 + np.sin(2 * np.pi * 110 * t_axis(0.22))) * env_ad(int(SR * 0.22), 0.003, 14)
    out["reject"] = lowpass(out["reject"], 900)
    out["click_empty"] = rim(0.06) * 0.8
    out["oven_ding"] = chime(1319, 0.7)
    out["ui_hover"] = pop(900, 0.05) * 0.5
    out["ui_click"] = pop(600, 0.09) + 0.4 * marimba(880, 0.09)
    buf = fx(1.3)
    for i, note in enumerate((72, 76, 79, 84)):
        put(buf, i * 0.09, marimba(hz(note), 0.7), 0.6)
        put(buf, i * 0.09, chime(hz(note + 12), 0.6), 0.25)
    out["unlock"] = buf
    buf = fx(2.2)
    for i, note in enumerate((67, 72, 76, 79, 84, 88)):
        put(buf, i * 0.12, marimba(hz(note), 1.0), 0.5)
        put(buf, i * 0.12, reed(hz(note - 12), 0.5), 0.5)
    for note in (72, 76, 79, 84):
        put(buf, 0.78, reed(hz(note), 1.2), 0.45)
        put(buf, 0.78, chime(hz(note + 12), 1.2), 0.2)
    out["fanfare"] = buf
    buf = fx(1.2)
    for i, note in enumerate((79, 84, 88, 91)):
        put(buf, i * 0.1, chime(hz(note), 0.8), 0.5)
    out["rare_fanfare"] = buf
    for name, notes in (("pirate_happy", (62, 67)), ("pirate_grumpy", (55, 50))):
        buf = fx(0.45)
        for i, note in enumerate(notes):
            g = t_axis(0.2)
            voice = lowpass(np.sign(np.sin(2 * np.pi * hz(note - 12) * g * (1 + 0.04 * np.sin(2 * np.pi * 9 * g)))), 900) * np.sin(np.pi * g / 0.2)
            put(buf, i * 0.16, voice, 0.5)
        out[name] = buf
    t = t_axis(0.9)
    boom = np.sin(2 * np.pi * np.cumsum(50 + 120 * np.exp(-t * 18)) / SR) * np.exp(-t * 5)
    out["cannon"] = boom + lowpass(noise(len(t)), 1400) * np.exp(-t * 9) * 0.9
    t = t_axis(0.7)
    out["splash"] = bandpass(noise(len(t)), 500, 5200) * (np.exp(-t * 7) * np.minimum(t / 0.01, 1.0)) + lowpass(noise(len(t)), 400) * np.exp(-t * 12) * 0.6
    t = t_axis(0.4)
    out["impact"] = lowpass(noise(len(t)), 2400) * np.exp(-t * 16) + np.sin(2 * np.pi * np.cumsum(90 + 200 * np.exp(-t * 30)) / SR) * np.exp(-t * 12)
    t = t_axis(0.6)
    out["hull_hit"] = lowpass(noise(len(t)), 600) * np.exp(-t * 8) * 1.2 + np.sin(2 * np.pi * 70 * t) * np.exp(-t * 7) + bandpass(noise(len(t)), 800, 2500) * np.exp(-t * 25) * 0.6
    out["reload"] = rim(0.08) * 0.6 + np.pad(pop(300, 0.08) * 0.5, (int(SR * 0.03), 0))[: int(SR * 0.08)]
    t = t_axis(0.5)
    out["shark_warn"] = np.sin(2 * np.pi * np.cumsum(400 + 500 * t) / SR) * np.sin(np.pi * t / 0.5) ** 2 * 0.7
    t = t_axis(0.35)
    out["shark_bite"] = bandpass(noise(len(t)), 900, 3800) * np.exp(-t * 22) + pop(140, 0.35)
    t = t_axis(1.1)
    out["tentacle_rise"] = lowpass(noise(len(t)), 700) * np.sin(np.pi * t / 1.1) ** 2 + bandpass(noise(len(t)), 1800, 5200) * np.sin(np.pi * t / 1.1) ** 4 * 0.4
    t = t_axis(1.2)
    out["tentacle_rumble"] = (np.sin(2 * np.pi * np.cumsum(38 + 40 * t) / SR) + lowpass(noise(len(t)), 160) * 2.0) * np.minimum(t / 1.0, 1.0) ** 2 * np.minimum((1.2 - t) / 0.05, 1.0).clip(0, 1)
    t = t_axis(0.8)
    out["tentacle_slam"] = np.sin(2 * np.pi * np.cumsum(45 + 110 * np.exp(-t * 20)) / SR) * np.exp(-t * 6) * 1.2 + bandpass(noise(len(t)), 400, 4200) * np.exp(-t * 8)
    buf = fx(0.9)
    put(buf, 0.0, out["splash"], 0.8)
    for i, note in enumerate((79, 76, 72)):
        put(buf, 0.05 + i * 0.08, marimba(hz(note), 0.4), 0.4)
    out["enemy_down"] = buf
    t = t_axis(1.8)
    roar = lowpass(np.sign(np.sin(2 * np.pi * np.cumsum(70 - 22 * t + 6 * np.sin(2 * np.pi * 11 * t)) / SR)), 420)
    out["kraken_roar"] = (roar + lowpass(noise(len(t)), 300) * 1.4) * np.sin(np.pi * t / 1.8) ** 1.5
    t = t_axis(1.2)
    out["ship_horn"] = lowpass(np.sign(np.sin(2 * np.pi * 147 * t)) + np.sign(np.sin(2 * np.pi * 220 * t)), 800) * np.minimum(t / 0.08, 1.0) * np.minimum((1.2 - t) / 0.2, 1.0).clip(0, 1) * 0.5
    buf = fx(0.6)
    put(buf, 0.0, pop(300, 0.2), 0.8)
    put(buf, 0.12, marimba(hz(72), 0.3), 0.5)
    put(buf, 0.22, marimba(hz(79), 0.3), 0.5)
    out["board"] = buf
    buf = fx(1.0)
    t = t_axis(0.3)
    put(buf, 0.0, bandpass(noise(len(t)), 1200, 5000) * np.minimum(t / 0.25, 1.0) ** 3, 0.3)
    t = t_axis(0.6)
    put(buf, 0.3, lowpass(noise(len(t)), 3000) * np.exp(-t * 7) + bandpass(noise(len(t)), 3000, 9000) * np.exp(-t * 4) * 0.5, 0.8)
    out["firework"] = buf
    buf = fx(1.4)
    for i, note in enumerate((67, 64, 60, 55)):
        put(buf, i * 0.22, reed(hz(note), 0.35), 0.6)
    out["limp_home"] = buf
    return out


def write_sfx(name: str, mono: np.ndarray, peak: float = 0.85) -> None:
    mono = np.asarray(mono, dtype=np.float64)
    fade = min(int(SR * 0.01), len(mono) // 4)
    mono[-fade:] *= np.linspace(1.0, 0.0, fade)
    mono = mono / max(np.abs(mono).max(), 1e-6) * peak
    sf.write(str(SFX / f"{name}.wav"), mono, SR, subtype="PCM_16")


def main() -> None:
    MUSIC.mkdir(parents=True, exist_ok=True)
    SFX.mkdir(parents=True, exist_ok=True)
    for name, build in (("island", island), ("sea", sea), ("kraken", kraken), ("ambience", ambience)):
        data = build()
        temp = MUSIC / f"_{name}.wav"
        sf.write(str(temp), data, SR, subtype="PCM_16")
        # libsndfile's Vorbis writer crashes on long buffers here, so ffmpeg encodes the loop.
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(temp), "-c:a", "libvorbis", "-q:a", "5",
                        str(MUSIC / f"{name}.ogg")], check=True)
        temp.unlink()
        print(f"music {name}: {len(data) / SR:.1f} s")
    for name, mono in effects().items():
        write_sfx(name, mono)
    print("effects:", len(list(SFX.glob("*.wav"))))


if __name__ == "__main__":
    main()
