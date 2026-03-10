"""Automation helpers for pyzoommate."""

from .ui_backend import (
    AutomationBackend,
    ImageMatchElement,
    PyAutoGuiFallbackBackend,
    PywinautoBackend,
    ResilientAutomationBackend,
)

__all__ = [
    "AutomationBackend",
    "ImageMatchElement",
    "PyAutoGuiFallbackBackend",
    "PywinautoBackend",
    "ResilientAutomationBackend",
]
