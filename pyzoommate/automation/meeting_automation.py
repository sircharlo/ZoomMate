"""Meeting automation orchestration replacing Includes/MeetingAutomation.au3."""

from __future__ import annotations

import logging
import time
import webbrowser
from datetime import datetime

from ..diagnostics.path_wizard import ResolveSecurityToggle
from ..globals import STATE
from ..user_settings import get_user_setting
from .zoom_operations import FocusZoomWindow, _GetZoomWindow, _OpenParticipantsPanel
from .zoom_operations import _backend as _AUTOMATION_BACKEND

logger = logging.getLogger(__name__)

PRE_MEETING_MINUTES = 60
MEETING_START_WARNING_MINUTES = 1


def _SnapZoomWindowToSide() -> bool:
    side = get_user_setting("SnapZoomSide", "Disabled").strip().lower()
    if side not in {"left", "right"}:
        return True

    if not FocusZoomWindow():
        return False

    try:
        import pyautogui

        pyautogui.hotkey("win", side)
        return True
    except Exception:
        return False


def SetSecuritySetting(setting_name: str, desired: bool) -> bool:
    logger.info("action=set_security setting=%s desired=%s", setting_name, desired)
    setting = ResolveSecurityToggle(setting_name)
    if setting is None:
        return False

    is_enabled: bool | None = None
    try:
        toggle_iface = getattr(setting, "iface_toggle", None)
        if toggle_iface is not None and hasattr(toggle_iface, "CurrentToggleState"):
            is_enabled = int(toggle_iface.CurrentToggleState) == 1
    except Exception:
        is_enabled = None

    if is_enabled is None:
        label = getattr(getattr(setting, "element_info", None), "name", "") or ""
        unchecked_value = get_user_setting("UncheckedValue").strip().lower()
        if unchecked_value:
            is_enabled = unchecked_value not in label.lower()

    if is_enabled is not None and is_enabled == desired:
        return True

    if not _AUTOMATION_BACKEND.click(setting, force=True):
        return False
    time.sleep(0.25)
    return True


def MuteAll() -> bool:
    logger.info("action=mute_all")
    if not _OpenParticipantsPanel():
        return False

    zoom_window = _GetZoomWindow()
    if zoom_window is None:
        return False

    mute_all = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("MuteAllValue"), scope=zoom_window)
    if mute_all is None or not _AUTOMATION_BACKEND.click(mute_all):
        return False

    dialog = _AUTOMATION_BACKEND.find_window(class_name="zChangeNameWndClass")
    if dialog is None:
        return True
    yes_button = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("YesValue"), scope=dialog)
    return yes_button is not None and _AUTOMATION_BACKEND.click(yes_button)


def ToggleFeed(feed_type: str, desired_state: bool) -> bool:
    logger.info("action=toggle_feed feed=%s desired=%s", feed_type, desired_state)
    zoom_window = _GetZoomWindow()
    if zoom_window is None:
        return False

    _AUTOMATION_BACKEND.move_mouse_to_element_start(zoom_window, click=False)

    feed = feed_type.strip().lower()
    if feed == "video":
        enabled_button = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("StopVideoValue"), scope=zoom_window)
        disabled_button = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("StartVideoValue"), scope=zoom_window)
    elif feed == "audio":
        enabled_button = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("CurrentlyUnmutedValue"), scope=zoom_window)
        disabled_button = _AUTOMATION_BACKEND.find_by_partial_name(get_user_setting("UnmuteAudioValue"), scope=zoom_window)
    else:
        return False

    currently_enabled = enabled_button is not None
    if currently_enabled == desired_state:
        return True

    target = enabled_button if currently_enabled else disabled_button
    if target is None:
        return False
    return _AUTOMATION_BACKEND.click(target)


def PulseSpotlightHostVideo(duration_ms: int = 5000) -> bool:
    logger.info("action=pulse_spotlight duration_ms=%s", duration_ms)
    if not _OpenParticipantsPanel():
        time.sleep(duration_ms / 1000)
        return False

    zoom_window = _GetZoomWindow()
    if zoom_window is None:
        time.sleep(duration_ms / 1000)
        return False

    spotlight = _AUTOMATION_BACKEND.find_by_partial_name("spotlight", scope=zoom_window)
    if spotlight is None or not _AUTOMATION_BACKEND.click(spotlight, force=True):
        time.sleep(duration_ms / 1000)
        return False

    time.sleep(duration_ms / 1000)
    remove_spotlight = _AUTOMATION_BACKEND.find_by_partial_name("remove spotlight", scope=zoom_window)
    if remove_spotlight is not None:
        _AUTOMATION_BACKEND.click(remove_spotlight, force=True)
    return True


def EnsureGalleryView() -> bool:
    logger.info("action=ensure_gallery_view")
    if not FocusZoomWindow():
        return False
    try:
        import pyautogui

        pyautogui.hotkey("alt", "f2")
        time.sleep(0.3)
        return True
    except Exception:
        return False


def _LaunchZoom() -> bool:
    meeting_id = get_user_setting("MeetingID")
    if not meeting_id:
        return False

    zoom_url = f"zoommtg://zoom.us/join?confno={meeting_id}"
    webbrowser.open(zoom_url)
    time.sleep(10)

    resolved_window = _GetZoomWindow()
    if resolved_window is None:
        return False

    _SnapZoomWindowToSide()
    return _GetZoomWindow() is not None


def _SetPreAndPostMeetingSettings() -> None:
    time.sleep(3)
    if not FocusZoomWindow():
        return

    SetSecuritySetting(get_user_setting("ZoomSecurityUnmuteValue"), True)
    SetSecuritySetting(get_user_setting("ZoomSecurityShareScreenValue"), False)
    ToggleFeed("Audio", False)
    ToggleFeed("Video", False)
    EnsureGalleryView()


def _SetDuringMeetingSettings() -> None:
    time.sleep(3)
    if not FocusZoomWindow():
        return

    SetSecuritySetting(get_user_setting("ZoomSecurityUnmuteValue"), False)
    SetSecuritySetting(get_user_setting("ZoomSecurityShareScreenValue"), False)
    MuteAll()
    ToggleFeed("Audio", True)
    ToggleFeed("Video", True)
    PulseSpotlightHostVideo(5000)
    EnsureGalleryView()
    _OpenParticipantsPanel()
    _SnapZoomWindowToSide()


def RunAutomationScene(scene: str) -> bool:
    normalized_scene = scene.strip().lower()

    if normalized_scene == "prepost":
        if _GetZoomWindow() is None:
            return False
        _SetPreAndPostMeetingSettings()
        return True

    if normalized_scene == "prestart":
        if _GetZoomWindow() is None:
            return False
        _SetDuringMeetingSettings()
        return True

    return False


def CheckMeetingWindow(meeting_time: str) -> int:
    if not meeting_time:
        return 60000

    next_check_delay = 5000

    hour_s, minute_s = meeting_time.split(":", 1)
    hour = int(hour_s)
    minute = int(minute_s)

    now = datetime.now()
    now_min = now.hour * 60 + now.minute
    meeting_min = hour * 60 + minute

    if (meeting_min - PRE_MEETING_MINUTES) <= now_min < (meeting_min - MEETING_START_WARNING_MINUTES):
        if not STATE.flags.pre_post_settings_configured:
            zoom_launched = _LaunchZoom()
            if zoom_launched:
                _SetPreAndPostMeetingSettings()
                STATE.flags.pre_post_settings_configured = True
        next_check_delay = 5000

    elif now_min == (meeting_min - MEETING_START_WARNING_MINUTES):
        if not STATE.flags.during_meeting_settings_configured:
            resolved_window = _GetZoomWindow()
            if resolved_window is None:
                return 1000
            _SetDuringMeetingSettings()
            STATE.flags.during_meeting_settings_configured = True
        next_check_delay = 5000

    elif now_min >= meeting_min:
        minutes_ago = now_min - meeting_min
        next_check_delay = 30000 if minutes_ago <= 120 else 60000

    else:
        minutes_left = meeting_min - now_min
        next_check_delay = 60000 if minutes_left > 60 else 5000

    STATE.flags.initial_notification_was_shown = True
    return next_check_delay
