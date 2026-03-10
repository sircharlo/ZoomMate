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
#include "ZoomPathEngine.au3"

; ================================================================================================
; ZOOM SETTINGS MANAGEMENT FUNCTIONS
; ================================================================================================

; Internal function to find security setting (used by cache)
Func _FindSecuritySettingInternal($sSetting, $oHostMenu)
	Return FindElementByPartialName($sSetting, Default, $oHostMenu)
EndFunc   ;==>_FindSecuritySettingInternal

; Finds first matching element from a pipe-separated list of partial names.
Func _FindElementByAnyName($sCandidates, $aControlTypes, $oParent)
	Local $aNames = StringSplit($sCandidates, "|", 2)
	For $i = 0 To UBound($aNames) - 1
		Local $name = StringStripWS($aNames[$i], 3)
		If $name = "" Then ContinueLoop
		Local $o = FindElementByPartialName($name, $aControlTypes, $oParent)
		If IsObj($o) Then Return $o
	Next
	Return 0
EndFunc   ;==>_FindElementByAnyName

; Sets "Who can share" via Share Options -> Host tools for sharing flow.
; @param $bAllowParticipants - True to allow all participants, False for host-only
Func SetShareScreenPermission($bAllowParticipants)
	If Not EnsureZoomMainWindow() Then Return False

	; Step 1: open Share options menu
	Local $aMenuItemTypes[1] = [$UIA_MenuItemControlTypeId]
	Local $shareOptionsCandidates = GetUserSetting("ShareOptionsValue")
	If $shareOptionsCandidates = "" Then $shareOptionsCandidates = "Option partage|Share options"
	Local $oShareOptions = _FindElementByAnyName($shareOptionsCandidates, $aMenuItemTypes, $oZoomWindow)
	If Not IsObj($oShareOptions) Then
		ReportUserFacingError("Share options button/menu not found.")
		Return False
	EndIf
	If Not _ClickElement($oShareOptions, True) Then Return False
	Sleep(350)

	; Step 2: click Host tools for sharing item in popup menu
	Local $oShareMenu = FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)
	If Not IsObj($oShareMenu) Then
		ReportUserFacingError("Share options menu did not open.")
		Return False
	EndIf
	Local $hostToolsShareCandidates = GetUserSetting("HostToolsForShareValue")
	If $hostToolsShareCandidates = "" Then $hostToolsShareCandidates = "Outils de l’hôte pour le partage|Host tools for sharing"
	Local $oHostToolsShare = _FindElementByAnyName($hostToolsShareCandidates, $aMenuItemTypes, $oShareMenu)
	If Not IsObj($oHostToolsShare) Then
		ReportUserFacingError("'Host tools for sharing' item not found.")
		Return False
	EndIf
	If Not _ClickElement($oHostToolsShare, True) Then Return False
	Sleep(500)

	; Step 3: select desired item from 'Who can share' combobox/list
	Local $aComboTypes[1] = [$UIA_ComboBoxControlTypeId]
	Local $comboCandidates = GetUserSetting("WhoCanShareComboValue")
	If $comboCandidates = "" Then $comboCandidates = "Qui peut partager|Who can share"
	Local $oWhoCanShareCombo = _FindElementByAnyName($comboCandidates, $aComboTypes, $oZoomWindow)
	If IsObj($oWhoCanShareCombo) Then _ClickElement($oWhoCanShareCombo, True)
	Sleep(300)

	Local $aListItemTypes[1] = [$UIA_ListItemControlTypeId]
	Local $targetCandidates = ""
	If $bAllowParticipants Then
		$targetCandidates = GetUserSetting("WhoCanShareParticipantsValue")
		If $targetCandidates = "" Then $targetCandidates = "Tous les participants|All participants"
	Else
		$targetCandidates = GetUserSetting("WhoCanShareHostOnlyValue")
		If $targetCandidates = "" Then $targetCandidates = "Hôte seulement|Host only"
	EndIf
	Local $oTarget = _FindElementByAnyName($targetCandidates, $aListItemTypes, $oZoomWindow)
	If Not IsObj($oTarget) Then
		ReportUserFacingError("Could not find target 'Who can share' option: " & $targetCandidates)
		Return False
	EndIf
	If Not _ClickElement($oTarget, True) Then Return False

	Return True
EndFunc   ;==>SetShareScreenPermission

; Sets a security setting to the desired state (enabled/disabled)
; @param $sSetting - Setting name to modify
; @param $bDesired - Desired state (True=enabled, False=disabled)
Func SetSecuritySetting($sSetting, $bDesired)
	Debug(t("INFO_SETTING_SECURITY", $sSetting), "INFO")

	; Share-screen permission is now under Share Options -> Host tools for sharing -> Who can share.
	If $sSetting = GetUserSetting("ZoomSecurityShareScreenValue") Then
		Return SetShareScreenPermission($bDesired)
	EndIf

	Local $oSetting = EnsureSecurityToggleVisible($sSetting)
	If Not IsObj($oSetting) Then Return False

	; Determine current state. Prefer UIA toggle state when available, fallback to label parsing.
	Local $bEnabled = False
	Local $toggleState
	$oSetting.GetCurrentPropertyValue($UIA_ToggleToggleStatePropertyId, $toggleState)
	If Not @error And IsNumber($toggleState) Then
		$bEnabled = ($toggleState = 1) ; 0=Off, 1=On, 2=Indeterminate
	Else
		Local $sLabel = ""
		$oSetting.GetCurrentPropertyValue($UIA_NamePropertyId, $sLabel)
		Local $uncheckedValue = GetUserSetting("UncheckedValue")
		$bEnabled = (StringInStr(StringLower($sLabel), StringLower($uncheckedValue)) = 0)
	EndIf

	If $bEnabled = $bDesired Then
		Debug("Security setting already in desired state: " & $sSetting, "VERBOSE")
		_CloseHostTools()
		Return True
	EndIf

	_HoverElement($oSetting, 50)
	If Not _MoveMouseToStartOfElement($oSetting, True) Then
		ReportUserFacingError("Could not toggle security setting: " & $sSetting)
		Return False
	EndIf
	Sleep(250)
	Debug("Toggled security setting '" & $sSetting & "'", "SETTING CHANGE")
	Return True
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
