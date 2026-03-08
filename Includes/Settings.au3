#include-once
; ================================================================================================
; SETTINGS - Zoom meeting settings management
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "ElementActions.au3"
#include "ZoomOperations.au3"

; ================================================================================================
; ZOOM SETTINGS MANAGEMENT FUNCTIONS
; ================================================================================================

; Internal function to find security setting (used by cache)
Func _FindSecuritySettingInternal($sSetting, $oHostMenu)
	Return FindElementByPartialName($sSetting, Default, $oHostMenu)
EndFunc   ;==>_FindSecuritySettingInternal

; Sets a security setting to the desired state (enabled/disabled)
; @param $sSetting - Setting name to modify
; @param $bDesired - Desired state (True=enabled, False=disabled)
Func SetSecuritySetting($sSetting, $bDesired)
	Debug(t("INFO_SETTING_SECURITY", $sSetting), "INFO")
	Sleep(3000)
	Local $oHostMenu = _OpenHostTools()
	If Not IsObj($oHostMenu) Then Return False

	Local $oSetting = FindElementByPartialName($sSetting, Default, $oHostMenu)
	If Not IsObj($oSetting) Then Return

	; Check current state
	Local $sLabel
	$oSetting.GetCurrentPropertyValue($UIA_NamePropertyId, $sLabel)

	Debug("Element name: '" & $sLabel & "'", "VERBOSE")

	; Setting is enabled if label does NOT contain unchecked indicator
	Local $uncheckedValue = GetUserSetting("UncheckedValue")
	Local $sLabelLower = StringLower($sLabel)
	Local $uncheckedLower = StringLower($uncheckedValue)

	Debug("Raw label: '" & $sLabel & "'", "VERBOSE")
	Debug("Label length: " & StringLen($sLabel), "VERBOSE")
	Debug("Unchecked value: '" & $uncheckedValue & "'", "VERBOSE")
	Debug("Unchecked length: " & StringLen($uncheckedValue), "VERBOSE")
	Debug("Label lower: '" & $sLabelLower & "'", "VERBOSE")
	Debug("Unchecked lower: '" & $uncheckedLower & "'", "VERBOSE")

	; Check if unchecked value appears anywhere in the label (not just word boundaries)
	Local $bEnabled = (StringInStr($sLabelLower, $uncheckedLower) = 0)

	Debug("StringInStr result: " & StringInStr($sLabelLower, $uncheckedLower), "VERBOSE")
	Debug("Setting '" & $sLabel & "' | Current: " & ($bEnabled ? "True" : "False") & " | Desired: " & $bDesired, "VERBOSE")

	; Only click if state needs to change
	If $bEnabled <> $bDesired Then
		_HoverElement($oSetting, 50)
		_MoveMouseToStartOfElement($oSetting, True) ; Click at start of element to ensure change
		Debug("Toggled setting '" & $sSetting & "'", "SETTING CHANGE")
	Else
		_CloseHostTools()
	EndIf
EndFunc   ;==>SetSecuritySetting

; Toggles host's audio or video feed on/off
; @param $feedType - "Video" or "Audio"
; @param $desiredState - True to enable, False to disable
Func ToggleFeed($feedType, $desiredState)
	Debug(t("INFO_TOGGLE_FEED", $feedType), "INFO")
	Local $currentlyEnabled = False

	; Controls might be hidden, show them by moving the mouse
	Debug("Controls might be hidden. Moving mouse to show controls.", "VERBOSE")
	_MoveMouseToStartOfElement($oZoomWindow)

	If $feedType = "Video" Then
		; Check for video control buttons to determine current state
		Local $stopMyVideoButton = FindElementByPartialName(GetUserSetting("StopVideoValue"), Default, $oZoomWindow)
		Local $startMyVideoButton = FindElementByPartialName(GetUserSetting("StartVideoValue"), Default, $oZoomWindow)
		$currentlyEnabled = IsObj($stopMyVideoButton)

		; Toggle if needed
		If $desiredState <> $currentlyEnabled Then
			If IsObj($stopMyVideoButton) Then
				_ClickElement($stopMyVideoButton)
			ElseIf IsObj($startMyVideoButton) Then
				_ClickElement($startMyVideoButton)
			Else
				Debug("No video button found to toggle!", "WARN")
			EndIf
		EndIf

	ElseIf $feedType = "Audio" Then
		; Check for audio control buttons to determine current state
		Local $muteHostButton = FindElementByPartialName(GetUserSetting("CurrentlyUnmutedValue"), Default, $oZoomWindow)
		Local $unmuteHostButton = FindElementByPartialName(GetUserSetting("UnmuteAudioValue"), Default, $oZoomWindow)
		$currentlyEnabled = IsObj($muteHostButton)

		; Toggle if needed
		If $desiredState <> $currentlyEnabled Then
			If IsObj($muteHostButton) Then
				_ClickElement($muteHostButton)
			ElseIf IsObj($unmuteHostButton) Then
				_ClickElement($unmuteHostButton)
			Else
				Debug("No audio button found to toggle!", "WARN")
			EndIf
		EndIf
	Else
		Debug(t("ERROR_UNKNOWN_FEED_TYPE") & ": '" & $feedType & "'", "WARN")
	EndIf
	Sleep(1000)
EndFunc   ;==>ToggleFeed

; Mutes all meeting participants
; @return Boolean - True if successful, False otherwise
Func MuteAll()
	Debug(t("INFO_MUTE_ALL"), "INFO")

	; Open participants panel
	Local $oParticipantsPanel = _OpenParticipantsPanel()
	If Not IsObj($oParticipantsPanel) Then Return False

	; Find and click "Mute All" button
	Local $oButton = FindElementByPartialName(GetUserSetting("MuteAllValue"), Default, $oZoomWindow)
	If Not _ClickElement($oButton) Then
		Debug(t("ERROR_ELEMENT_NOT_FOUND", GetUserSetting("MuteAllValue")), "ERROR")
		Return False
	EndIf

	; Confirm the action in dialog
	Return DialogClick("zChangeNameWndClass", GetUserSetting("YesValue"))
EndFunc   ;==>MuteAll

; Best-effort: switch host to gallery view.
; This uses Zoom's default Alt+F2 shortcut when available.
Func EnsureGalleryView()
	Debug("Ensuring gallery view (best effort via Alt+F2).", "INFO")
	If Not FocusZoomWindow() Then Return False
	Send("!{F2}")
	Sleep(300)
	Return True
EndFunc   ;==>EnsureGalleryView

; Best-effort spotlight pulse for host video.
; Current implementation is a safe no-op placeholder until a robust UIA locator is configured.
Func PulseSpotlightHostVideo($durationMs = 5000)
	Debug("Spotlight pulse requested for " & $durationMs & "ms. No-op until spotlight selector is configured.", "WARN")
	Sleep($durationMs)
	Return True
EndFunc   ;==>PulseSpotlightHostVideo

; Clicks a button in a dialog window by class name and button text
; @param $ClassName - Dialog window class name
; @param $ButtonLabel - Button text to click
; @return Boolean - True if successful, False otherwise
Func DialogClick($ClassName, $ButtonLabel)
	Local $oDialog = FindElementByClassName($ClassName)
	Local $oButton = FindElementByPartialName($ButtonLabel, Default, $oDialog)
	If _ClickElement($oButton) Then Return True
	Debug(t("ERROR_ELEMENT_NOT_FOUND", $ButtonLabel), "ERROR")
	Return False
EndFunc   ;==>DialogClick
