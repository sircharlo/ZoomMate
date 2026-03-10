"""Meeting automation logic ported from Includes/MeetingAutomation.au3."""

from __future__ import annotations

import time
import webbrowser
from datetime import datetime

from pyzoommate.globals import STATE
from pyzoommate.user_settings import GetUserSetting

PRE_MEETING_MINUTES = 60
MEETING_START_WARNING_MINUTES = 1


def _GetZoomWindow() -> object | None:
    """Best-effort Zoom window resolver placeholder."""

    return object()


def FocusZoomWindow() -> bool:
    """Best-effort focus placeholder."""

    return _GetZoomWindow() is not None


def _SnapZoomWindowToSide() -> bool:
    """Best-effort snap placeholder."""

    return True


def SetSecuritySetting(setting_name: str, desired: bool) -> bool:
    """Placeholder security setter hook."""

    _ = (setting_name, desired)
    return True


def MuteAll() -> bool:
    """Placeholder mute-all hook."""

    return True


def ToggleFeed(feed_type: str, desired_state: bool) -> bool:
    """Placeholder feed toggle hook."""

    _ = (feed_type, desired_state)
    return True


def PulseSpotlightHostVideo(duration_ms: int = 5000) -> bool:
    """Placeholder spotlight hook."""

    time.sleep(duration_ms / 1000)
    return True


def EnsureGalleryView() -> bool:
    """Placeholder gallery-view hook."""

    return True


def _OpenParticipantsPanel() -> bool:
    """Placeholder participants-panel hook."""

    return True


def _LaunchZoom() -> bool:
    meeting_id = GetUserSetting("MeetingID")
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

    SetSecuritySetting(GetUserSetting("ZoomSecurityUnmuteValue"), True)
    SetSecuritySetting(GetUserSetting("ZoomSecurityShareScreenValue"), False)
    ToggleFeed("Audio", False)
    ToggleFeed("Video", False)
    EnsureGalleryView()


def _SetDuringMeetingSettings() -> None:
    time.sleep(3)
    if not FocusZoomWindow():
        return

    SetSecuritySetting(GetUserSetting("ZoomSecurityUnmuteValue"), False)
    SetSecuritySetting(GetUserSetting("ZoomSecurityShareScreenValue"), False)
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
        if minutes_ago <= 120:
            next_check_delay = 30000
        else:
            next_check_delay = 60000

    else:
        minutes_left = meeting_min - now_min
        if minutes_left > 60:
            next_check_delay = 60000
        else:
            next_check_delay = 5000

    STATE.flags.initial_notification_was_shown = True
    return next_check_delay
