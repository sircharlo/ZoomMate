#include-once
; ================================================================================================
; KEYBOARD SHORTCUTS - Keyboard shortcut management
; ================================================================================================

#include "Globals.au3"
#include "MeetingAutomation.au3"
#include "Utils.au3"
#include "UserSettings.au3"

; ================================================================================================
; KEYBOARD SHORTCUT MANAGEMENT
; ================================================================================================

; Registers or unregisters the keyboard shortcut for manual trigger
; Called when keyboard shortcut setting is changed
Func _UpdateKeyboardShortcut()
	; Unregister any currently registered hotkey
	If $g_HotkeyRegistered Then
		HotKeySet($g_KeyboardShortcut)
		$g_HotkeyRegistered = False
		Debug("Previous keyboard shortcut unregistered: " & $g_KeyboardShortcut, "VERBOSE")
	EndIf

	; Update the global keyboard shortcut variable
	$g_KeyboardShortcut = GetUserSetting("KeyboardShortcut")

	; Register new hotkey if not empty
	If $g_KeyboardShortcut <> "" Then
		; Validate the shortcut format (basic validation)
		If StringRegExp($g_KeyboardShortcut, "^[\^\!\+\#]+[a-zA-Z0-9]$") Then
			HotKeySet($g_KeyboardShortcut, "_ManualTrigger")
			$g_HotkeyRegistered = True
			Debug("New keyboard shortcut registered: " & $g_KeyboardShortcut, "VERBOSE")
		Else
			Debug("Invalid keyboard shortcut format: " & $g_KeyboardShortcut, "VERBOSE")
			$g_KeyboardShortcut = ""
			IniWrite($CONFIG_FILE, "General", "KeyboardShortcut", "")
		EndIf
	Else
		Debug("Keyboard shortcut cleared", "VERBOSE")
	EndIf
EndFunc   ;==>_UpdateKeyboardShortcut

; Manual trigger function activated by keyboard shortcut
; Allows user to manually apply post-meeting settings
Func _ManualTrigger()    ; Show message and wait for user input before applying settings
	Debug("Manual trigger: Showing post-meeting message", "VERBOSE")

	; Show the post-meeting message and wait for Enter key
	ShowOverlayMessage('POST_MEETING_HIT_KEY')

	; Wait for user to press Enter or ESC
	Local $userInput = _WaitForEnterOrEscape()

	; Hide the message
	HideOverlayMessage()

	; Apply settings if user pressed Enter
	If $userInput = "ENTER" Then
		Debug("User pressed Enter: Applying post-meeting settings", "VERBOSE")
		_SetPreAndPostMeetingSettings()
	Else
		Debug("User pressed Escape or closed dialog: Cancelling", "VERBOSE")
	EndIf
EndFunc   ;==>_ManualTrigger

; Waits for user to press Enter or Escape key
; @return String - "ENTER" if Enter was pressed, "ESCAPE" if Escape was pressed or dialog closed
Func _WaitForEnterOrEscape()
	Local $hUser32 = DllOpen("user32.dll")

	While True
		; Check for Enter key
		If _IsKeyPressed($hUser32, 0x0D) Then ; VK_RETURN
			DllClose($hUser32)
			Return "ENTER"
		EndIf

		; Check for Escape key
		If _IsKeyPressed($hUser32, 0x1B) Then ; VK_ESCAPE
			DllClose($hUser32)
			Return "ESCAPE"
		EndIf

		; Check if GUI was closed (handle becomes invalid)
		If $g_OverlayMessageGUI = 0 Or Not WinExists(HWnd($g_OverlayMessageGUI)) Then
			DllClose($hUser32)
			Return "ESCAPE"
		EndIf

		Sleep(100) ; Small delay to avoid high CPU usage
	WEnd
EndFunc   ;==>_WaitForEnterOrEscape

; Helper function to check if a key is currently pressed
; @param $hDLL - Handle to user32.dll
; @param $iKeyCode - Virtual key code to check
; @return Boolean - True if key is pressed
Func _IsKeyPressed($hDLL, $iKeyCode)
	Local $aRet = DllCall($hDLL, "short", "GetAsyncKeyState", "int", $iKeyCode)
	If @error Or Not IsArray($aRet) Then Return False
	Return BitAND($aRet[0], 0x8000) <> 0
EndFunc   ;==>_IsKeyPressed
