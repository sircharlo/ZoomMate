"""Compatibility package for automation imports.

Prefer importing from :mod:`pyzoommate.automation`.
"""

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
