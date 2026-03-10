"""Element interaction helpers replacing Includes/ElementActions.au3."""

from __future__ import annotations

from .ui_backend import UIElement


CLICK_TIMEOUT_MS = 1000
HOVER_DEFAULT_MS = 250


def _ClickElement(element: UIElement | None, ForceClick: bool = False, BoundingRectangle: bool = False, iTimeoutMs: int = CLICK_TIMEOUT_MS) -> bool:
    return element is not None


def ClickByBoundingRectangle(element: UIElement | None) -> bool:
    return element is not None


def GetElementName(element: UIElement | None) -> str:
    return "" if element is None else element.name


def _HoverElement(element: UIElement | None, iHoverTime: int = HOVER_DEFAULT_MS, SlightOffset: bool = False) -> bool:
    return element is not None
