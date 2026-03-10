"""Entrypoint replacing ZoomMate.au3."""

from __future__ import annotations

import argparse
import time

from .automation.meeting_automation import CheckMeetingWindow, RunAutomationScene
from .config import LoadMeetingConfig
from .gui.settings_window import _InitDayLabelMaps
from .gui.tray import TrayEvent
from .i18n import _InitializeTranslations


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="pyzoommate")
    parser.add_argument("--scene", help="Run a specific automation scene and exit.")
    parser.add_argument("--once", action="store_true", help="Run one polling iteration only.")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    _InitializeTranslations()
    config = LoadMeetingConfig()
    _InitDayLabelMaps()

    if args.scene:
        return 0 if RunAutomationScene(args.scene) else 1

    while True:
        TrayEvent()
        sleep_ms = CheckMeetingWindow(config.midweek_time)
        if args.once:
            break
        time.sleep(sleep_ms / 1000)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
