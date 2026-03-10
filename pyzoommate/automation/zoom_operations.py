"""Zoom-specific UI operations replacing Includes/ZoomOperations.au3."""

from __future__ import annotations

from .ui_backend import UIElement


def _FindHostToolsContainer() -> UIElement | None:
    return None


def _OpenHostTools() -> bool:
    return False


def _FindHostMenuInternal() -> UIElement | None:
    return None


def _CloseHostTools() -> bool:
    return True


def GetMoreMenu() -> UIElement | None:
    return _FindMoreMenuInternal()


def _FindMoreMenuInternal() -> UIElement | None:
    return None


def _OpenParticipantsPanel() -> bool:
    return False


def _FindParticipantsPanelInternal() -> UIElement | None:
    return None
