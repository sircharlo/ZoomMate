"""Settings window placeholders replacing GUI config helpers."""

from __future__ import annotations

from ..user_settings import set_user_setting

DAY_LABEL_MAP: dict[str, int] = {}


def _InitDayLabelMaps() -> None:
    DAY_LABEL_MAP.update(
        {
            "Sunday": 1,
            "Monday": 2,
            "Tuesday": 3,
            "Wednesday": 4,
            "Thursday": 5,
            "Friday": 6,
            "Saturday": 7,
        }
    )


def ShowConfigGUI() -> None:
    """Placeholder for future desktop GUI implementation."""


def SaveFieldImmediately(key: str, value: str) -> None:
    set_user_setting(key, value)
