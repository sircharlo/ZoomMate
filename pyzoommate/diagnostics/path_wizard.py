"""Path and UI diagnostics helpers."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from ..automation.zoom_operations import (
    FocusZoomWindow,
    GetMoreMenu,
    _FindHostToolsContainer,
    _GetZoomWindow,
    _OpenHostTools,
)
from ..automation.zoom_operations import _backend as _AUTOMATION_BACKEND
from ..user_settings import get_user_setting, set_user_setting

_LAST_PATH_ERROR = ""

DIAGNOSTICS_FILE = Path("zoom_ui_diagnostics.txt")


def _SetPathError(message: str) -> None:
    global _LAST_PATH_ERROR
    _LAST_PATH_ERROR = message


def _GetPathError() -> str:
    return _LAST_PATH_ERROR


def EnsureZoomMainWindow() -> bool:
    _SetPathError("")
    zoom_window = _GetZoomWindow()
    if zoom_window is None:
        _SetPathError("Zoom main window not found.")
        return False
    if not FocusZoomWindow():
        _SetPathError("Unable to focus Zoom main window.")
        return False
    return True


def EnsureMoreMenuVisible() -> bool:
    if not EnsureZoomMainWindow():
        return False
    if GetMoreMenu() is None:
        _SetPathError("Unable to open Zoom More menu.")
        return False
    return True


def EnsureHostToolsVisible() -> bool:
    if not EnsureZoomMainWindow():
        return False
    if not _OpenHostTools():
        _SetPathError("Unable to open Host Tools panel/menu.")
        return False
    return True


def EnsureHostToolsParticipantsScope() -> bool:
    if not EnsureHostToolsVisible():
        return False

    host_tools = _FindHostToolsContainer()
    if host_tools is None:
        _SetPathError("Host Tools container was not found after opening Host Tools.")
        return False

    participants = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("ParticipantValue"), scope=host_tools)
    if participants is not None:
        _AUTOMATION_BACKEND.click(participants, force=True)
    return True


def ResolveSecurityToggle(setting: str):
    if not setting.strip():
        _SetPathError("Security toggle name is empty.")
        return None

    if not EnsureHostToolsParticipantsScope():
        return None

    host_tools = _FindHostToolsContainer()
    if host_tools is None:
        return None

    control_types = ("CheckBox", "Button", "MenuItem", "Text")
    element = _AUTOMATION_BACKEND.find_by_partial_name(setting, control_types=control_types, scope=host_tools)
    if element is None:
        zoom_window = _GetZoomWindow()
        if zoom_window is not None:
            element = _AUTOMATION_BACKEND.find_by_partial_name(setting, control_types=control_types, scope=zoom_window)
    if element is None:
        _SetPathError(f"Security toggle not found: {setting}")
        return None
    return element


def EnsureSecurityToggleVisible(setting: str) -> bool:
    return ResolveSecurityToggle(setting) is not None


def RunUIDiagnostics() -> Path:
    zoom_window_present = _GetZoomWindow() is not None
    host_tools_visible = EnsureHostToolsVisible()
    more_menu_visible = EnsureMoreMenuVisible()

    rows = [
        f"Timestamp: {datetime.now().isoformat()}",
        f"ZoomWindowVisible={zoom_window_present}",
        f"MoreMenuVisible={more_menu_visible}",
        f"HostToolsVisible={host_tools_visible}",
        f"HostToolsValue={get_user_setting('HostToolsValue')}",
        f"MoreMeetingControlsValue={get_user_setting('MoreMeetingControlsValue')}",
        f"ParticipantValue={get_user_setting('ParticipantValue')}",
        f"LastPathError={_GetPathError()}",
    ]
    DIAGNOSTICS_FILE.write_text("\n".join(rows) + "\n", encoding="utf-8")
    return DIAGNOSTICS_FILE


def RunPathCaptureWizard(more_label: str, host_tools_label: str, participants_label: str) -> None:
    set_user_setting("MoreMeetingControlsValue", more_label)
    set_user_setting("HostToolsValue", host_tools_label)
    set_user_setting("ParticipantValue", participants_label)
