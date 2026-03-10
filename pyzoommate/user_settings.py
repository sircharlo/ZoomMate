"""User settings and INI compatibility layer."""

from __future__ import annotations

from configparser import ConfigParser
from pathlib import Path

CONFIG_FILE = Path("zoom_config.ini")
USER_SETTINGS: dict[str, str] = {}


def _StringToUTF8(text: str) -> str:
    return text.encode("utf-8", errors="ignore").decode("latin1", errors="ignore")


def _UTF8ToString(text: str) -> str:
    return text.encode("latin1", errors="ignore").decode("utf-8", errors="ignore")


def _GetIniSectionForKey(key: str) -> str:
    if key == "MeetingID":
        return "ZoomSettings"
    if key in {"MidweekDay", "MidweekTime", "WeekendDay", "WeekendTime"}:
        return "Meetings"
    if key in {"Language", "SnapZoomSide", "KeyboardShortcut"}:
        return "General"
    return "ZoomStrings"


def _load_ini() -> ConfigParser:
    parser = ConfigParser()
    if CONFIG_FILE.exists():
        parser.read(CONFIG_FILE, encoding="utf-8")
    return parser


def _save_ini(parser: ConfigParser) -> None:
    with CONFIG_FILE.open("w", encoding="utf-8") as handle:
        parser.write(handle)


def GetUserSetting(key: str, default: str = "") -> str:
    return get_user_setting(key, default)


def get_user_setting(key: str, default: str = "") -> str:
    return USER_SETTINGS.get(key, default)


def set_user_setting(key: str, value: str) -> None:
    USER_SETTINGS[key] = value
    parser = _load_ini()
    section = _GetIniSectionForKey(key)
    if not parser.has_section(section):
        parser.add_section(section)
    parser.set(section, key, _StringToUTF8(value))
    _save_ini(parser)


def load_all_settings(defaults: dict[str, str] | None = None) -> dict[str, str]:
    parser = _load_ini()
    loaded: dict[str, str] = {}

    keys = {
        "MeetingID",
        "MidweekDay",
        "MidweekTime",
        "WeekendDay",
        "WeekendTime",
        "Language",
        "SnapZoomSide",
        "KeyboardShortcut",
        "HostToolsValue",
        "ParticipantValue",
        "MuteAllValue",
        "MoreMeetingControlsValue",
        "YesValue",
        "UncheckedValue",
        "CurrentlyUnmutedValue",
        "UnmuteAudioValue",
        "StopVideoValue",
        "StartVideoValue",
        "ZoomSecurityUnmuteValue",
        "ZoomSecurityShareScreenValue",
    }

    for key in keys:
        section = _GetIniSectionForKey(key)
        raw = parser.get(section, key, fallback="")
        loaded[key] = _UTF8ToString(raw) if raw else ""

    # Backward compatibility migration from [General] for day fields.
    for key in ("MidweekDay", "WeekendDay"):
        if not loaded[key]:
            legacy = parser.get("General", key, fallback="")
            if legacy:
                loaded[key] = _UTF8ToString(legacy)
                if not parser.has_section("Meetings"):
                    parser.add_section("Meetings")
                parser.set("Meetings", key, legacy)

    if defaults:
        for k, v in defaults.items():
            if not loaded.get(k):
                loaded[k] = v

    USER_SETTINGS.clear()
    USER_SETTINGS.update(loaded)
    _save_ini(parser)
    return loaded
