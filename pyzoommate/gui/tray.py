"""Tray event shim with explicit no-op logging for debuggability."""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


def _InitTray() -> None:
    logger.info("tray_init no-op")


def TrayEvent() -> None:
    logger.debug("tray_event tick")
