#include-once
; ================================================================================================
; CONFIGURATION - Configuration loading and validation
; ================================================================================================

#include "Globals.au3"
#include "KeyboardShortcuts.au3"
#include "UserSettings.au3"
#include "Utils.au3"

; ================================================================================================
; CONFIGURATION LOADING AND SAVING
; ================================================================================================

; Loads meeting configuration from INI file
; If any required settings are missing, opens the configuration GUI
Func LoadMeetingConfig()
	; Clear existing settings
	$g_UserSettings.RemoveAll()

	; Load all required settings from INI file
	$g_UserSettings.Add("MeetingID", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomSettings", "MeetingID", "")))
	$g_UserSettings.Add("MidweekDay", _UTF8ToString(IniRead($CONFIG_FILE, "Meetings", "MidweekDay", "")))
	$g_UserSettings.Add("MidweekTime", _UTF8ToString(IniRead($CONFIG_FILE, "Meetings", "MidweekTime", "")))
	$g_UserSettings.Add("WeekendDay", _UTF8ToString(IniRead($CONFIG_FILE, "Meetings", "WeekendDay", "")))
	$g_UserSettings.Add("WeekendTime", _UTF8ToString(IniRead($CONFIG_FILE, "Meetings", "WeekendTime", "")))
	$g_UserSettings.Add("HostToolsValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "HostToolsValue", "")))
	$g_UserSettings.Add("ParticipantValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "ParticipantValue", "")))
	$g_UserSettings.Add("MuteAllValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "MuteAllValue", "")))
	$g_UserSettings.Add("MoreMeetingControlsValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "MoreMeetingControlsValue", "")))
	$g_UserSettings.Add("YesValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "YesValue", "")))
	$g_UserSettings.Add("UncheckedValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "UncheckedValue", "")))
	$g_UserSettings.Add("CurrentlyUnmutedValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "CurrentlyUnmutedValue", "")))
	$g_UserSettings.Add("UnmuteAudioValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "UnmuteAudioValue", "")))
	$g_UserSettings.Add("StopVideoValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "StopVideoValue", "")))
	$g_UserSettings.Add("StartVideoValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "StartVideoValue", "")))
	$g_UserSettings.Add("ZoomSecurityUnmuteValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "ZoomSecurityUnmuteValue", "")))
	$g_UserSettings.Add("ZoomSecurityShareScreenValue", _UTF8ToString(IniRead($CONFIG_FILE, "ZoomStrings", "ZoomSecurityShareScreenValue", "")))
	$g_UserSettings.Add("KeyboardShortcut", _UTF8ToString(IniRead($CONFIG_FILE, "General", "KeyboardShortcut", "")))

	; Window snapping preference (Disabled|Left|Right)
	$g_UserSettings.Add("SnapZoomSide", _UTF8ToString(IniRead($CONFIG_FILE, "General", "SnapZoomSide", "Disabled")))

	; Load language setting
	Local $lang = _UTF8ToString(IniRead($CONFIG_FILE, "General", "Language", ""))
	If $lang = "" Then
		$lang = "en"
		IniWrite($CONFIG_FILE, "General", "Language", _StringToUTF8($lang))
	EndIf
	$g_UserSettings.Add("Language", $lang)
	$g_CurrentLang = $lang

	; Load keyboard shortcut setting
	$g_KeyboardShortcut = GetUserSetting("KeyboardShortcut")
	If $g_KeyboardShortcut <> "" Then
		_UpdateKeyboardShortcut()
	EndIf

	; Check if all required settings are configured
	If GetUserSetting("MeetingID") = "" Or GetUserSetting("MidweekDay") = "" Or GetUserSetting("MidweekTime") = "" Or GetUserSetting("WeekendDay") = "" Or GetUserSetting("WeekendTime") = "" Or GetUserSetting("HostToolsValue") = "" Or GetUserSetting("ParticipantValue") = "" Or GetUserSetting("MuteAllValue") = "" Or GetUserSetting("YesValue") = "" Or GetUserSetting("MoreMeetingControlsValue") = "" Or GetUserSetting("UncheckedValue") = "" Or GetUserSetting("CurrentlyUnmutedValue") = "" Or GetUserSetting("UnmuteAudioValue") = "" Or GetUserSetting("StopVideoValue") = "" Or GetUserSetting("StartVideoValue") = "" Or GetUserSetting("ZoomSecurityUnmuteValue") = "" Or GetUserSetting("ZoomSecurityShareScreenValue") = "" Then
		; Open configuration GUI if any settings are missing
		ShowConfigGUI()
		While $g_ConfigGUI
			Sleep(100)
		WEnd
	Else
		Debug(t("INFO_CONFIG_LOADED"), "INFO")
		Debug("Midweek Meeting: " & t("DAY_" & GetUserSetting("MidweekDay")) & " at " & GetUserSetting("MidweekTime"), "VERBOSE", True)
		Debug("Weekend Meeting: " & t("DAY_" & GetUserSetting("WeekendDay")) & " at " & GetUserSetting("WeekendTime"), "VERBOSE", True)
	EndIf
EndFunc   ;==>LoadMeetingConfig


; ================================================================================================
; INPUT VALIDATION FUNCTIONS
; ================================================================================================

; Validates meeting ID format (9-11 digits)
; @param $s - String to validate
; @return Boolean - True if valid meeting ID format
Func _IsValidMeetingID($s)
	$s = StringStripWS($s, 3)  ; Remove leading/trailing whitespace
	If $s = "" Then Return False
	If Not StringRegExp($s, "^\d{9,11}$") Then Return False
	Return True
EndFunc   ;==>_IsValidMeetingID

; Validates time format (HH:MM in 24-hour format)
; @param $s - String to validate
; @return Boolean - True if valid time format
Func _IsValidTime($s)
	$s = StringStripWS($s, 3)  ; Remove leading/trailing whitespace
	If $s = "" Then Return False
	If Not StringRegExp($s, "^(\d{1,2}):(\d{2})$") Then Return False

	; Validate hour and minute ranges
	Local $a = StringSplit($s, ":")
	Local $h = Number($a[1])
	Local $m = Number($a[2])
	If $h < 0 Or $h > 23 Then Return False
	If $m < 0 Or $m > 59 Then Return False
	Return True
EndFunc   ;==>_IsValidTime

; Validates keyboard shortcut format
; @param $s - String to validate
; @return Boolean - True if valid keyboard shortcut format
Func _IsValidKeyboardShortcut($s)
	$s = StringStripWS($s, 3)  ; Remove leading/trailing whitespace
	If $s = "" Then Return True  ; Empty shortcut is valid (means no hotkey)

	; Basic validation for AutoIt hotkey format: modifiers + key
	; Valid modifiers: ^ (Ctrl), ! (Alt), + (Shift), # (Win)
	; Valid keys: a-z, A-Z, 0-9, F1-F12, etc.
	If Not StringRegExp($s, "^[\^\!\+\#]*[a-zA-Z0-9]$") Then Return False

	; Must have at least one modifier key
	If Not StringRegExp($s, "[\^\!\+\#]") Then Return False

	Return True
EndFunc   ;==>_IsValidKeyboardShortcut
