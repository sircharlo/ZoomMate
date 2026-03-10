"""Unified automation backends for ZoomMate.

This module provides a UIA-first backend (pywinauto) plus an image-based
fallback backend (pyautogui) and a resilient facade that routes actions through
both while logging backend usage for every action.
"""

from __future__ import annotations

import logging
import random
import re
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Optional, Sequence

logger = logging.getLogger(__name__)


class AutomationBackend(ABC):
    """Automation backend contract."""

    @abstractmethod
    def find_window(
        self,
        class_name: Optional[str] = None,
        title_re: Optional[str] = None,
    ) -> Any:
        raise NotImplementedError

    @abstractmethod
    def find_by_partial_name(
        self,
        name: str,
        control_types: Optional[Sequence[str]] = None,
        scope: Any = None,
    ) -> Any:
        raise NotImplementedError

    @abstractmethod
    def click(self, element: Any, force: bool = False) -> bool:
        raise NotImplementedError

    @abstractmethod
    def focus_window(self, window: Any) -> bool:
        raise NotImplementedError

    @abstractmethod
    def get_bounding_rect(self, element: Any) -> Optional[tuple[int, int, int, int]]:
        raise NotImplementedError

    @abstractmethod
    def move_mouse_to_element_start(self, element: Any, click: bool = False) -> bool:
        raise NotImplementedError


class PywinautoBackend(AutomationBackend):
    """UIAutomation backend using pywinauto in UIA mode."""

    def __init__(self, default_timeout_s: float = 5.0) -> None:
        self.default_timeout_s = default_timeout_s
        self._desktop = None

    def _desktop_uia(self):
        if self._desktop is None:
            try:
                from pywinauto import Desktop
            except Exception as exc:  # pragma: no cover
                raise RuntimeError("pywinauto is required for PywinautoBackend") from exc
            self._desktop = Desktop(backend="uia")
        return self._desktop

    def find_window(self, class_name: Optional[str] = None, title_re: Optional[str] = None) -> Any:
        desktop = self._desktop_uia()
        kwargs: dict[str, Any] = {}
        if class_name:
            kwargs["class_name"] = class_name
        if title_re:
            kwargs["title_re"] = title_re

        try:
            window = desktop.window(**kwargs)
            if window.exists(timeout=self.default_timeout_s):
                logger.info("action=find_window backend=pywinauto class_name=%s title_re=%s", class_name, title_re)
                return window
        except Exception:
            pass
        logger.info("action=find_window backend=pywinauto result=not_found class_name=%s title_re=%s", class_name, title_re)
        return None

    def find_by_partial_name(
        self,
        name: str,
        control_types: Optional[Sequence[str]] = None,
        scope: Any = None,
    ) -> Any:
        parent = scope or self._desktop_uia()
        control_types = control_types or ("Button", "MenuItem")
        pattern = re.compile(re.escape(name), re.IGNORECASE)

        try:
            descendants = parent.descendants()
        except Exception:
            descendants = []

        for element in descendants:
            try:
                if element.element_info.control_type not in control_types:
                    continue
                candidate = element.element_info.name or ""
                if pattern.search(candidate):
                    logger.info(
                        "action=find_by_partial_name backend=pywinauto query=%r matched=%r",
                        name,
                        candidate,
                    )
                    return element
            except Exception:
                continue

        logger.info("action=find_by_partial_name backend=pywinauto result=not_found query=%r", name)
        return None

    def click(self, element: Any, force: bool = False) -> bool:
        started = time.monotonic()
        timeout = self.default_timeout_s

        def _timed_out() -> bool:
            return (time.monotonic() - started) > timeout

        if element is None:
            logger.info("action=click backend=pywinauto result=invalid_element")
            return False

        if force:
            ok = self._click_by_rect(element)
            logger.info("action=click backend=pywinauto strategy=force_mouse success=%s", ok)
            return ok

        strategies = (
            ("invoke", lambda e: self._call_if_present(e, "invoke")),
            ("legacy_default", lambda e: self._call_iface_if_present(e, "iface_legacy_iaccessible", "DoDefaultAction")),
            ("selection", lambda e: self._call_if_present(e, "select")),
            ("toggle", lambda e: self._call_if_present(e, "toggle")),
            ("mouse_rect", self._click_by_rect),
        )

        for strategy_name, strategy in strategies:
            if _timed_out():
                logger.info("action=click backend=pywinauto result=timeout")
                return False
            try:
                if strategy(element):
                    logger.info("action=click backend=pywinauto strategy=%s success=true", strategy_name)
                    return True
            except Exception:
                continue

        logger.info("action=click backend=pywinauto result=failed")
        return False

    def focus_window(self, window: Any) -> bool:
        if window is None:
            logger.info("action=focus_window backend=pywinauto result=invalid_window")
            return False
        try:
            window.set_focus()
            logger.info("action=focus_window backend=pywinauto success=true")
            return True
        except Exception:
            logger.info("action=focus_window backend=pywinauto success=false")
            return False

    def get_bounding_rect(self, element: Any) -> Optional[tuple[int, int, int, int]]:
        try:
            rect = element.rectangle()
            x, y = int(rect.left), int(rect.top)
            width, height = int(rect.width()), int(rect.height())
            logger.info("action=get_bounding_rect backend=pywinauto success=true")
            return x, y, width, height
        except Exception:
            logger.info("action=get_bounding_rect backend=pywinauto success=false")
            return None

    def move_mouse_to_element_start(self, element: Any, click: bool = False) -> bool:
        rect = self.get_bounding_rect(element)
        if not rect:
            return False
        x, y, _w, h = rect
        start_x = x + random.randint(5, 30)
        start_y = y + int(h / 2) + random.randint(-5, 5)

        try:
            from pywinauto import mouse

            mouse.move(coords=(start_x, start_y))
            time.sleep(0.2)
            if click:
                mouse.click(button="left", coords=(start_x, start_y))
            logger.info(
                "action=move_mouse_to_element_start backend=pywinauto click=%s success=true",
                click,
            )
            return True
        except Exception:
            logger.info(
                "action=move_mouse_to_element_start backend=pywinauto click=%s success=false",
                click,
            )
            return False

    @staticmethod
    def _call_if_present(element: Any, method_name: str) -> bool:
        method = getattr(element, method_name, None)
        if callable(method):
            method()
            return True
        return False

    @staticmethod
    def _call_iface_if_present(element: Any, iface_name: str, method_name: str) -> bool:
        iface = getattr(element, iface_name, None)
        method = getattr(iface, method_name, None)
        if callable(method):
            method()
            return True
        return False

    def _click_by_rect(self, element: Any) -> bool:
        rect = self.get_bounding_rect(element)
        if not rect:
            return False
        x, y, w, h = rect
        center_x = x + int(w / 2)
        center_y = y + int(h / 2)
        try:
            from pywinauto import mouse

            mouse.click(button="left", coords=(center_x, center_y))
            return True
        except Exception:
            return False


@dataclass
class ImageMatchElement:
    name: str
    image_path: Path
    center: Optional[tuple[int, int]] = None


class PyAutoGuiFallbackBackend(AutomationBackend):
    """Image-based backend for resilient fallback interactions."""

    def __init__(self, image_dir: Path | str = "images", confidence: float = 0.8) -> None:
        self.image_dir = Path(image_dir)
        self.confidence = confidence
        self._asset_paths = sorted(self.image_dir.glob("*.jpg"))

    def _pyautogui(self):
        try:
            import pyautogui
        except Exception as exc:  # pragma: no cover
            raise RuntimeError("pyautogui is required for PyAutoGuiFallbackBackend") from exc
        return pyautogui

    def find_window(self, class_name: Optional[str] = None, title_re: Optional[str] = None) -> Any:
        logger.info("action=find_window backend=pyautogui result=unsupported class_name=%s title_re=%s", class_name, title_re)
        return None

    def find_by_partial_name(
        self,
        name: str,
        control_types: Optional[Sequence[str]] = None,
        scope: Any = None,
    ) -> Any:
        _ = control_types, scope
        name_norm = name.lower().replace(" ", "_")
        candidates = [p for p in self._asset_paths if name_norm in p.stem.lower() or p.stem.lower() in name_norm]

        for image_path in candidates:
            center = self._locate_center(image_path)
            if center:
                logger.info(
                    "action=find_by_partial_name backend=pyautogui query=%r matched_image=%s",
                    name,
                    image_path.name,
                )
                return ImageMatchElement(name=name, image_path=image_path, center=center)

        logger.info("action=find_by_partial_name backend=pyautogui result=not_found query=%r", name)
        return None

    def click(self, element: Any, force: bool = False) -> bool:
        _ = force
        pyautogui = self._pyautogui()

        if isinstance(element, str):
            element = self.find_by_partial_name(element)

        if isinstance(element, ImageMatchElement):
            center = element.center or self._locate_center(element.image_path)
            if center:
                pyautogui.click(*center)
                logger.info("action=click backend=pyautogui image=%s success=true", element.image_path.name)
                return True

        logger.info("action=click backend=pyautogui success=false")
        return False

    def focus_window(self, window: Any) -> bool:
        logger.info("action=focus_window backend=pyautogui result=unsupported")
        return False

    def get_bounding_rect(self, element: Any) -> Optional[tuple[int, int, int, int]]:
        if isinstance(element, ImageMatchElement):
            pyautogui = self._pyautogui()
            region = pyautogui.locateOnScreen(str(element.image_path), confidence=self.confidence)
            if region:
                logger.info("action=get_bounding_rect backend=pyautogui success=true")
                return int(region.left), int(region.top), int(region.width), int(region.height)
        logger.info("action=get_bounding_rect backend=pyautogui success=false")
        return None

    def move_mouse_to_element_start(self, element: Any, click: bool = False) -> bool:
        pyautogui = self._pyautogui()
        rect = self.get_bounding_rect(element)
        if not rect:
            logger.info("action=move_mouse_to_element_start backend=pyautogui success=false")
            return False

        x, y, _w, h = rect
        start_x = x + random.randint(5, 30)
        start_y = y + int(h / 2) + random.randint(-5, 5)
        pyautogui.moveTo(start_x, start_y)
        if click:
            pyautogui.click(start_x, start_y)
        logger.info("action=move_mouse_to_element_start backend=pyautogui click=%s success=true", click)
        return True

    def _locate_center(self, image_path: Path) -> Optional[tuple[int, int]]:
        pyautogui = self._pyautogui()
        try:
            center = pyautogui.locateCenterOnScreen(str(image_path), confidence=self.confidence)
            if center:
                return int(center.x), int(center.y)
        except TypeError:
            center = pyautogui.locateCenterOnScreen(str(image_path))
            if center:
                return int(center.x), int(center.y)
        return None


class ResilientAutomationBackend(AutomationBackend):
    """Facade that routes through UIA first then image fallback."""

    def __init__(
        self,
        primary: Optional[AutomationBackend] = None,
        fallback: Optional[AutomationBackend] = None,
    ) -> None:
        self.primary = primary or PywinautoBackend()
        self.fallback = fallback or PyAutoGuiFallbackBackend()

    def find_window(self, class_name: Optional[str] = None, title_re: Optional[str] = None) -> Any:
        result = self.primary.find_window(class_name=class_name, title_re=title_re)
        if result is not None:
            logger.info("action=find_window route=primary")
            return result
        logger.info("action=find_window route=fallback")
        return self.fallback.find_window(class_name=class_name, title_re=title_re)

    def find_by_partial_name(
        self,
        name: str,
        control_types: Optional[Sequence[str]] = None,
        scope: Any = None,
    ) -> Any:
        result = self.primary.find_by_partial_name(name, control_types=control_types, scope=scope)
        if result is not None:
            logger.info("action=find_by_partial_name route=primary query=%r", name)
            return result
        logger.info("action=find_by_partial_name route=fallback query=%r", name)
        return self.fallback.find_by_partial_name(name, control_types=control_types, scope=scope)

    def click(self, element: Any, force: bool = False) -> bool:
        if self.primary.click(element, force=force):
            logger.info("action=click route=primary success=true")
            return True
        logger.info("action=click route=fallback_attempt")
        ok = self.fallback.click(element, force=force)
        logger.info("action=click route=fallback success=%s", ok)
        return ok

    def focus_window(self, window: Any) -> bool:
        if self.primary.focus_window(window):
            logger.info("action=focus_window route=primary success=true")
            return True
        ok = self.fallback.focus_window(window)
        logger.info("action=focus_window route=fallback success=%s", ok)
        return ok

    def get_bounding_rect(self, element: Any) -> Optional[tuple[int, int, int, int]]:
        rect = self.primary.get_bounding_rect(element)
        if rect:
            logger.info("action=get_bounding_rect route=primary success=true")
            return rect
        rect = self.fallback.get_bounding_rect(element)
        logger.info("action=get_bounding_rect route=fallback success=%s", bool(rect))
        return rect

    def move_mouse_to_element_start(self, element: Any, click: bool = False) -> bool:
        if self.primary.move_mouse_to_element_start(element, click=click):
            logger.info("action=move_mouse_to_element_start route=primary success=true")
            return True
        ok = self.fallback.move_mouse_to_element_start(element, click=click)
        logger.info("action=move_mouse_to_element_start route=fallback success=%s", ok)
        return ok


__all__ = [
    "AutomationBackend",
    "ImageMatchElement",
    "PyAutoGuiFallbackBackend",
    "PywinautoBackend",
    "ResilientAutomationBackend",
]
