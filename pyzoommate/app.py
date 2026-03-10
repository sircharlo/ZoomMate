"""Entrypoint replacing ZoomMate.au3."""

from __future__ import annotations

import argparse
import logging
import time
from datetime import datetime

from .automation.meeting_automation import CheckMeetingWindow, RunAutomationScene
from .config import LoadMeetingConfig
from .globals import STATE
from .gui.settings_window import _InitDayLabelMaps
from .gui.tray import TrayEvent

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)


def _wday_autoit_compatible(now: datetime) -> int:
    return (now.isoweekday() % 7) + 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="pyzoommate")
    parser.add_argument("--scene", help="Run a specific automation scene and exit.")
    parser.add_argument("--once", action="store_true", help="Run one polling iteration only.")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    config = LoadMeetingConfig()
    _InitDayLabelMaps()

    if args.scene:
        return 0 if RunAutomationScene(args.scene) else 1

    while True:
        TrayEvent()

        today = _wday_autoit_compatible(datetime.now())
        if today != STATE.previous_run_day:
            STATE.previous_run_day = today
            STATE.flags.pre_post_settings_configured = False
            STATE.flags.during_meeting_settings_configured = False

        if today == config.midweek_day:
            sleep_ms = CheckMeetingWindow(config.midweek_time)
        elif today == config.weekend_day:
            sleep_ms = CheckMeetingWindow(config.weekend_time)
        else:
            sleep_ms = 60000

        if args.once:
            break
        time.sleep(sleep_ms / 1000)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
