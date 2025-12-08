#include-once
; ================================================================================================
; USER SETTINGS MANAGEMENT
; ================================================================================================

#include "Globals.au3"

; Retrieves a user setting value by key
; @param $key - The setting key to retrieve
; @return String - The setting value or empty string if not found
Func GetUserSetting($key)
	If $g_UserSettings.Exists($key) Then Return $g_UserSettings.Item($key)
	Return ""
EndFunc   ;==>GetUserSetting

; Maps a setting key to its appropriate INI file section
; @param $sKey - Setting key name
; @return String - INI section name
Func _GetIniSectionForKey($sKey)
	Switch $sKey
		Case "MeetingID"
			Return "ZoomSettings"
		Case "MidweekDay", "MidweekTime", "WeekendDay", "WeekendTime"
			Return "Meetings"
		Case "Language", "SnapZoomSide", "KeyboardShortcut"
			Return "General"
		Case Else
			Return "ZoomStrings"
	EndSwitch
EndFunc   ;==>_GetIniSectionForKey

