"""State profiler output compatible with legacy filenames."""

from __future__ import annotations

from configparser import ConfigParser
from datetime import datetime
from pathlib import Path

from ..diagnostics.path_wizard import EnsureHostToolsVisible, EnsureZoomMainWindow
from ..automation.zoom_operations import _FindParticipantsPanelInternal

STATE_PROFILE_INI = Path("zoom_state_profiles.ini")
STATE_PROFILE_TXT = Path("zoom_state_profiles.txt")


def GetCurrentZoomStateFlags() -> dict[str, bool]:
    return {
        "zoom_window_visible": EnsureZoomMainWindow(),
        "host_tools_visible": EnsureHostToolsVisible(),
        "participants_panel_visible": _FindParticipantsPanelInternal() is not None,
    }


def CaptureCurrentStateSnapshot(stateName: str) -> dict[str, object]:
    return {
        "state": stateName,
        "timestamp": datetime.utcnow().isoformat(),
        "flags": GetCurrentZoomStateFlags(),
    }


def RunStateTrainingWizard(states: list[str] | None = None) -> list[dict[str, object]]:
    states = states or ["baseline", "prepost", "prestart"]
    snapshots = [CaptureCurrentStateSnapshot(state) for state in states]

    parser = ConfigParser()
    for snap in snapshots:
        section = str(snap["state"])
        parser[section] = {
            "Timestamp": str(snap["timestamp"]),
            **{k: str(v) for k, v in snap["flags"].items()},
        }

    with STATE_PROFILE_INI.open("w", encoding="utf-8") as handle:
        parser.write(handle)

    lines: list[str] = []
    for snap in snapshots:
        lines.append(f"[{snap['state']}] {snap['timestamp']}")
        for k, v in snap["flags"].items():
            lines.append(f"- {k}={v}")
    STATE_PROFILE_TXT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    return snapshots
