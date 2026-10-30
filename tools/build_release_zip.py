#!/usr/bin/env python3
"""Build and verify release zip package for OldSchoolConsumables WoW Retail addon."""

from __future__ import annotations

import os
import re
import sys
import zipfile
from pathlib import Path

ADDON_DIR = Path(__file__).resolve().parent.parent
DIST_DIR = ADDON_DIR / "dist"
ADDON_NAME = "OldSchoolConsumables"

EXCLUDE_PATTERNS = {
    ".git",
    ".github",
    ".gitignore",
    ".pkgmeta",
    "README.md",
    "CHANGELOG.md",
    "WAGO_RELEASE_GUIDE.md",
    "tests",
    "tools",
    "deploy.ps1",
    "dist",
    "__pycache__",
    ".pytest_cache",
}

EXPECTED_FILES = [
    f"{ADDON_NAME}/OldSchoolConsumables.toc",
    f"{ADDON_NAME}/Core.lua",
    f"{ADDON_NAME}/Database.lua",
    f"{ADDON_NAME}/AudioEngine.lua",
    f"{ADDON_NAME}/TriggerEngine.lua",
    f"{ADDON_NAME}/OverheadDisplay.lua",
    f"{ADDON_NAME}/UI_DraggableWindow.lua",
    f"{ADDON_NAME}/UI_BlizzardSettings.lua",
    f"{ADDON_NAME}/Sounds/potion.ogg",
    f"{ADDON_NAME}/Sounds/potion.wav",
    f"{ADDON_NAME}/Sounds/food.ogg",
    f"{ADDON_NAME}/Sounds/food.wav",
    f"{ADDON_NAME}/Sounds/2401.wav",
    f"{ADDON_NAME}/Sounds/2393.wav",
]


def extract_version_from_toc(toc_path: Path) -> str:
    """Extract addon version from .toc file, defaulting to 1.0.0."""
    if not toc_path.exists():
        return "1.0.0"
    content = toc_path.read_text(encoding="utf-8")
    match = re.search(r"^##\s*Version:\s*([^\r\n]+)", content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return "1.0.0"


def should_exclude(rel_path: Path) -> bool:
    """Check if relative path matches exclusion rules."""
    parts = rel_path.parts
    for part in parts:
        if part in EXCLUDE_PATTERNS:
            return True
        if part.startswith(".") and part != ".":
            return True
        if part.endswith(".pyc"):
            return True
    return False


def build_release_zip() -> Path:
    """Build the release zip package and return its path."""
    toc_path = ADDON_DIR / f"{ADDON_NAME}.toc"
    version = extract_version_from_toc(toc_path)
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    
    zip_filename = f"{ADDON_NAME}-v{version}.zip"
    zip_path = DIST_DIR / zip_filename

    print(f"[BUILD] Packaging {ADDON_NAME} v{version}...")
    print(f"[BUILD] Source Directory: {ADDON_DIR}")
    print(f"[BUILD] Target Archive:   {zip_path}")

    files_to_pack: list[tuple[Path, str]] = []

    for root, dirs, files in os.walk(ADDON_DIR):
        current_dir = Path(root)
        rel_dir = current_dir.relative_to(ADDON_DIR)
        
        # Prune excluded directories in-place
        dirs[:] = [d for d in dirs if not should_exclude(rel_dir / d)]

        for file_name in sorted(files):
            file_path = current_dir / file_name
            rel_file = file_path.relative_to(ADDON_DIR)
            if should_exclude(rel_file):
                continue

            # Prefix with addon folder name inside the zip
            archive_name = (Path(ADDON_NAME) / rel_file).as_posix()
            files_to_pack.append((file_path, archive_name))

    files_to_pack.sort(key=lambda x: x[1])

    with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for src_path, arc_name in files_to_pack:
            zf.write(src_path, arc_name)
            print(f"  + Added: {arc_name} ({src_path.stat().st_size} bytes)")

    print(f"\n[BUILD] Created {zip_path.name} ({zip_path.stat().st_size} bytes)")
    return zip_path


def verify_zip(zip_path: Path) -> bool:
    """Verify integrity and structure of the release zip."""
    print(f"\n[VERIFY] Verifying {zip_path.name}...")
    
    with zipfile.ZipFile(zip_path, mode="r") as zf:
        # Test CRC-32 integrity
        bad_file = zf.testzip()
        if bad_file:
            print(f"[ERROR] Corrupted file in zip: {bad_file}")
            return False

        namelist = set(zf.namelist())

        # Ensure all required files are present
        missing = [f for f in EXPECTED_FILES if f not in namelist]
        if missing:
            print(f"[ERROR] Missing required files in archive:")
            for m in missing:
                print(f"  - {m}")
            return False

        # Ensure no excluded files leaked in
        leaks = []
        for name in namelist:
            parts = Path(name).parts
            if not parts or parts[0] != ADDON_NAME:
                leaks.append(f"{name} (root must be {ADDON_NAME})")
            for part in parts[1:]:
                if part in EXCLUDE_PATTERNS or part.endswith(".pyc") or part.endswith(".py"):
                    leaks.append(name)
                    break

        if leaks:
            print(f"[ERROR] Disallowed files leaked into archive:")
            for leak in leaks:
                print(f"  ! {leak}")
            return False

        print("[VERIFY] Integrity check passed!")
        print(f"[VERIFY] Total entries: {len(namelist)}")
        print("[VERIFY] Contents:")
        for info in zf.infolist():
            print(f"  - {info.filename:50} [{info.file_size:8d} bytes -> {info.compress_size:8d} bytes, ratio {info.compress_size/max(1,info.file_size):.1%}]")

    return True


def main() -> int:
    try:
        zip_path = build_release_zip()
        success = verify_zip(zip_path)
        if not success:
            return 1
        print(f"\n[SUCCESS] Release archive ready at: {zip_path}")
        return 0
    except Exception as e:
        print(f"[FAIL] Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
