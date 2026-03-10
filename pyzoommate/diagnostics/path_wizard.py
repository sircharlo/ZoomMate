"""Path wizard placeholder replacing Includes/ZoomPathEngine.au3."""

from __future__ import annotations

_LAST_PATH_ERROR = ""


def _SetPathError(message: str) -> None:
    global _LAST_PATH_ERROR
    _LAST_PATH_ERROR = message


def _GetPathError() -> str:
    return _LAST_PATH_ERROR


def EnsureZoomMainWindow() -> bool:
    return True


def EnsureMoreMenuVisible() -> bool:
    return True


def EnsureHostToolsVisible() -> bool:
    return True


def EnsureHostToolsParticipantsScope() -> bool:
    return True


def EnsureSecurityToggleVisible(setting: str) -> bool:
    return bool(setting)
