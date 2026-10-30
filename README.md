---
title: "OldSchoolConsumables - World of Warcraft: Midnight Addon"
slug: old-school-consumables
status: active
last_activity: 2026-10-30
repo_paths: ["C:/Users/drops/ai-os/projects/old-school-consumables", "C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/OldSchoolConsumables"]
tags: [old-school-consumables, wow-addon, midnight-12, osrs-sounds, audio, consumables, retail-wow]
summary: "World of Warcraft retail addon replacing consumable sound effects with authentic Old School RuneScape drinking and eating sounds. Built strictly compliant with Midnight 12.0+ secret value execution rules."
snapshot: "2026-10-30; notes=0; retail WoW Midnight 12.0+ addon suite deployed live"
sensitivity: "none"
---

# OldSchoolConsumables

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](CHANGELOG.md)
[![WoW Client](https://img.shields.io/badge/WoW-Midnight%2012.0%2B-orange.svg)](OldSchoolConsumables.toc)
[![Wago Addons](https://img.shields.io/badge/Wago-Addons-c1272d.svg)](https://addons.wago.io/)
[![GitHub Releases](https://img.shields.io/badge/GitHub-Releases-181717.svg)](https://github.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#)

[Changelog](CHANGELOG.md) • [Wago Release Guide](WAGO_RELEASE_GUIDE.md)

OldSchoolConsumables is a World of Warcraft: Midnight (12.0+) retail addon that replaces standard consumable audio cues with iconic Old School RuneScape sound effects. When drinking potions, flasks, or health draughts, the addon triggers the classic OSRS drinking sound (Sound ID 2401). When consuming food, feasts, or conjured mana buns, it triggers the OSRS eating crunch (Sound ID 2393).

---

## Features

- **Authentic OSRS Sound Effects**: High-fidelity OGG Vorbis audio tracks paired with 16-bit uncompressed WAV fallbacks for maximum client compatibility.
- **Midnight 12.0+ Consumables Database**: Pre-registered database covering Midnight expansion flasks, combat potions (including *Potion of Light's Potential* and *Liquid Luster*), health draughts, warlock healthstones, raid feasts, and conjured mage buns.
- **High-Precision De-Bounce Engine**: 0.5-second suppression window preventing redundant sound playback during rapid aura ticks, multi-buff applications, or channeled eating.
- **Dual Interface System**:
  - **Standalone Draggable Customizer**: Retro OSRS stone-and-gold themed window with sound channel selector (`Master`, `SFX`, `Dialog`, `Ambience`, `Music`), category toggles, audio test buttons, and custom ID manager.
  - **Blizzard Settings Integration**: Native options panel registered under `Game Menu -> Options -> AddOns -> OldSchoolConsumables`.
- **Custom ID Management**: Add or remove custom Spell IDs and Item IDs directly through the in-game GUI or SavedVariables.
- **Configurable Overhead Text**: Optional floating text display (`*Gulp*`, `*Chomp*`) above player frame. Disabled by default per project specification (`overheadText = false`).

---

## Installation & Releases

### Option 1: Wago Addons (Recommended)
Download and manage updates automatically via the Wago App or web portal:
1. Visit [OldSchoolConsumables on Wago Addons](https://addons.wago.io/).
2. Click **Install with Wago App** or download the latest release package.
3. For maintainers publishing updates to Wago, refer to the [Wago Release Guide](WAGO_RELEASE_GUIDE.md).

### Option 2: GitHub Releases
1. Download the latest `OldSchoolConsumables-v1.0.0.zip` from [GitHub Releases](https://github.com/).
2. Extract the `OldSchoolConsumables` folder into your World of Warcraft retail directory:
   ```
   C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\OldSchoolConsumables
   ```
3. Restart World of Warcraft or reload UI via `/reload`.

### Option 3: Local Dev Deployment Script
For local development and testing, run the automated deployment script in PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File projects/old-school-consumables/deploy.ps1
```

---

## Midnight (12.0+) Secret Values Compliance

In World of Warcraft: Midnight (Patch 12.0+), Blizzard introduced restricted execution boundaries where aura durations, charges, and combat numerical outputs are opaque secret values.

OldSchoolConsumables is architected from the ground up for strict compliance:
1. **Zero Secret Arithmetic**: The trigger and audio engines perform no mathematical operations (`+`, `-`, `*`, `/`) or inequalities (`<`, `>`, `<=`, `>=`) on aura or unit return values.
2. **Zero String Formatting on Secrets**: Secret userdata is never passed to `string.format`, `tostring`, or concatenation operators.
3. **Discrete Event Interception**: Classification relies on `COMBAT_LOG_EVENT_UNFILTERED` (`SPELL_CAST_SUCCESS`, `SPELL_AURA_APPLIED`), `UNIT_SPELLCAST_SUCCEEDED`, and safe presence checks via `C_UnitAuras.GetPlayerAuraBySpellID`.
4. **Taint-Free UI**: The draggable frame and overhead display frames are anchored to `UIParent` with explicit mouse isolation to eliminate secure execution contamination.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/osc` | Open or toggle the draggable OSRS customizer window |
| `/runescape`, `/rsc` | Aliases for `/osc` |
| `/osc ui` or `/osc config` | Open or toggle the customizer window |
| `/osc test` or `/osc pot` | Test potion drinking sound effect |
| `/osc food` or `/osc testfood` | Test food eating sound effect |
| `/osc overhead` | Toggle floating overhead text display (default: Disabled) |
| `/osc help` | Print command usage list in chat |

---

## File Architecture

```
projects/old-school-consumables/
├── OldSchoolConsumables.toc     # Addon manifest (Interface 120100, 120105)
├── Database.lua                 # Midnight consumable registry & default schema
├── AudioEngine.lua              # PlaySoundFile playback wrapper & 0.5s debouncer
├── OverheadDisplay.lua          # Optional floating text animator
├── TriggerEngine.lua            # Combat log & spellcast event classifier
├── UI_DraggableWindow.lua       # Standalone OSRS-themed draggable GUI
├── UI_BlizzardSettings.lua      # Blizzard Settings canvas category panel
├── Core.lua                     # SavedVariables lifecycle & slash command handler
├── CHANGELOG.md                 # Semantic version history (Keep a Changelog)
├── WAGO_RELEASE_GUIDE.md        # Wago Addons publishing & BigWigs packager guide
├── deploy.ps1                   # Live retail deployment script
├── Sounds/
│   ├── potion.ogg / potion.wav  # OSRS potion drinking audio (2401)
│   ├── food.ogg / food.wav      # OSRS food eating audio (2393)
│   ├── 2401.wav                 # OSRS original drinking sound archive
│   └── 2393.wav                 # OSRS original eating sound archive
└── tests/
    └── test_database_and_events.py # Automated integrity & secret value test suite
```

---

## Verification & Testing

To run the automated verification test suite:

```powershell
python projects/old-school-consumables/tests/test_database_and_events.py
```

For release notes and version history, see [CHANGELOG.md](CHANGELOG.md).
