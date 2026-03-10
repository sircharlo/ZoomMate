"""i18n loader replacing Includes/i18n.au3 and language files."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

_TRANSLATION_LINE = re.compile(r'\$TRANSLATIONS_[A-Z]+\.Add\("([^"]+)",\s*"((?:[^"]|"")*)"\)')
_LANG_FILES = {
    "en": "en.au3",
    "fr": "fr.au3",
    "es": "es.au3",
    "ru": "ru.au3",
    "uk": "uk.au3",
}


@dataclass
class I18nStore:
    language: str = "en"
    translations: dict[str, dict[str, str]] = field(default_factory=dict)


STORE = I18nStore()


def _parse_translation_file(path: Path) -> dict[str, str]:
    content = path.read_text(encoding="utf-8", errors="ignore")
    items: dict[str, str] = {}
    for key, value in _TRANSLATION_LINE.findall(content):
        items[key] = value.replace('""', '"')
    return items


def _InitializeTranslations(language: str = "en") -> None:
    bundle_root = Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parents[2]))
    includes_dir = bundle_root / "Includes"
    translations: dict[str, dict[str, str]] = {}
    for lang, filename in _LANG_FILES.items():
        file_path = includes_dir / filename
        if file_path.exists():
            translations[lang] = _parse_translation_file(file_path)

    if "en" not in translations:
        translations["en"] = {
            "LANGNAME": "English",
            "INFO_NO_MEETING_SCHEDULED": "No meeting scheduled for today.",
            "ERROR_GET_DESKTOP_ELEMENT_FAILED": "Failed to get desktop element.",
        }

    STORE.translations = translations
    STORE.language = language if language in translations else "en"


def _GetLanguageTranslations(lang_code: str) -> dict[str, str]:
    return STORE.translations.get(lang_code, STORE.translations.get("en", {}))


def _ListAvailableLanguageNames() -> list[str]:
    names = []
    for code, values in STORE.translations.items():
        names.append(values.get("LANGNAME", code))
    return sorted(names)


def _GetLanguageDisplayName(lang_code: str) -> str:
    return _GetLanguageTranslations(lang_code).get("LANGNAME", lang_code)


def t(key: str, p0: str | None = None, p1: str | None = None, p2: str | None = None) -> str:
    base = _GetLanguageTranslations(STORE.language).get(key, key)
    replacements = [p0, p1, p2]
    for index, value in enumerate(replacements):
        if value is not None:
            base = base.replace("{" + str(index) + "}", value)
    return base
