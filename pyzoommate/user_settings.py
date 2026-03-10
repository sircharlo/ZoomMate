"""User settings store replacing Includes/UserSettings.au3."""

from __future__ import annotations

from configparser import ConfigParser
from pathlib import Path

SETTINGS_PATH = Path("zoommate_user_settings.ini")
USER_SETTINGS = ConfigParser()


def _load() -> None:
    if SETTINGS_PATH.exists():
        USER_SETTINGS.read(SETTINGS_PATH, encoding="utf-8")


def _save() -> None:
    with SETTINGS_PATH.open("w", encoding="utf-8") as handle:
        USER_SETTINGS.write(handle)


def _GetIniSectionForKey(key: str) -> str:
    mapping = {
        "Language": "General",
        "MeetingID": "Meeting",
        "MidweekDay": "Meeting",
        "MidweekTime": "Meeting",
        "WeekendDay": "Meeting",
        "WeekendTime": "Meeting",
    }
    return mapping.get(key, "General")


def GetUserSetting(key: str, default: str = "") -> str:
    return get_user_setting(key, default)


def get_user_setting(key: str, default: str = "") -> str:
    section = _GetIniSectionForKey(key)
    if USER_SETTINGS.has_option(section, key):
        return USER_SETTINGS.get(section, key)
    return default


def set_user_setting(key: str, value: str) -> None:
    section = _GetIniSectionForKey(key)
    if not USER_SETTINGS.has_section(section):
        USER_SETTINGS.add_section(section)
    USER_SETTINGS.set(section, key, value)
    _save()


_load()
