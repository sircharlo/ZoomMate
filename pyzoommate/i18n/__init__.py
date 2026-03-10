"""i18n loader replacing Includes/i18n.au3 and language files."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class I18nStore:
    language: str = "en"
    translations: dict[str, dict[str, str]] = None

    def __post_init__(self) -> None:
        if self.translations is None:
            self.translations = {
                "en": {
                    "INFO_NO_MEETING_SCHEDULED": "No meeting scheduled today.",
                    "ERROR_GET_DESKTOP_ELEMENT_FAILED": "Failed to access desktop element.",
                }
            }


STORE = I18nStore()


def _InitializeTranslations(language: str = "en") -> None:
    STORE.language = language


def _GetLanguageTranslations(lang_code: str) -> dict[str, str]:
    return STORE.translations.get(lang_code, STORE.translations["en"])


def t(key: str, p0: str | None = None, p1: str | None = None, p2: str | None = None) -> str:
    base = _GetLanguageTranslations(STORE.language).get(key, key)
    replacements = [p0, p1, p2]
    for index, value in enumerate(replacements):
        if value is not None:
            base = base.replace("{" + str(index) + "}", value)
    return base
