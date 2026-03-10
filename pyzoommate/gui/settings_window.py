"""Settings helpers and validation for the migrated app."""

from __future__ import annotations

from ..config import _IsValidKeyboardShortcut, _IsValidMeetingID, _IsValidTime
from ..i18n import t
from ..user_settings import get_user_setting, set_user_setting

DAY_LABEL_MAP: dict[str, int] = {}
REVERSE_DAY_LABEL_MAP: dict[int, str] = {}


def _InitDayLabelMaps() -> None:
    DAY_LABEL_MAP.clear()
    REVERSE_DAY_LABEL_MAP.clear()
    for day_num in range(1, 8):
        label = t(f"DAY_{day_num}")
        DAY_LABEL_MAP[label] = day_num
        REVERSE_DAY_LABEL_MAP[day_num] = label


def validate_current_config() -> list[str]:
    errors: list[str] = []
    if not _IsValidMeetingID(get_user_setting("MeetingID")):
        errors.append(t("ERROR_MEETING_ID_FORMAT"))
    if not _IsValidTime(get_user_setting("MidweekTime")):
        errors.append("MidweekTime: " + t("ERROR_TIME_FORMAT"))
    if not _IsValidTime(get_user_setting("WeekendTime")):
        errors.append("WeekendTime: " + t("ERROR_TIME_FORMAT"))
    if not _IsValidKeyboardShortcut(get_user_setting("KeyboardShortcut")):
        errors.append(t("ERROR_KEYBOARD_SHORTCUT_FORMAT"))
    return errors


def ShowConfigGUI() -> None:
    # Deliberately minimal non-blocking implementation for service-friendly operation.
    # Configuration is edited by INI and validated on launch.
    return


def SaveFieldImmediately(key: str, value: str) -> None:
    set_user_setting(key, value)
