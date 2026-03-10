"""Configuration helpers replacing Includes/Config.au3."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .user_settings import USER_SETTINGS, get_user_setting

_MEETING_ID_PATTERN = re.compile(r"^\d{9,12}$")
_TIME_PATTERN = re.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d$")
_SHORTCUT_PATTERN = re.compile(r"^[A-Za-z0-9+\- ]+$")


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
    return bool(_TIME_PATTERN.fullmatch(value.strip()))


def _IsValidKeyboardShortcut(value: str) -> bool:
    return bool(_SHORTCUT_PATTERN.fullmatch(value.strip())) and "+" in value


def LoadMeetingConfig() -> MeetingConfig:
    """Load core meeting configuration from user settings."""

    return MeetingConfig(
        midweek_day=int(get_user_setting("MidweekDay", "3")),
        midweek_time=get_user_setting("MidweekTime", "19:00"),
        weekend_day=int(get_user_setting("WeekendDay", "7")),
        weekend_time=get_user_setting("WeekendTime", "10:00"),
        meeting_id=get_user_setting("MeetingID", ""),
    )


__all__ = [
    "LoadMeetingConfig",
    "MeetingConfig",
    "USER_SETTINGS",
    "_IsValidKeyboardShortcut",
    "_IsValidMeetingID",
    "_IsValidTime",
]
