"""Meeting automation orchestration replacing Includes/MeetingAutomation.au3."""

from __future__ import annotations

from datetime import datetime

from ..globals import STATE


def _LaunchZoom() -> bool:
    return True


def _SetPreAndPostMeetingSettings() -> bool:
    STATE.flags.pre_post_settings_configured = True
    return True


def _SetDuringMeetingSettings() -> bool:
    STATE.flags.during_meeting_settings_configured = True
    return True


def RunAutomationScene(scene: str) -> bool:
    normalized = scene.strip().lower()
    if normalized == "prepost":
        return _SetPreAndPostMeetingSettings()
    if normalized in {"prestart", "during"}:
        return _SetDuringMeetingSettings()
    return False


def CheckMeetingWindow(meeting_time: str) -> int:
    """Return a poll/sleep interval in milliseconds."""

    now = datetime.now().strftime("%H:%M")
    if now == meeting_time:
        return 1000
    return 5000
