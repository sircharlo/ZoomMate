"""Configuration helpers replacing Includes/Config.au3."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .i18n import _InitializeTranslations
from .user_settings import USER_SETTINGS, load_all_settings

_MEETING_ID_PATTERN = re.compile(r"^\d{9,11}$")
_TIME_PATTERN = re.compile(r"^(\d{1,2}):(\d{2})$")
_SHORTCUT_PATTERN = re.compile(r"^[\^\!\+\#]*[a-zA-Z0-9]$")


@dataclass
class MeetingConfig:
    midweek_day: int
    midweek_time: str
    weekend_day: int
    weekend_time: str
    meeting_id: str


def _IsValidMeetingID(value: str) -> bool:
    return bool(_MEETING_ID_PATTERN.fullmatch(value.strip()))


def _IsValidTime(value: str) -> bool:
    value = value.strip()
    match = _TIME_PATTERN.fullmatch(value)
    if not match:
        return False
    hour = int(match.group(1))
    minute = int(match.group(2))
    return 0 <= hour <= 23 and 0 <= minute <= 59


def _IsValidKeyboardShortcut(value: str) -> bool:
    value = value.strip()
    if not value:
        return True
    if not _SHORTCUT_PATTERN.fullmatch(value):
        return False
    return any(symbol in value for symbol in "^!+#")


def _default_settings() -> dict[str, str]:
    return {
        "Language": "en",
        "SnapZoomSide": "Disabled",
        "MidweekDay": "3",
        "MidweekTime": "19:00",
        "WeekendDay": "7",
        "WeekendTime": "10:00",
        "HostToolsValue": "Host tools",
        "ParticipantValue": "Participant",
        "MuteAllValue": "Mute All",
        "MoreMeetingControlsValue": "More meeting controls",
        "YesValue": "Yes",
        "UncheckedValue": "Unchecked",
        "CurrentlyUnmutedValue": "Currently unmuted",
        "UnmuteAudioValue": "Unmute my audio",
        "StopVideoValue": "Stop my video",
        "StartVideoValue": "Start my video",
        "ZoomSecurityUnmuteValue": "Unmute themselves",
        "ZoomSecurityShareScreenValue": "Share screen",
    }


def LoadMeetingConfig() -> MeetingConfig:
    loaded = load_all_settings(defaults=_default_settings())
    _InitializeTranslations(loaded.get("Language", "en"))

    return MeetingConfig(
        midweek_day=int(loaded.get("MidweekDay", "3")),
        midweek_time=loaded.get("MidweekTime", "19:00"),
        weekend_day=int(loaded.get("WeekendDay", "7")),
        weekend_time=loaded.get("WeekendTime", "10:00"),
        meeting_id=loaded.get("MeetingID", ""),
    )


__all__ = [
    "LoadMeetingConfig",
    "MeetingConfig",
    "USER_SETTINGS",
    "_IsValidKeyboardShortcut",
    "_IsValidMeetingID",
    "_IsValidTime",
]
