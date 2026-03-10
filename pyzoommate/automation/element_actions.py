"""Element interaction helpers replacing Includes/ElementActions.au3."""

from __future__ import annotations

import time
from typing import Any

from .ui_backend import ResilientAutomationBackend

_backend = ResilientAutomationBackend()

CLICK_TIMEOUT_MS = 5000
HOVER_DEFAULT_MS = 1000


def _ClickElement(element: Any | None, ForceClick: bool = False, BoundingRectangle: bool = False, iTimeoutMs: int = CLICK_TIMEOUT_MS) -> bool:
    _ = BoundingRectangle
    if element is None:
        return False
    start = time.monotonic()
    while time.monotonic() - start <= (iTimeoutMs / 1000):
        if _backend.click(element, force=ForceClick):
            return True
        time.sleep(0.1)
    return False


def ClickByBoundingRectangle(element: Any | None) -> bool:
    if element is None:
        return False
    rect = _backend.get_bounding_rect(element)
    return bool(rect) and _backend.click(element, force=True)


def GetElementName(element: Any | None) -> str:
    if element is None:
        return ""
    return getattr(getattr(element, "element_info", None), "name", "") or getattr(element, "name", "")


def _HoverElement(element: Any | None, iHoverTime: int = HOVER_DEFAULT_MS, SlightOffset: bool = False) -> bool:
    _ = SlightOffset
    if element is None:
        return False
    ok = _backend.move_mouse_to_element_start(element, click=False)
    if ok:
        time.sleep(iHoverTime / 1000)
    return ok
