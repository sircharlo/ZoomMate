"""State containers replacing Includes/Globals.au3."""

from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class RuntimeFlags:
    """Runtime flags that were global variables in AutoIt."""

    pre_post_settings_configured: bool = False
    during_meeting_settings_configured: bool = False
    initial_notification_was_shown: bool = False


@dataclass
class AppState:
    """Top-level mutable state container for the app runtime."""

    script_dir: Path = field(default_factory=lambda: Path.cwd())
    previous_run_day: int | None = None
    sleep_time_ms: int = 5000
    flags: RuntimeFlags = field(default_factory=RuntimeFlags)


STATE = AppState()
