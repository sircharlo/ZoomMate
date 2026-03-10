#include-once
; ================================================================================================
; STATE PROFILER - Guided Zoom state capture and signature analysis
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "ZoomOperations.au3"

Global Const $STATE_PROFILE_INI = @ScriptDir & "\zoom_state_profiles.ini"
Global Const $STATE_PROFILE_TXT = @ScriptDir & "\zoom_state_profiles.txt"

; Returns a dictionary of current, high-level Zoom UI state flags.
Func GetCurrentZoomStateFlags()
	Local $oFlags = ObjCreate("Scripting.Dictionary")
	If Not IsObj($oFlags) Then Return 0

	Local $oResolvedZoomWindow = _GetZoomWindow()
	$oFlags.Add("ZoomWindowVisible", IsObj($oResolvedZoomWindow))
	If Not IsObj($oResolvedZoomWindow) Then Return $oFlags

	Local $oMoreMenu = FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)
	$oFlags.Add("MoreMenuVisible", IsObj($oMoreMenu))

	Local $oHostTools = _FindHostToolsContainer()
	$oFlags.Add("HostToolsVisible", IsObj($oHostTools))

	Local $ListType[1] = [$UIA_ListControlTypeId]
	Local $oParticipantsPanel = FindElementByPartialName(GetUserSetting("ParticipantValue"), $ListType, $oZoomWindow)
	$oFlags.Add("ParticipantsPanelVisible", IsObj($oParticipantsPanel))

	Local $oParticipantsInHostTools = 0
	If IsObj($oHostTools) Then
		$oParticipantsInHostTools = FindElementByPartialName(GetUserSetting("ParticipantValue"), Default, $oHostTools)
	EndIf
	$oFlags.Add("HostToolsParticipantsNodeVisible", IsObj($oParticipantsInHostTools))

	Local $oMuteHostButton = FindElementByPartialName(GetUserSetting("CurrentlyUnmutedValue"), Default, $oZoomWindow)
	$oFlags.Add("HostAudioOn", IsObj($oMuteHostButton))

	Local $oStopVideoButton = FindElementByPartialName(GetUserSetting("StopVideoValue"), Default, $oZoomWindow)
	$oFlags.Add("HostVideoOn", IsObj($oStopVideoButton))

	; Best effort: Gallery view is usually toggled via Alt+F2; Zoom does not reliably expose a stable named element.
	$oFlags.Add("GalleryViewDetected", False)

	Return $oFlags
EndFunc   ;==>GetCurrentZoomStateFlags

; Captures current state flags and visible named elements into INI + text report.
Func CaptureCurrentStateSnapshot($stateName)
	Local $oFlags = GetCurrentZoomStateFlags()
	If Not IsObj($oFlags) Then
		ReportUserFacingError("State capture failed: could not create state dictionary.")
		Return False
	EndIf

	Local $section = "State_" & $stateName
	IniWrite($STATE_PROFILE_INI, $section, "Timestamp", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	For $k In $oFlags.Keys
		IniWrite($STATE_PROFILE_INI, $section, $k, String($oFlags.Item($k)))
	Next

	Local $h = FileOpen($STATE_PROFILE_TXT, $FO_APPEND + $FO_CREATEPATH)
	If $h = -1 Then
		ReportUserFacingError("State capture failed: cannot write " & $STATE_PROFILE_TXT)
		Return False
	EndIf

	FileWriteLine($h, "============================================================")
	FileWriteLine($h, "State: " & $stateName & " | " & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	For $k In $oFlags.Keys
		FileWriteLine($h, "Flag." & $k & "=" & String($oFlags.Item($k)))
	Next

	_DumpVisibleNamedElements($h)
	FileClose($h)
	Return True
EndFunc   ;==>CaptureCurrentStateSnapshot

; Guided wizard that asks operator to place Zoom in each state, then captures signatures.
Func RunStateTrainingWizard()
	Local $oResolvedZoomWindow = _GetZoomWindow()
	If Not IsObj($oResolvedZoomWindow) Then
		ReportUserFacingError("State profiler needs an active Zoom meeting window.")
		Return
	EndIf

	Local $states[9] = [ _
		"BASELINE_MEETING_VIEW", _
		"MORE_MENU_OPEN", _
		"HOST_TOOLS_OPEN", _
		"HOST_TOOLS_PARTICIPANTS_SECTION", _
		"PARTICIPANTS_PANEL_OPEN", _
		"AUDIO_ON_VIDEO_ON", _
		"AUDIO_OFF_VIDEO_OFF", _
		"GALLERY_VIEW", _
		"ACTIVE_SPEAKER_VIEW"]

	Local $instructions[9] = [ _
		"Leave Zoom in normal meeting view (no menus open).", _
		"Open More menu and keep it visible.", _
		"Open Host Tools panel/menu and keep it visible.", _
		"In Host Tools, open/select Participants node for security toggles.", _
		"Open the main Participants panel.", _
		"Set host audio ON and host video ON.", _
		"Set host audio OFF and host video OFF.", _
		"Switch to Gallery view.", _
		"Switch to Active Speaker view."]

	For $i = 0 To UBound($states) - 1
		Local $res = MsgBox(1 + 262144, "ZoomMate State Profiler", _
			"Prepare this state then click OK:" & @CRLF & @CRLF & _
			$states[$i] & @CRLF & $instructions[$i] & @CRLF & @CRLF & _
			"Click Cancel to stop the wizard.")
		If $res <> 1 Then ExitLoop

		If Not CaptureCurrentStateSnapshot($states[$i]) Then
			ReportUserFacingError("State capture failed for: " & $states[$i])
			ExitLoop
		EndIf
	Next

	MsgBox(64 + 262144, "ZoomMate", "State profiling completed." & @CRLF & _
		"Saved to:" & @CRLF & $STATE_PROFILE_INI & @CRLF & $STATE_PROFILE_TXT)
EndFunc   ;==>RunStateTrainingWizard

Func _DumpVisibleNamedElements($hFile)
	If Not IsObj($oZoomWindow) Then Return

	Local $aTypes[7] = [$UIA_ButtonControlTypeId, $UIA_MenuItemControlTypeId, $UIA_CheckBoxControlTypeId, $UIA_ListControlTypeId, $UIA_PaneControlTypeId, $UIA_GroupControlTypeId, $UIA_WindowControlTypeId]
	For $t = 0 To UBound($aTypes) - 1
		Local $pCondition
		$oUIAutomation.CreatePropertyCondition($UIA_ControlTypePropertyId, $aTypes[$t], $pCondition)
		Local $pElements
		$oZoomWindow.FindAll($TreeScope_Descendants, $pCondition, $pElements)
		Local $oElements = ObjCreateInterface($pElements, $sIID_IUIAutomationElementArray, $dtagIUIAutomationElementArray)
		If IsObj($oElements) Then
			Local $iCount
			$oElements.Length($iCount)
			FileWriteLine($hFile, "Type=" & $aTypes[$t] & " Count=" & $iCount)
			Local $limit = $iCount
			If $limit > 250 Then $limit = 250
			For $i = 0 To $limit - 1
				Local $pElement
				$oElements.GetElement($i, $pElement)
				Local $oElement = ObjCreateInterface($pElement, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
				If IsObj($oElement) Then
					Local $sName = ""
					$oElement.GetCurrentPropertyValue($UIA_NamePropertyId, $sName)
					If StringStripWS($sName, 3) <> "" Then FileWriteLine($hFile, "  - " & $sName)
				EndIf
			Next
		EndIf
	Next
EndFunc   ;==>_DumpVisibleNamedElements
