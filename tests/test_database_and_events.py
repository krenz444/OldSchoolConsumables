"""
OldSchoolConsumables - Deterministic Verification & Test Suite
World of Warcraft: Midnight (12.0+) Addon Integrity Tests

Tests TOC metadata, Consumables Database registration, Midnight Secret-Value
Static Analysis Safety, Audio Asset Integrity, and Sound De-bounce Simulation.
"""

import os
import re
import sys
import unittest
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# Addon root directory resolution
ADDON_DIR = Path(__file__).resolve().parent.parent
SOUNDS_DIR = ADDON_DIR / "Sounds"
TOC_FILE = ADDON_DIR / "OldSchoolConsumables.toc"
DATABASE_LUA = ADDON_DIR / "Database.lua"


# ==============================================================================
# Helper Utilities: Lua Parsing & Secret Value Static Analysis
# ==============================================================================

def strip_lua_comments(code: str) -> str:
    """Removes Lua block comments (--[[ ... ]]) and line comments (-- ...)."""
    # Block comments: --[[ ... ]] or --[=[ ... ]=]
    code = re.sub(r"--\[(=*)\[.*?\]\1\]", "", code, flags=re.DOTALL)
    # Line comments: -- ...
    code = re.sub(r"--.*$", "", code, flags=re.MULTILINE)
    return code


def parse_toc_file(toc_path: Path) -> Tuple[Dict[str, str], List[str]]:
    """Parses a World of Warcraft TOC file into metadata directives and loaded lua files."""
    metadata: Dict[str, str] = {}
    lua_files: List[str] = []

    with open(toc_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("##"):
                # Directive e.g. "## Interface: 120100, 120105"
                directive_body = line[2:].strip()
                if ":" in directive_body:
                    key, val = directive_body.split(":", 1)
                    metadata[key.strip()] = val.strip()
            elif not line.startswith("#"):
                # File entry e.g. "Database.lua"
                lua_files.append(line)

    return metadata, lua_files


def extract_lua_category_sections(lua_code: str) -> Dict[str, str]:
    """Extracts raw category blocks from DB.Consumables table definition in Database.lua."""
    categories = ["flasks", "potions", "health", "feasts", "food", "magebuns"]
    sections: Dict[str, str] = {}

    for i, cat in enumerate(categories):
        pattern = rf"{cat}\s*=\s*\{{"
        match = re.search(pattern, lua_code)
        if not match:
            continue
        start_pos = match.start()

        # Find the next category or closing of DB.Consumables
        end_pos = len(lua_code)
        for next_cat in categories[i + 1:]:
            next_match = re.search(rf"{next_cat}\s*=\s*\{{", lua_code[start_pos + len(cat):])
            if next_match:
                end_pos = start_pos + len(cat) + next_match.start()
                break

        sections[cat] = lua_code[start_pos:end_pos]

    return sections


class SecretValueSafetyScanner:
    """Static analysis scanner for WoW Midnight (12.0+) secret value compliance.
    
    Under Midnight 12.0+ restricted execution rules:
    - Aura duration/expirationTime and applications/charges are secret userdata.
    - Arithmetic (+, -, *, /) or inequalities (>, <, >=, <=) on secret values cause fatal Lua errors.
    - String formatting (string.format) or concatenation (..) on secret values causes fatal errors.
    - Nil comparisons (== nil, ~= nil) and boolean truthiness checks (if aura.duration then) are safe.
    - UnitHealth("player") arithmetic in restricted/combat contexts is forbidden.
    """

    FORBIDDEN_RULES: List[Tuple[str, str]] = [
        # Arithmetic on aura.duration or aura.expirationTime
        (
            r"aura\.(duration|expirationTime)\s*([+\-*/%^]|\bmath\.)",
            "Arithmetic operation on aura.duration / expirationTime"
        ),
        (
            r"([+\-*/%^])\s*aura\.(duration|expirationTime)",
            "Arithmetic operation on aura.duration / expirationTime"
        ),
        # Inequality or numeric comparison on aura.duration or aura.expirationTime
        (
            r"aura\.(duration|expirationTime)\s*(>=|<=|>|<|==\s*\d|~=\s*\d)",
            "Inequality or numeric comparison on aura.duration / expirationTime"
        ),
        (
            r"(>=|<=|>|<|\d\s*==|\d\s*~=)\s*aura\.(duration|expirationTime)",
            "Inequality or numeric comparison on aura.duration / expirationTime"
        ),
        # Arithmetic on aura.applications, count, charges
        (
            r"aura\.(applications|count|charges)\s*([+\-*/%^]|\bmath\.)",
            "Arithmetic operation on aura.applications / count"
        ),
        (
            r"([+\-*/%^])\s*aura\.(applications|count|charges)",
            "Arithmetic operation on aura.applications / count"
        ),
        # Inequality or numeric comparison on aura.applications, count, charges
        (
            r"aura\.(applications|count|charges)\s*(>=|<=|>|<|==\s*\d|~=\s*\d)",
            "Inequality or numeric comparison on aura.applications / count"
        ),
        (
            r"(>=|<=|>|<|\d\s*==|\d\s*~=)\s*aura\.(applications|count|charges)",
            "Inequality or numeric comparison on aura.applications / count"
        ),
        # UnitHealth player arithmetic in combat
        (
            r"UnitHealth\s*\(\s*[\"']player[\"']\s*\)\s*([+\-*/%^><]|>=|<=|==\s*\d|~=\s*\d)",
            "Direct arithmetic or comparison on UnitHealth('player')"
        ),
        (
            r"([+\-*/%^><]|>=|<=|\d\s*==|\d\s*~=)\s*UnitHealth\s*\(\s*[\"']player[\"']\s*\)",
            "Direct arithmetic or comparison on UnitHealth('player')"
        ),
        # string.format on secret aura values
        (
            r"string\.format\s*\([^;)]*aura\.(duration|expirationTime|applications|count|charges)",
            "Forbidden string.format invocation with secret aura value"
        ),
        # string concatenation on secret aura values
        (
            r"aura\.(duration|expirationTime|applications|count|charges)\s*\.\.",
            "Forbidden string concatenation with secret aura value"
        ),
        (
            r"\.\.\s*aura\.(duration|expirationTime|applications|count|charges)",
            "Forbidden string concatenation with secret aura value"
        ),
    ]

    @classmethod
    def scan_code(cls, lua_code: str, filename: str = "<unknown>") -> List[str]:
        """Scans Lua code for secret-value violations, returning any violation descriptions."""
        clean_code = strip_lua_comments(lua_code)
        violations: List[str] = []

        for line_num, line in enumerate(clean_code.splitlines(), start=1):
            line_str = line.strip()
            if not line_str:
                continue
            for pattern, desc in cls.FORBIDDEN_RULES:
                if re.search(pattern, line_str):
                    violations.append(f"[{filename}:{line_num}] {desc}: '{line_str}'")

        return violations


# ==============================================================================
# Simulation: Sound De-bounce Engine
# ==============================================================================

class ConsumableSoundDebouncer:
    """Simulates the 0.5s sound de-bounce engine used by OldSchoolConsumables.
    
    Prevents duplicate sound effects when multiple auras or combat log events
    fire simultaneously or in rapid succession (e.g., within a 0.5s window).
    """

    def __init__(self, window_seconds: float = 0.5):
        self.window = window_seconds
        self.last_played_time = -float("inf")
        self.sound_play_count = 0
        self.history: List[Tuple[float, str, bool]] = []

    def trigger_event(self, current_time: float, sound_name: str = "potion") -> bool:
        """Attempts to play a sound at current_time.
        
        Returns True if the sound played, False if suppressed by the debounce window.
        """
        elapsed = current_time - self.last_played_time
        if elapsed >= self.window:
            self.last_played_time = current_time
            self.sound_play_count += 1
            self.history.append((current_time, sound_name, True))
            return True
        else:
            self.history.append((current_time, sound_name, False))
            return False


# ==============================================================================
# Test Cases
# ==============================================================================

class TestTOCFormat(unittest.TestCase):
    """Verifies OldSchoolConsumables.toc metadata, interface version, and load order."""

    def setUp(self):
        self.assertTrue(TOC_FILE.is_file(), f"TOC file missing: {TOC_FILE}")
        self.metadata, self.lua_files = parse_toc_file(TOC_FILE)

    def test_toc_interface_version(self):
        """Confirms ## Interface: 120100, 120105."""
        self.assertIn("Interface", self.metadata, "TOC file must declare 'Interface'")
        interface_val = self.metadata["Interface"]
        self.assertIn("120100", interface_val, "Interface must support Midnight 12.0.1 (120100)")
        self.assertIn("120105", interface_val, "Interface must support Midnight 12.0.5 (120105)")
        self.assertEqual(interface_val, "120100, 120105")

    def test_toc_saved_variables(self):
        """Confirms ## SavedVariables: OldSchoolConsumablesDB."""
        self.assertIn("SavedVariables", self.metadata, "TOC file must declare 'SavedVariables'")
        self.assertEqual(
            self.metadata["SavedVariables"],
            "OldSchoolConsumablesDB",
            "SavedVariables must be 'OldSchoolConsumablesDB'"
        )

    def test_toc_title_and_category(self):
        """Confirms Title and Category metadata."""
        self.assertIn("Title", self.metadata)
        self.assertIn("OldSchoolConsumables", self.metadata["Title"])
        self.assertIn("Category", self.metadata)
        self.assertEqual(self.metadata["Category"], "Audio")

    def test_toc_load_order(self):
        """Confirms strict file load order:
        Database.lua -> AudioEngine.lua -> OverheadDisplay.lua -> TriggerEngine.lua ->
        UI_DraggableWindow.lua -> UI_BlizzardSettings.lua -> Core.lua
        """
        expected_order = [
            "Database.lua",
            "AudioEngine.lua",
            "OverheadDisplay.lua",
            "TriggerEngine.lua",
            "UI_DraggableWindow.lua",
            "UI_BlizzardSettings.lua",
            "Core.lua",
        ]
        self.assertEqual(
            self.lua_files,
            expected_order,
            f"TOC load order mismatch! Expected: {expected_order}, Got: {self.lua_files}"
        )


class TestConsumableDatabase(unittest.TestCase):
    """Verifies that all required Midnight 12.0+ consumables are registered in Database.lua."""

    def setUp(self):
        self.assertTrue(DATABASE_LUA.is_file(), f"Database.lua missing: {DATABASE_LUA}")
        with open(DATABASE_LUA, "r", encoding="utf-8") as f:
            self.content = f.read()
        self.sections = extract_lua_category_sections(self.content)

    def test_midnight_flasks_registered(self):
        """Verifies presence of Midnight Flasks (1235111, 1235108, 1235110, 1235057, 1239355)."""
        expected_flasks = [1235111, 1235108, 1235110, 1235057, 1239355]
        flask_section = self.sections.get("flasks", "")
        self.assertTrue(flask_section, "Flasks section missing in Database.lua")

        for spell_id in expected_flasks:
            self.assertIn(
                str(spell_id),
                flask_section,
                f"Midnight Flask buff ID {spell_id} missing from flasks section in Database.lua"
            )

    def test_combat_potions_registered(self):
        """Verifies Combat Potions (1236616 Light's Potential, 1236998 Rampant Abandon, 1236994 Recklessness, 1238443 Zealotry, 1295132 Liquid Luster, 1239479 Devoured Dreams)."""
        expected_potions = [1236616, 1236998, 1236994, 1238443, 1295132, 1239479]
        expected_items = [241308, 241309, 245897, 245898, 241288, 241289, 241292, 241296, 271887]
        potion_section = self.sections.get("potions", "")
        self.assertTrue(potion_section, "Potions section missing in Database.lua")

        for spell_id in expected_potions:
            self.assertIn(
                str(spell_id),
                potion_section,
                f"Combat Potion spell ID {spell_id} missing from potions section in Database.lua"
            )

        for item_id in expected_items:
            self.assertIn(
                str(item_id),
                potion_section,
                f"Combat Potion item ID {item_id} missing from potions section in Database.lua"
            )

    def test_healing_potions_and_healthstones_registered(self):
        """Verifies Healing Potions & Healthstones (1238009, 1234768, 1259276, 5512, 224464, 431416, 241304, 271884)."""
        expected_health = [1238009, 1234768, 1259276, 5512, 224464, 431416, 241304, 271884]
        health_section = self.sections.get("health", "")
        self.assertTrue(health_section, "Health section missing in Database.lua")

        for entry_id in expected_health:
            self.assertIn(
                str(entry_id),
                health_section,
                f"Healing item/spell ID {entry_id} missing from health section in Database.lua"
            )

    def test_feasts_registered(self):
        """Verifies Feasts (1259657, 1259658, 1259656, 1259659, 1243843)."""
        expected_feasts = [1259657, 1259658, 1259656, 1259659, 1243843]
        feast_section = self.sections.get("feasts", "")
        self.assertTrue(feast_section, "Feasts section missing in Database.lua")

        for spell_id in expected_feasts:
            self.assertIn(
                str(spell_id),
                feast_section,
                f"Feast spell ID {spell_id} missing from feasts section in Database.lua"
            )

    def test_mage_buns_registered(self):
        """Verifies Mage Buns (113509, 192002, 190336)."""
        expected_buns = [113509, 192002, 190336]
        magebun_section = self.sections.get("magebuns", "")
        self.assertTrue(magebun_section, "Magebuns section missing in Database.lua")

        for entry_id in expected_buns:
            self.assertIn(
                str(entry_id),
                magebun_section,
                f"Mage bun item/spell ID {entry_id} missing from magebuns section in Database.lua"
            )

    def test_default_settings_overhead_text_disabled(self):
        """Verifies DefaultSettings has overheadText = false by default."""
        match = re.search(r"overheadText\s*=\s*(false|true)", self.content)
        self.assertIsNotNone(match, "overheadText setting not found in DB.DefaultSettings")
        self.assertEqual(
            match.group(1),
            "false",
            "overheadText must be false by default per specification"
        )


class TestSecretSafety(unittest.TestCase):
    """Static analysis scanning Lua files to guarantee secret-value compliance under Midnight 12.0+."""

    def test_scanner_catches_dangerous_patterns(self):
        """Validates that the safety scanner accurately identifies forbidden code patterns."""
        forbidden_samples = [
            ("local rem = aura.duration > 0", "duration inequality"),
            ("local rem = aura.duration + 5", "duration addition"),
            ("local rem = 10 - aura.duration", "duration subtraction"),
            ("local count = aura.applications + 1", "applications addition"),
            ("if aura.applications >= 2 then", "applications inequality"),
            ("local hp = UnitHealth('player') + 10", "UnitHealth arithmetic"),
            ("if UnitHealth(\"player\") < 5000 then", "UnitHealth inequality"),
            ("local msg = string.format('time: %s', aura.duration)", "string.format secret"),
            ("local msg = 'time:' .. aura.duration", "concatenation secret"),
        ]
        for snippet, desc in forbidden_samples:
            violations = SecretValueSafetyScanner.scan_code(snippet, filename=desc)
            self.assertGreater(
                len(violations),
                0,
                f"Scanner failed to detect forbidden pattern: '{snippet}' ({desc})"
            )

    def test_scanner_allows_safe_patterns(self):
        """Validates that the safety scanner allows permitted nil-checks and boolean checks."""
        safe_samples = [
            "if aura.duration ~= nil then",
            "if aura.duration == nil then",
            "if aura.duration then",
            "if not aura.duration then",
            "local hasDuration = (aura.duration ~= nil)",
            "if aura.applications ~= nil then",
            "local safeID = tonumber(spellID)",
            "local isCombat = InCombatLockdown()",
        ]
        for snippet in safe_samples:
            violations = SecretValueSafetyScanner.scan_code(snippet, filename="safe_snippet")
            self.assertEqual(
                violations,
                [],
                f"Scanner falsely flagged safe pattern: '{snippet}' -> {violations}"
            )

    def test_addon_lua_files_secret_safety(self):
        """Scans all existing Lua files in projects/old-school-consumables/ for secret violations."""
        target_files = [
            "Database.lua",
            "AudioEngine.lua",
            "TriggerEngine.lua",
            "OverheadDisplay.lua",
            "UI_DraggableWindow.lua",
            "UI_BlizzardSettings.lua",
            "Core.lua",
        ]

        # Gather all existing .lua files in the addon directory
        lua_files_to_scan = [
            p for p in ADDON_DIR.glob("*.lua")
            if p.is_file()
        ]

        self.assertGreater(
            len(lua_files_to_scan),
            0,
            "No Lua files found in addon directory to scan!"
        )

        all_violations: List[str] = []
        for lua_file in lua_files_to_scan:
            with open(lua_file, "r", encoding="utf-8") as f:
                code = f.read()
            violations = SecretValueSafetyScanner.scan_code(code, filename=lua_file.name)
            all_violations.extend(violations)

        self.assertEqual(
            all_violations,
            [],
            f"Secret-value violations detected in Lua files:\n" + "\n".join(all_violations)
        )


class TestAudioAssetIntegrity(unittest.TestCase):
    """Verifies that all required RuneScape audio assets exist and have valid sizes and headers."""

    def test_audio_directory_exists(self):
        """Verifies Sounds directory exists."""
        self.assertTrue(SOUNDS_DIR.is_dir(), f"Sounds directory missing: {SOUNDS_DIR}")

    def test_potion_wav_integrity(self):
        """Checks Sounds/potion.wav exists and is > 30,000 bytes."""
        potion_wav = SOUNDS_DIR / "potion.wav"
        self.assertTrue(potion_wav.is_file(), f"Sounds/potion.wav missing: {potion_wav}")
        size = potion_wav.stat().st_size
        self.assertGreater(
            size,
            30000,
            f"Sounds/potion.wav size {size} bytes is not > 30,000 bytes"
        )

    def test_food_wav_integrity(self):
        """Checks Sounds/food.wav exists and is > 25,000 bytes."""
        food_wav = SOUNDS_DIR / "food.wav"
        self.assertTrue(food_wav.is_file(), f"Sounds/food.wav missing: {food_wav}")
        size = food_wav.stat().st_size
        self.assertGreater(
            size,
            25000,
            f"Sounds/food.wav size {size} bytes is not > 25,000 bytes"
        )

    def test_potion_ogg_integrity(self):
        """Checks Sounds/potion.ogg exists, has non-zero size, and starts with OggS magic bytes."""
        potion_ogg = SOUNDS_DIR / "potion.ogg"
        self.assertTrue(potion_ogg.is_file(), f"Sounds/potion.ogg missing: {potion_ogg}")
        self.assertGreater(potion_ogg.stat().st_size, 0, "Sounds/potion.ogg is empty")

        with open(potion_ogg, "rb") as f:
            magic = f.read(4)
        self.assertEqual(magic, b"OggS", f"potion.ogg magic header mismatch: {magic}")

    def test_food_ogg_integrity(self):
        """Checks Sounds/food.ogg exists, has non-zero size, and starts with OggS magic bytes."""
        food_ogg = SOUNDS_DIR / "food.ogg"
        self.assertTrue(food_ogg.is_file(), f"Sounds/food.ogg missing: {food_ogg}")
        self.assertGreater(food_ogg.stat().st_size, 0, "Sounds/food.ogg is empty")

        with open(food_ogg, "rb") as f:
            magic = f.read(4)
        self.assertEqual(magic, b"OggS", f"food.ogg magic header mismatch: {magic}")


class TestDebounceSimulation(unittest.TestCase):
    """Verifies that the 0.5s de-bounce window suppresses rapid concurrent events."""

    def test_rapid_concurrent_events_specification(self):
        """Simulates 0.5s de-bounce window:
        - t = 0.00s: triggers sound 1 (played = True)
        - t = 0.05s: suppressed (played = False)
        - t = 0.10s: suppressed (played = False)
        - t = 0.60s: triggers sound 2 (played = True)
        Total sounds played = 2.
        """
        debouncer = ConsumableSoundDebouncer(window_seconds=0.5)

        # t = 0.00s -> sound 1 fires
        r1 = debouncer.trigger_event(0.0, "potion")
        self.assertTrue(r1, "Event at t=0.0s should play sound")
        self.assertEqual(debouncer.sound_play_count, 1)

        # t = 0.05s -> suppressed (50ms apart)
        r2 = debouncer.trigger_event(0.05, "potion")
        self.assertFalse(r2, "Event at t=0.05s (50ms) should be suppressed by debounce")
        self.assertEqual(debouncer.sound_play_count, 1)

        # t = 0.10s -> suppressed (100ms apart from start)
        r3 = debouncer.trigger_event(0.10, "potion")
        self.assertFalse(r3, "Event at t=0.10s (100ms) should be suppressed by debounce")
        self.assertEqual(debouncer.sound_play_count, 1)

        # t = 0.60s -> sound 2 fires (600ms >= 500ms window)
        r4 = debouncer.trigger_event(0.60, "potion")
        self.assertTrue(r4, "Event at t=0.60s should play sound after 0.5s window elapsed")
        self.assertEqual(debouncer.sound_play_count, 2)

    def test_exact_boundary_conditions(self):
        """Tests boundary precision:
        - Event at t=0.00s triggers.
        - Event at t=0.499s is suppressed (elapsed < 0.500s).
        - Event at t=0.500s triggers (elapsed >= 0.500s).
        """
        debouncer = ConsumableSoundDebouncer(window_seconds=0.5)

        self.assertTrue(debouncer.trigger_event(0.0))
        self.assertFalse(debouncer.trigger_event(0.499))
        self.assertTrue(debouncer.trigger_event(0.500))
        self.assertEqual(debouncer.sound_play_count, 2)

    def test_high_frequency_event_burst(self):
        """Simulates 20 rapid events within 200ms (e.g. multi-aura batch application).
        Only 1 sound should ever play.
        """
        debouncer = ConsumableSoundDebouncer(window_seconds=0.5)

        for i in range(20):
            t = i * 0.01  # 0ms, 10ms, 20ms, ... 190ms
            played = debouncer.trigger_event(t)
            if i == 0:
                self.assertTrue(played, f"Initial event at t={t} should play")
            else:
                self.assertFalse(played, f"Burst event at t={t} should be suppressed")

        self.assertEqual(debouncer.sound_play_count, 1)


class TestCombatAndNameFallback(unittest.TestCase):
    """Verifies combat log registration and smart name pattern fallback logic."""

    def test_combat_log_event_registered(self):
        """Verifies that COMBAT_LOG_EVENT_UNFILTERED is registered in TriggerEngine.lua."""
        with open(ADDON_DIR / "TriggerEngine.lua", "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("COMBAT_LOG_EVENT_UNFILTERED", content, "TriggerEngine must listen to COMBAT_LOG_EVENT_UNFILTERED for combat reliability")
        self.assertIn("CombatLogGetCurrentEventInfo", content, "TriggerEngine must call CombatLogGetCurrentEventInfo")
        self.assertIn("SPELL_CAST_SUCCESS", content, "TriggerEngine must check SPELL_CAST_SUCCESS for combat casts")
        self.assertIn("SPELL_AURA_APPLIED", content, "TriggerEngine must check SPELL_AURA_APPLIED for combat buffs")

    def test_smart_name_matching_fallback_in_database(self):
        """Verifies that Database.lua contains smart name pattern matching for unlisted potions and foods."""
        with open(DATABASE_LUA, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("lower:find(\"potential\")", content, "Database.lua must support Light's Potential name pattern matching")
        self.assertIn("lower:find(\"potion\")", content, "Database.lua must support generic potion name matching")
        self.assertIn("lower:find(\"draught\")", content, "Database.lua must support draught name matching")
        self.assertIn("lower:find(\"flask\")", content, "Database.lua must support flask name matching")



# ==============================================================================
# Main Runner
# ==============================================================================

if __name__ == "__main__":
    unittest.main()
