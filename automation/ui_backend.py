"""Compatibility shim for migrated backend module.

The implementation now lives under ``pyzoommate.automation.ui_backend``.
"""

from pyzoommate.automation.ui_backend import (  # noqa: F401
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
