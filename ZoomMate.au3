; ================================================================================================
; ZOOMMATE - Automated Zoom Meeting Management Tool
; ================================================================================================
; This script automatically manages Zoom meeting settings based on scheduled meeting times.
; It configures security settings before/after meetings and applies meeting-specific settings
; when meetings start.

; ================================================================================================
; COMPILER DIRECTIVES AND INCLUDES
; ================================================================================================
#AutoIt3Wrapper_UseX64=y
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Date.au3>
#include <TrayConstants.au3>
#include <StaticConstants.au3>
#include <GDIPlus.au3>
#include <WinAPI.au3>
#include <EditConstants.au3>
#include <File.au3>
#include "Includes\UIA_Functions-a.au3"
#include "Includes\CUIAutomation2.au3"

; ================================================================================================
; FILE INSTALLATION - Extract embedded images to script directory
; ================================================================================================
FileInstall("images\host_tools.jpg", @ScriptDir & "\images\host_tools.jpg", 1)
FileInstall("images\more_meeting_controls.jpg", @ScriptDir & "\images\more_meeting_controls.jpg", 1)
FileInstall("images\participant.jpg", @ScriptDir & "\images\participant.jpg", 1)
FileInstall("images\mute_all.jpg", @ScriptDir & "\images\mute_all.jpg", 1)
FileInstall("images\yes.jpg", @ScriptDir & "\images\yes.jpg", 1)
FileInstall("images\security_unmute.jpg", @ScriptDir & "\images\security_unmute.jpg", 1)
FileInstall("images\security_share_screen.jpg", @ScriptDir & "\images\security_share_screen.jpg", 1)
FileInstall("images\placeholder.jpg", @ScriptDir & "\images\placeholder.jpg", 1)

; ================================================================================================
; AUTOIT OPTIONS AND CONSTANTS
; ================================================================================================
; Set AutoIt options for better script behavior
Opt("MustDeclareVars", 1)        ; Force variable declarations
Opt("GUIOnEventMode", 1)         ; Enable GUI event mode
Opt("TrayMenuMode", 3)           ; Custom tray menu (no default, no auto-pause)

; Windows API constants for GUI message handling
Global Const $MF_BYCOMMAND = 0x00000000

; ================================================================================================
; CUSTOM INCLUDES - Refactored modules
; ================================================================================================
#include "Includes\Globals.au3"
#include "Includes\i18n.au3"
#include "Includes\Utils.au3"
#include "Includes\UserSettings.au3"
#include "Includes\Config.au3"
#include "Includes\GUI.au3"
#include "Includes\UIAutomation.au3"
#include "Includes\ElementActions.au3"
#include "Includes\ZoomOperations.au3"
#include "Includes\KeyboardShortcuts.au3"
#include "Includes\Settings.au3"
#include "Includes\MeetingAutomation.au3"

; ================================================================================================
; TRAY ICON EVENT HANDLING
; ================================================================================================

; Sets up tray icon and handles tray events
TraySetIcon($g_TrayIcon)

; ================================================================================================
; UIAUTOMATION COM INITIALIZATION
; ================================================================================================

; Initialize UIAutomation COM object for interacting with Zoom UI
$oUIAutomation = ObjCreateInterface($sCLSID_CUIAutomation, $sIID_IUIAutomation, $dtagIUIAutomation)
If Not IsObj($oUIAutomation) Then
	Debug("Failed to create UIAutomation COM object.", "UIA")
	MsgBox(16 + 262144, "ZoomMate - Critical Error", "Failed to create UIAutomation COM object." & @CRLF & "Please ensure UIA prerequisites are met.")
	Exit
EndIf
Debug("UIAutomation COM created successfully.", "UIA")

; Get desktop element as root for UI searches
$oUIAutomation.GetRootElement($pDesktop)
$oDesktop = ObjCreateInterface($pDesktop, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
If Not IsObj($oDesktop) Then
	Debug(t("ERROR_GET_DESKTOP_ELEMENT_FAILED"), "ERROR")
	MsgBox(16 + 262144, "ZoomMate - Critical Error", t("ERROR_GET_DESKTOP_ELEMENT_FAILED"))
	Exit
EndIf
Debug("Desktop element obtained.", "UIA")

; ================================================================================================
; MAIN APPLICATION INITIALIZATION
; ================================================================================================

; Load translations and configuration
LoadMeetingConfig()
_InitDayLabelMaps()

; Debugging functions here
; _LaunchZoom()
; _GetZoomWindow()
; FocusZoomWindow()
; _SetDuringMeetingSettings()


; ================================================================================================
; COMMAND-LINE SCENE TRIGGERING (for Electron integration)
; ================================================================================================
; Usage examples:
;   ZoomMate.exe --scene prepost
;   ZoomMate.exe --scene prestart
If $CmdLine[0] >= 2 And StringLower($CmdLine[1]) = "--scene" Then
	Debug("Command-line scene requested: " & $CmdLine[2], "INFO")
	If RunAutomationScene($CmdLine[2]) Then
		Exit
	Else
		Debug("Scene execution failed or scene name invalid: " & $CmdLine[2], "ERROR")
		Exit 1
	EndIf
EndIf

; ================================================================================================
; MAIN APPLICATION LOOP
; ================================================================================================

; Initialize loop variables
Global $today
Global $timeNow
Global $sleepTime = 5000

While True
	; Handle tray icon events
	TrayEvent()

	; Check if day has changed to reset automation flags
	$today = @WDAY
	If $today <> $previousRunDay Then
		Debug("New day detected. Resetting configuration flags.", "VERBOSE")
		$previousRunDay = $today
		$g_PrePostSettingsConfigured = False
		$g_DuringMeetingSettingsConfigured = False
	EndIf

	$timeNow = _NowTime(4) ; Get current time in HH:MM format

	; Check if today is a scheduled meeting day
	If $today = Number(GetUserSetting("MidweekDay")) Then
		$sleepTime = CheckMeetingWindow(GetUserSetting("MidweekTime"))
	ElseIf $today = Number(GetUserSetting("WeekendDay")) Then
		$sleepTime = CheckMeetingWindow(GetUserSetting("WeekendTime"))
	Else
		; Not a meeting day - wait 1 minute before checking again
		Debug(t("INFO_NO_MEETING_SCHEDULED"), "INFO", $g_InitialNotificationWasShown)
		$g_InitialNotificationWasShown = True
		$sleepTime = 60000
	EndIf

	Sleep($sleepTime)
WEnd
