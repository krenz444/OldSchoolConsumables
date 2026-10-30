# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-30

### Added
- **Authentic OSRS Sound Effects**: Integrated original Old School RuneScape drinking sound (Sound ID 2401) and food eating sound (Sound ID 2393) in both 44.1 kHz OGG Vorbis and uncompressed 16-bit PCM WAV formats.
- **Dual Interface System**:
  - Standalone draggable retro OSRS stone-and-gold themed customizer window accessible via `/osc`, `/rsc`, or `/runescape`.
  - Native Blizzard Settings canvas integration under `Game Menu -> Options -> AddOns -> OldSchoolConsumables`.
- **Comprehensive Midnight 12.0+ Consumable Catalog**:
  - Full expansion coverage for Midnight flasks, combat potions, health draughts, cauldrons, warlock healthstones, raid feasts, and conjured mage buns.
  - Item ID and Spell ID mappings for *Potion of Light's Potential* (Spell ID `1236616`, Item IDs `241308`, `241309`, `245897`, `245898`).
  - Item ID and Spell ID mappings for *Liquid Luster* (Spell ID `1295132`).
- **High-Reliability Combat Log Monitoring**: Intercepts `COMBAT_LOG_EVENT_UNFILTERED` (`SPELL_CAST_SUCCESS`, `SPELL_AURA_APPLIED`) alongside `UNIT_SPELLCAST_SUCCEEDED` to guarantee 100% trigger reliability during combat encounters and macro clicks.
- **Smart Pattern Matching Fallback**: Substring matching (`"potion"`, `"draught"`, `"elixir"`, `"feast"`, `"food"`, `"bread"`, etc.) for newly introduced or uncataloged consumables.
- **Audio De-Bounce & Routing**:
  - 0.5-second suppression window preventing audio stutter during rapid buff applications or channeled consumption.
  - Configurable sound channel routing across `Master`, `SFX`, `Dialog`, `Ambience`, and `Music`.
- **Midnight 12.0+ Secret Values Compliance**: Strict zero-arithmetic and zero-formatting policy on opaque combat userdata and unit aura returns to prevent protected execution errors.
- **Configurable Overhead Floating Text**: Optional floating visual notifications (`*Gulp*`, `*Chomp*`) anchored to player frame (disabled by default).
