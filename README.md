# ZoomMate

A lightweight AutoIt (AU3) script that automates common Zoom tasks for meetings of Jehovah's Witnesses. Designed to let AV operators focus less on Zoom controls, this script handles routine actions like opening meetings, managing host tools, and streamlining the virtual meeting experience.

## What It Does

ZoomMate automatically:

- Launches Zoom meetings at scheduled times
- Configures meeting security settings before and after meetings
- Applies meeting-specific settings when meetings start
- Manages host controls and participant settings
- Runs in the system tray for easy access and configuration

## Requirements

- Windows OS
- [AutoIt](https://www.autoitscript.com/site/autoit/downloads/) installed for running `.au3` scripts or compiling to `.exe`
- Zoom desktop client installed

## Installation & Setup

1. **Download and extract** the ZoomMate files to your desired location.

2. **Configure your settings:**
   - Run `ZoomMate.au3` (double-click if AutoIt is installed)
   - The configuration GUI will launch automatically
   - Set your Meeting ID, meeting times, and language preferences
   - Configure any other settings as needed

3. **Start using ZoomMate:**
   - The script will run in your system tray
   - Click the tray icon to access settings and configuration
   - ZoomMate will automatically manage your Zoom meetings based on your schedule

## Optional: Compile to Standalone Executable

If you prefer not to install AutoIt or want a standalone executable:

```powershell
Aut2exe.exe /in "ZoomMate.au3" /out "ZoomMate.exe" /icon "zoommate.ico"
```

This creates `ZoomMate.exe` with your custom icon that can be run without AutoIt installed.

## Usage

Once configured, ZoomMate runs automatically in the background:

- It monitors your scheduled meeting times
- Launches Zoom and applies your configured settings
- Manages meeting controls throughout the session
- Access the tray icon anytime to modify settings or view status

### Electron Integration (shortcut-driven scenes)

You can trigger deterministic automation scenes from your Electron app by launching ZoomMate with a scene argument:

```bash
ZoomMate.exe --scene prepost
ZoomMate.exe --scene prestart
```

- `prepost`: Intended for before meeting start and after meeting end. Applies host audio/video off, allows participant unmute, disables screen share, and attempts gallery view.
- `prestart`: Intended for just before the meeting starts. Applies mute-all, prevents participant unmute, host audio/video on, opens participants panel, snaps window to configured side, and attempts gallery view.

The script is designed to be unobtrusive and requires minimal interaction once initially configured.


## Reliability & Future-Proofing Toolkit

ZoomMate now includes a deterministic path engine and diagnostics helpers so UI changes in Zoom can be handled faster:

- **Path engine**: each action drills through required parent paths first (Zoom window -> More -> Host Tools -> Participants -> setting).
- **User-visible failures**: if a required panel/toggle cannot be found, ZoomMate reports the error in GUI/tray and stops that task.
- **UI Diagnostics button**: captures discoverable Zoom element names into `zoom_ui_diagnostics.txt`.
- **Path Wizard button**: lets operators re-capture and store key path labels (More, Host Tools, Participants) after Zoom UI updates.


### State Profiler Wizard

Use **State Profiler** in the settings GUI to guide Zoom through key states and automatically capture signatures for each state.

Captured outputs:
- `zoom_state_profiles.ini` (state flags)
- `zoom_state_profiles.txt` (visible named elements by control type)

This is intended to make future checks deterministic (for example: detect if Participants panel is already open before trying to open it again).
