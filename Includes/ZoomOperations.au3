#include-once
; ================================================================================================
; ZOOM OPERATIONS - Zoom-specific menu and panel operations
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "ElementActions.au3"

; Note: ResponsiveSleep function - looks like Sleep with delay calculation
; Using Sleep directly since ResponsiveSleep is not defined in codebase

; ================================================================================================
; ZOOM-SPECIFIC UI INTERACTION FUNCTIONS
; ================================================================================================


; Attempts to locate the Host Tools container in either legacy flyout or new side panel layouts.
; @return Object - Host tools container scope or 0
Func _FindHostToolsContainer()
	If Not IsObj($oZoomWindow) Then Return 0

	; Legacy popup/flyout menu
	Local $oHostMenu = FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)
	If IsObj($oHostMenu) Then Return $oHostMenu

	; New host tools panel often appears as Pane/Group/Window labeled like Host Tools
	Local $aPanelTypes[3] = [$UIA_PaneControlTypeId, $UIA_GroupControlTypeId, $UIA_WindowControlTypeId]
	Local $oHostPanel = FindElementByPartialName(GetUserSetting("HostToolsValue"), $aPanelTypes, $oZoomWindow)
	If IsObj($oHostPanel) Then Return $oHostPanel

	Return 0
EndFunc   ;==>_FindHostToolsContainer

; Opens the Host Tools menu in Zoom
; @return Object - Host menu object or False if failed
Func _OpenHostTools()
	If Not IsObj($oZoomWindow) Then Return False

	; Check if host tools are already open (legacy or new layout)
	Local $oHostContainer = _FindHostToolsContainer()
	If IsObj($oHostContainer) Then Return $oHostContainer

	; Controls might be hidden, show them by moving the mouse
	Debug("Controls might be hidden. Moving mouse to show controls.", "VERBOSE")
	Local $oResolvedZoomWindow = _GetZoomWindow()
	If Not IsObj($oResolvedZoomWindow) Then Return False
	_MoveMouseToStartOfElement($oZoomWindow, True)

	; First attempt: Host Tools button directly on toolbar
	Local $aToolbarTypes[1] = [$UIA_ButtonControlTypeId]
	Local $oHostToolsButton = FindElementByPartialName(GetUserSetting("HostToolsValue"), $aToolbarTypes, $oZoomWindow)
	If IsObj($oHostToolsButton) Then
		Debug("Host Tools button found directly; clicking.", "VERBOSE")
		; Force click works better for the main toolbar Host Tools button (btn_security)
		If Not _ClickElement($oHostToolsButton, True) Then
			Debug("Direct Host Tools click failed; trying More-menu fallback.", "WARN")
		Else
			Sleep(700)
			$oHostContainer = _FindHostToolsContainer()
			If IsObj($oHostContainer) Then Return $oHostContainer
			Debug("Direct Host Tools click did not open a Host Tools container; trying More-menu fallback.", "VERBOSE")
		EndIf
	EndIf

	; Second attempt: open More menu then Host Tools
	Debug("Host Tools button not found/active, looking for 'More' button.", "VERBOSE")
	Local $oMoreMenu = GetMoreMenu()
	Local $aMoreMenuTypes[3] = [$UIA_TabItemControlTypeId, $UIA_ButtonControlTypeId, $UIA_MenuItemControlTypeId]
	If IsObj($oMoreMenu) Then
		; In newer Zoom builds this is often a TabItem with a long localized name.
		Local $oHostToolsMenuItem = FindElementByPartialName(GetUserSetting("HostToolsValue"), $aMoreMenuTypes, $oMoreMenu)
		If IsObj($oHostToolsMenuItem) Then
			Debug("Found Host Tools item in More. Clicking it.", "VERBOSE")
			If Not _ClickElement($oHostToolsMenuItem, True) Then
				; some builds require hover first then click
				_HoverElement($oHostToolsMenuItem, 400)
				_MoveMouseToStartOfElement($oHostToolsMenuItem, True)
			EndIf
			Sleep(700)
			$oHostContainer = _FindHostToolsContainer()
			If IsObj($oHostContainer) Then Return $oHostContainer
		EndIf
	Else
		; Fallback: some layouts expose More content in a non-modeless window tree.
		Local $oHostToolsFromZoom = FindElementByPartialName(GetUserSetting("HostToolsValue"), $aMoreMenuTypes, $oZoomWindow)
		If IsObj($oHostToolsFromZoom) Then
			Debug("Found Host Tools item from Zoom window tree fallback. Clicking it.", "VERBOSE")
			_ClickElement($oHostToolsFromZoom, True)
			Sleep(700)
			$oHostContainer = _FindHostToolsContainer()
			If IsObj($oHostContainer) Then Return $oHostContainer
		EndIf
	EndIf

	Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("HostToolsValue")), "ERROR")
	Return False
EndFunc   ;==>_OpenHostTools

; Internal function to find Host menu (used by cache)
Func _FindHostMenuInternal()
	Return _FindHostToolsContainer()
EndFunc   ;==>_FindHostMenuInternal

; Closes the Host Tools menu by clicking on the main window
Func _CloseHostTools()
	Debug(t("INFO_CLOSE_HOST_TOOLS"), "INFO")
	_MoveMouseToStartOfElement($oZoomWindow, True) ; Click at start of window to ensure menu closes
EndFunc   ;==>_CloseHostTools

; Opens the "More" menu in Zoom if available
; @return Object - More menu object or False if failed
Func GetMoreMenu()
	Debug(t("INFO_GET_MORE_MENU"), "INFO")
	If Not IsObj($oZoomWindow) Then Return False

	Local $oMoreMenu = FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)

	If Not IsObj($oMoreMenu) Then
		; Menu not open, find and click the More button
		Debug("More menu not open, attempting to open.", "VERBOSE")
		Debug("Controls might be hidden. Moving mouse to show controls.", "VERBOSE")
		_MoveMouseToStartOfElement($oZoomWindow)

		Local $oMoreButton = FindElementByPartialName(GetUserSetting("MoreMeetingControlsValue"), Default, $oZoomWindow)
		If Not IsObj($oMoreButton) Then
			Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("MoreMeetingControlsValue")), "ERROR")
			Return False
		EndIf
		Debug("Clicking More button to open menu.", "VERBOSE")
		If Not _ClickElement($oMoreButton, True) Then
			Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("MoreMeetingControlsValue")), "ERROR")
			Return False
		EndIf
		; Wait briefly for the More menu to open
		Sleep(500)
	EndIf

	; Return the now-open More menu
	$oMoreMenu = FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)
	If IsObj($oMoreMenu) Then
		Debug("More menu opened.", "UIA")
	Else
		Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("MoreMeetingControlsValue")), "ERROR")
	EndIf
	Return $oMoreMenu
EndFunc   ;==>GetMoreMenu

; Internal function to find More menu (used by cache)
Func _FindMoreMenuInternal()
	Return FindElementByClassName("WCN_ModelessWnd", Default, $oZoomWindow)
EndFunc   ;==>_FindMoreMenuInternal

; Opens the Participants panel in Zoom
; @return Object - Participants panel object or False if failed
Func _OpenParticipantsPanel()
	Debug(t("INFO_OPEN_PARTICIPANTS_PANEL"), "INFO")
	If Not IsObj($oZoomWindow) Then Return False

	; Controls might be hidden, show them by moving the mouse
	Debug("Controls might be hidden. Moving mouse to show controls.", "VERBOSE")
	_MoveMouseToStartOfElement($oZoomWindow)

	Local $ListType[1] = [$UIA_ListControlTypeId]
	Local $oParticipantsPanel = FindElementByPartialName(GetUserSetting("ParticipantValue"), $ListType, $oZoomWindow)

	If Not IsObj($oParticipantsPanel) Then
		; Panel not open, find and click the Participants button
		Debug("Participants panel not open, attempting to open.", "UIA")
		Local $oMainParticipantsButton = FindElementByPartialName(GetUserSetting("ParticipantValue"), Default, $oZoomWindow)

		; Scenario 1: Try to find Participants button directly
		If IsObj($oMainParticipantsButton) Then
			Debug("Participants button found directly; clicking.", "VERBOSE")
			If Not _ClickElement($oMainParticipantsButton) Then
				Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("ParticipantValue")), "ERROR")
				Return False
			EndIf
		Else
			; Scenario 2: Try to find More menu, then Participants
			Debug("Participants button not found, looking for 'More' button.", "VERBOSE")
			Local $oMoreMenu = GetMoreMenu()
			If IsObj($oMoreMenu) Then
				; Now look for the Participants button in the More menu
				Local $oParticipantsMenuItem = FindElementByPartialName(GetUserSetting("ParticipantValue"), Default, $oMoreMenu)
				If IsObj($oParticipantsMenuItem) Then
					Debug("Found Participants menu item. Hovering it to open submenu.", "VERBOSE")
					If _HoverElement($oParticipantsMenuItem, 1200) Then         ; 1.2s hover to ensure submenu appears
						; Now look for the Participants button again in the submenu
						Debug("Looking for Participants button again in submenu.", "VERBOSE")
						Local $oParticipantsSubMenuItem = FindElementByPartialName(GetUserSetting("ParticipantValue"), Default, $oZoomWindow)
						If IsObj($oParticipantsSubMenuItem) Then
							Debug("Final Participants button found. Clicking it.", "VERBOSE")
							_HoverElement($oParticipantsSubMenuItem, 500)
							_MoveMouseToStartOfElement($oParticipantsSubMenuItem, True)
							Debug("Participants button clicked.", "VERBOSE")
							Sleep(500) ; Move mouse to start of element and click to avoid hover issues
						Else
							Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("ParticipantValue")), "ERROR")
							Return False
						EndIf
					Else
						Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("ParticipantValue")), "ERROR")
						Return False
					EndIf
				Else
					Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("ParticipantValue")), "ERROR")
					Return False
				EndIf
			Else
				Debug(t("ERROR_FAILED_CLICK_ELEMENT", GetUserSetting("ParticipantValue")), "ERROR")
				Return False
			EndIf
		EndIf
	EndIf

	; Return the now-open participants panel
	$oParticipantsPanel = FindElementByPartialName(GetUserSetting("ParticipantValue"), $ListType, $oZoomWindow)
	If IsObj($oParticipantsPanel) Then
		Debug("Participants panel opened.", "UIA")
		_SnapZoomWindowToSide()
	Else
		Debug(t("ERROR_FAILED_OPEN_PANEL", GetUserSetting("ParticipantValue")), "ERROR")
	EndIf
	Return $oParticipantsPanel
EndFunc   ;==>_OpenParticipantsPanel

; Internal function to find Participants panel (used by cache)
Func _FindParticipantsPanelInternal()
	Local $ListType[1] = [$UIA_ListControlTypeId]
	Return FindElementByPartialName(GetUserSetting("ParticipantValue"), $ListType, $oZoomWindow)
EndFunc   ;==>_FindParticipantsPanelInternal
