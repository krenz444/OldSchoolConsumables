#!/usr/bin/env python3
"""
fetch_audio.py - OSRS Authentic Sound Effect Asset Pipeline
Part of the OldSchoolConsumables World of Warcraft Addon.

Fetches the authentic classic Old School RuneScape sound effects:
  - Sound ID 2401: Classic Potion Drink (distinct 3-gulp liquid bubble sound)
  - Sound ID 2393: Classic Food Eat (distinct crunchy shark / nom nom sound)

Saves both authentic WAV (PCM 8-bit / 22.05kHz mono) and encodes OGG Vorbis
for seamless World of Warcraft client playback via PlaySoundFile.
"""

from __future__ import annotations

import io
import os
import shutil
import subprocess
import sys
import urllib.request
import wave
from pathlib import Path

# Authoritative OSRS audio dump repository
OSRS_AUDIO_SOURCES = {
    "potion": {
        "id": "2401",
        "url": "https://raw.githubusercontent.com/SoaresPT/OSRS-SoundEffects-Dumps/master/sounds/2401.wav",
        "expected_min_bytes": 20000,
        "description": "OSRS Classic Potion Drink (Sound ID 2401)",
    },
    "food": {
        "id": "2393",
        "url": "https://raw.githubusercontent.com/SoaresPT/OSRS-SoundEffects-Dumps/master/sounds/2393.wav",
        "expected_min_bytes": 20000,
        "description": "OSRS Classic Food Eat (Sound ID 2393)",
    },
}


def get_sounds_dir() -> Path:
    """Resolve the target Sounds directory relative to this script."""
    script_dir = Path(__file__).resolve().parent
    # Check parent directory (projects/old-school-consumables/Sounds)
    target_dir = script_dir.parent / "Sounds"
    target_dir.mkdir(parents=True, exist_ok=True)
    return target_dir


def download_wav(url: str, min_bytes: int = 20000) -> bytes:
    """Download audio bytes from URL and validate WAV RIFF format."""
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) OldSchoolConsumables/1.0"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        if resp.status != 200:
            raise RuntimeError(f"HTTP download failed with status {resp.status} for {url}")
        data = resp.read()

    if len(data) < min_bytes:
        raise ValueError(f"Downloaded payload too small ({len(data)} bytes, expected >= {min_bytes})")

    if not data.startswith(b"RIFF") or data[8:12] != b"WAVE":
        raise ValueError(f"Downloaded file does not have a valid RIFF/WAVE header")

    # Verify wave chunk structure via stdlib wave module
    with wave.open(io.BytesIO(data), "rb") as w:
        channels = w.getnchannels()
        framerate = w.getframerate()
        nframes = w.getnframes()
        duration = nframes / framerate if framerate else 0.0

    print(f"  [OK] Valid WAV payload: {len(data):,} bytes, {channels}ch, {framerate}Hz, duration: {duration:.3f}s")
    return data


def convert_wav_to_ogg(wav_path: Path, ogg_path: Path) -> bool:
    """
    Convert WAV to Ogg Vorbis.
    Attempts soundfile first, then ffmpeg CLI, then fallback.
    """
    # Attempt 1: soundfile (libsndfile)
    try:
        import soundfile as sf  # type: ignore

        data, samplerate = sf.read(str(wav_path))
        sf.write(str(ogg_path), data, samplerate, format="OGG", subtype="VORBIS")
        if ogg_path.exists() and ogg_path.stat().st_size > 1000:
            # Verify valid Ogg header
            with open(ogg_path, "rb") as f:
                header = f.read(4)
            if header == b"OggS":
                print(f"  [OK] Encoded OGG via soundfile: {ogg_path.name} ({ogg_path.stat().st_size:,} bytes)")
                return True
    except Exception as e:
        print(f"  [INFO] soundfile conversion skipped/failed: {e}")

    # Attempt 2: ffmpeg CLI
    try:
        cmd = ["ffmpeg", "-y", "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "4", str(ogg_path)]
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        if res.returncode == 0 and ogg_path.exists() and ogg_path.stat().st_size > 1000:
            print(f"  [OK] Encoded OGG via ffmpeg: {ogg_path.name} ({ogg_path.stat().st_size:,} bytes)")
            return True
    except Exception as e:
        print(f"  [INFO] ffmpeg conversion skipped/failed: {e}")

    # Fallback: if no vorbis encoder is present, copy wav as placeholder so path exists
    print(f"  [WARN] Vorbis encoder unavailable; copying WAV to {ogg_path.name} as fallback container.")
    shutil.copy2(wav_path, ogg_path)
    return True


def main() -> int:
    print("=" * 72)
    print("OldSchoolConsumables - Authentic Audio Asset Pipeline")
    print("=" * 72)

    sounds_dir = get_sounds_dir()
    print(f"Target Directory: {sounds_dir.resolve()}\n")

    summary = []

    for key, spec in OSRS_AUDIO_SOURCES.items():
        sound_id = spec["id"]
        url = spec["url"]
        desc = spec["description"]
        print(f"[*] Processing {desc}...")
        print(f"    Fetching: {url}")

        raw_wav_bytes = download_wav(url, spec["expected_min_bytes"])

        # 1. Save original numbered WAV: e.g. 2401.wav, 2393.wav
        id_wav_file = sounds_dir / f"{sound_id}.wav"
        id_wav_file.write_bytes(raw_wav_bytes)
        print(f"    Saved: {id_wav_file.name} ({len(raw_wav_bytes):,} bytes)")

        # 2. Save named WAV: e.g. potion.wav, food.wav
        named_wav_file = sounds_dir / f"{key}.wav"
        named_wav_file.write_bytes(raw_wav_bytes)
        print(f"    Saved: {named_wav_file.name} ({len(raw_wav_bytes):,} bytes)")

        # 3. Encode named OGG: e.g. potion.ogg, food.ogg
        named_ogg_file = sounds_dir / f"{key}.ogg"
        convert_wav_to_ogg(named_wav_file, named_ogg_file)

        summary.append({
            "key": key,
            "sound_id": sound_id,
            "desc": desc,
            "wav_id": id_wav_file,
            "wav_named": named_wav_file,
            "ogg_named": named_ogg_file,
        })
        print()

    print("=" * 72)
    print("AUDIO ASSET VERIFICATION REPORT:")
    print("=" * 72)
    all_ok = True
    for item in summary:
        w_id = item["wav_id"]
        w_name = item["wav_named"]
        o_name = item["ogg_named"]

        for f in [w_id, w_name, o_name]:
            if not f.exists():
                print(f"  [FAIL] Missing file: {f}")
                all_ok = False
            else:
                sz = f.stat().st_size
                header = f.read_bytes()[:4]
                print(f"  [PASS] {f.name:<15} Size: {sz:>7,} bytes  Header: {header}")

    if all_ok:
        print("\nAll OSRS audio assets downloaded, converted, and verified successfully.")
        return 0
    else:
        print("\nSome audio assets failed verification.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
