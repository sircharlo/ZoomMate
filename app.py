"""Main loop equivalent to ZoomMate.au3."""

from __future__ import annotations

import argparse
import time
from datetime import datetime

from automation.meeting_automation import CheckMeetingWindow, RunAutomationScene
from pyzoommate.config import LoadMeetingConfig
from pyzoommate.globals import STATE
from pyzoommate.gui.settings_window import _InitDayLabelMaps
from pyzoommate.gui.tray import TrayEvent
from pyzoommate.i18n import _InitializeTranslations
from pyzoommate.user_settings import GetUserSetting


def _wday_autioit_compatible(now: datetime) -> int:
    """Map Python weekday to AutoIt @WDAY numbering (Sunday=1 ... Saturday=7)."""

    return (now.isoweekday() % 7) + 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ZoomMate")
    parser.add_argument("--scene", choices=["prepost", "prestart"], help="Run automation scene and exit")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    _InitializeTranslations()
    LoadMeetingConfig()
    _InitDayLabelMaps()

    if args.scene:
        return 0 if RunAutomationScene(args.scene) else 1

    sleep_time_ms = 5000
    while True:
        TrayEvent()

        today = _wday_autioit_compatible(datetime.now())
        if today != STATE.previous_run_day:
            STATE.previous_run_day = today
            STATE.flags.pre_post_settings_configured = False
            STATE.flags.during_meeting_settings_configured = False

        if today == int(GetUserSetting("MidweekDay", "3")):
            sleep_time_ms = CheckMeetingWindow(GetUserSetting("MidweekTime"))
        elif today == int(GetUserSetting("WeekendDay", "7")):
            sleep_time_ms = CheckMeetingWindow(GetUserSetting("WeekendTime"))
        else:
            STATE.flags.initial_notification_was_shown = True
            sleep_time_ms = 60000

        time.sleep(sleep_time_ms / 1000)


if __name__ == "__main__":
    raise SystemExit(main())
