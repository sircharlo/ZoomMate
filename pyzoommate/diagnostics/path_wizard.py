"""Path and UI diagnostics helpers."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from ..user_settings import get_user_setting, set_user_setting

_LAST_PATH_ERROR = ""

DIAGNOSTICS_FILE = Path("zoom_ui_diagnostics.txt")


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


def RunUIDiagnostics() -> Path:
    rows = [
        f"Timestamp: {datetime.now().isoformat()}",
        f"HostToolsValue={get_user_setting('HostToolsValue')}",
        f"MoreMeetingControlsValue={get_user_setting('MoreMeetingControlsValue')}",
        f"ParticipantValue={get_user_setting('ParticipantValue')}",
    ]
    DIAGNOSTICS_FILE.write_text("\n".join(rows) + "\n", encoding="utf-8")
    return DIAGNOSTICS_FILE


def RunPathCaptureWizard(more_label: str, host_tools_label: str, participants_label: str) -> None:
    set_user_setting("MoreMeetingControlsValue", more_label)
    set_user_setting("HostToolsValue", host_tools_label)
    set_user_setting("ParticipantValue", participants_label)
