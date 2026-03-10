"""UI backend abstraction replacing Includes/UIAutomation.au3."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class UIElement:
    name: str
    class_name: str = ""


def FindElementByClassName(class_name: str, scope: str | None = None, parent: UIElement | None = None) -> UIElement | None:
    return None


def _GetZoomWindow() -> UIElement | None:
    return _FindZoomWindowInternal()


def _FindZoomWindowInternal() -> UIElement | None:
    return None


def FocusZoomWindow(window: UIElement | None = None) -> bool:
    return window is not None or _GetZoomWindow() is not None


def _SnapZoomWindowToSide() -> bool:
    return False


def FindElementByPartialName(partial: str, control_types: list[str] | None = None, parent: UIElement | None = None) -> UIElement | None:
    return None
