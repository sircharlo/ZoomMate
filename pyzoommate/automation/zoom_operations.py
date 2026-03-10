"""Zoom-specific UI operations replacing Includes/ZoomOperations.au3."""

from __future__ import annotations

from .ui_backend import ResilientAutomationBackend
from ..user_settings import get_user_setting

ZOOM_WINDOW_CLASS = "ConfMultiTabContentWndClass"
_backend = ResilientAutomationBackend()


def _GetZoomWindow():
    return _backend.find_window(class_name=ZOOM_WINDOW_CLASS)


def FocusZoomWindow() -> bool:
    win = _GetZoomWindow()
    return bool(win) and _backend.focus_window(win)


def _FindHostToolsContainer():
    zoom_window = _GetZoomWindow()
    if not zoom_window:
        return None
    return _backend.find_by_partial_name(get_user_setting("HostToolsValue"), scope=zoom_window)


def _OpenHostTools() -> bool:
    zoom_window = _GetZoomWindow()
    if not zoom_window:
        return False
    host_tools = _backend.find_by_partial_name(get_user_setting("HostToolsValue"), scope=zoom_window)
    if host_tools:
        return _backend.click(host_tools, force=True)

    more_menu = GetMoreMenu()
    if not more_menu:
        return False
    host_tools = _backend.find_by_partial_name(get_user_setting("HostToolsValue"), scope=more_menu)
    return bool(host_tools) and _backend.click(host_tools, force=True)


def _CloseHostTools() -> bool:
    win = _GetZoomWindow()
    return bool(win) and _backend.move_mouse_to_element_start(win, click=True)


def _FindMoreMenuInternal():
    zoom_window = _GetZoomWindow()
    if not zoom_window:
        return None
    return _backend.find_by_partial_name(get_user_setting("MoreMeetingControlsValue"), scope=zoom_window)


def GetMoreMenu():
    more = _FindMoreMenuInternal()
    if more:
        _backend.click(more, force=True)
        return _GetZoomWindow()
    return None


def _OpenParticipantsPanel() -> bool:
    zoom_window = _GetZoomWindow()
    if not zoom_window:
        return False

    participants = _backend.find_by_partial_name(get_user_setting("ParticipantValue"), scope=zoom_window)
    if participants:
        return _backend.click(participants)

    more_menu = GetMoreMenu()
    if not more_menu:
        return False
    participants = _backend.find_by_partial_name(get_user_setting("ParticipantValue"), scope=more_menu)
    return bool(participants) and _backend.click(participants)


def _FindParticipantsPanelInternal():
    zoom_window = _GetZoomWindow()
    if not zoom_window:
        return None
    return _backend.find_by_partial_name(get_user_setting("ParticipantValue"), scope=zoom_window)
