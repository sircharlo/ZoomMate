#include-once
; ================================================================================================
; ZOOM PATH ENGINE - Deterministic, reusable UI navigation paths
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "ElementActions.au3"
#include "ZoomOperations.au3"

Global $g_LastPathError = ""

Func _SetPathError($sMessage)
	$g_LastPathError = $sMessage
	ReportUserFacingError($sMessage)
	Debug($sMessage, "ERROR", True)
	Return False
EndFunc   ;==>_SetPathError

Func _GetPathError()
	Return $g_LastPathError
EndFunc   ;==>_GetPathError

; Ensure Zoom main meeting window exists and is focused.
Func EnsureZoomMainWindow()
	$g_LastPathError = ""
	If Not _GetZoomWindow() Then Return _SetPathError("Zoom main window not found.")
	If Not FocusZoomWindow() Then Return _SetPathError("Unable to focus Zoom main window.")
	Return True
EndFunc   ;==>EnsureZoomMainWindow

; Ensure More menu is visible and return container object.
Func EnsureMoreMenuVisible()
	If Not EnsureZoomMainWindow() Then Return 0
	Local $oMoreMenu = GetMoreMenu()
	If Not IsObj($oMoreMenu) Then
		_SetPathError("Unable to open Zoom More menu.")
		Return 0
	EndIf
	Return $oMoreMenu
EndFunc   ;==>EnsureMoreMenuVisible

; Ensure Host Tools container is visible and return container.
Func EnsureHostToolsVisible()
	If Not EnsureZoomMainWindow() Then Return 0
	Local $oHostTools = _OpenHostTools()
	If Not IsObj($oHostTools) Then
		_SetPathError("Unable to open Host Tools panel/menu.")
		Return 0
	EndIf
	Return $oHostTools
EndFunc   ;==>EnsureHostToolsVisible

; Ensure Participants section inside Host Tools is visible for security toggles.
Func EnsureHostToolsParticipantsScope()
	Local $oHostTools = EnsureHostToolsVisible()
	If Not IsObj($oHostTools) Then Return 0

	Local $oParticipants = FindElementByPartialName(GetUserSetting("ParticipantValue"), Default, $oHostTools)
	If IsObj($oParticipants) Then
		_ClickElement($oParticipants)
		Sleep(350)
	EndIf

	; Return host-tools scope regardless, caller can verify specific toggle presence
	Return $oHostTools
EndFunc   ;==>EnsureHostToolsParticipantsScope

; Ensure a specific security toggle is discoverable before any action.
Func EnsureSecurityToggleVisible($sSetting)
	Local $oScope = EnsureHostToolsParticipantsScope()
	If Not IsObj($oScope) Then Return 0

	Local $aSecurityTypes[4] = [$UIA_CheckBoxControlTypeId, $UIA_ButtonControlTypeId, $UIA_MenuItemControlTypeId, $UIA_TextControlTypeId]
	Local $oSetting = FindElementByPartialName($sSetting, $aSecurityTypes, $oScope)
	If Not IsObj($oSetting) Then
		$oSetting = FindElementByPartialName($sSetting, $aSecurityTypes, $oZoomWindow)
	EndIf

	If Not IsObj($oSetting) Then
		_SetPathError("Security toggle not found: " & $sSetting)
		Return 0
	EndIf

	Return $oSetting
EndFunc   ;==>EnsureSecurityToggleVisible
