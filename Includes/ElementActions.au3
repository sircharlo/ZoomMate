#include-once
; ================================================================================================
; ELEMENT ACTIONS - UI element interaction methods
; ================================================================================================

#include "Globals.au3"
#include "i18n.au3"
#include "Utils.au3"
#include "UIA_Functions-a.au3"

; ================================================================================================
; UI ELEMENT INTERACTION FUNCTIONS
; ================================================================================================

; Clicks a UI element using multiple methods for maximum compatibility with timeout protection
; @param $oElement - Element to click
; @param $ForceClick - If True, forces mouse click method
; @param $BoundingRectangle - If True, forces click by bounding rectangle
; @param $iTimeoutMs - Timeout in milliseconds (default: 5000)
; @return Boolean - True if successful, False otherwise
Func _ClickElement($oElement, $ForceClick = False, $BoundingRectangle = False, $iTimeoutMs = $CLICK_TIMEOUT_MS)
	Sleep(500) ; Brief pause to ensure UI is ready
	Local $iStartTime = TimerInit()

	If Not IsObj($oElement) Then
		Debug(t("ERROR_INVALID_ELEMENT_OBJECT"), "WARN")
		Return False
	EndIf

	; Get element name for debugging
	Local $sElementName = GetElementName($oElement)
	Debug("Attempting to click element: '" & $sElementName & "'", "VERBOSE")

	; Method 0: Force mouse click (only when requested)
	If $ForceClick Then
		; Method 0.5: Force mouse click by bounding rectangle (only when requested)
		If $BoundingRectangle Then
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			If Not ClickByBoundingRectangle($oElement) Then
				Return False
			EndIf
			Debug("Element clicked via bounding rectangle.", "VERBOSE")
		Else
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			UIA_MouseClick($oElement)
			Debug("Element clicked via UIA_MouseClick.", "VERBOSE")
		EndIf
		Return True
	EndIf

	; Method 1: Try Invoke Pattern (works for most buttons)
	Local $pInvokePattern, $oInvokePattern
	$oElement.GetCurrentPattern($UIA_InvokePatternId, $pInvokePattern)
	If $pInvokePattern Then
		$oInvokePattern = ObjCreateInterface($pInvokePattern, $sIID_IUIAutomationInvokePattern, $dtagIUIAutomationInvokePattern)
		If IsObj($oInvokePattern) Then
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			Debug("Using Invoke pattern for: '" & $sElementName & "'", "VERBOSE")
			$oInvokePattern.Invoke()
			Debug("Element clicked via Invoke pattern.", "VERBOSE")
			Return True
		EndIf
	EndIf

	; Method 2: Try Legacy Accessible Pattern (works for menu items and older controls)
	Local $pLegacyPattern, $oLegacyPattern
	$oElement.GetCurrentPattern($UIA_LegacyIAccessiblePatternId, $pLegacyPattern)
	If $pLegacyPattern Then
		$oLegacyPattern = ObjCreateInterface($pLegacyPattern, $sIID_IUIAutomationLegacyIAccessiblePattern, $dtagIUIAutomationLegacyIAccessiblePattern)
		If IsObj($oLegacyPattern) Then
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			Debug("Using LegacyAccessible pattern for: '" & $sElementName & "'", "VERBOSE")
			$oLegacyPattern.DoDefaultAction()
			Debug("Element clicked via LegacyAccessible pattern.", "VERBOSE")
			Return True
		EndIf
	EndIf

	; Method 3: Try Selection Item Pattern (for selectable menu items)
	Local $pSelectionItemPattern, $oSelectionItemPattern
	$oElement.GetCurrentPattern($UIA_SelectionItemPatternId, $pSelectionItemPattern)
	If $pSelectionItemPattern Then
		$oSelectionItemPattern = ObjCreateInterface($pSelectionItemPattern, $sIID_IUIAutomationSelectionItemPattern, $dtagIUIAutomationSelectionItemPattern)
		If IsObj($oSelectionItemPattern) Then
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			Debug("Using SelectionItem pattern for: '" & $sElementName & "'", "VERBOSE")
			$oSelectionItemPattern.Select()
			Debug("Element selected via SelectionItem pattern.", "VERBOSE")
			Return True
		EndIf
	EndIf

	; Method 4: Try Toggle Pattern (for toggle buttons/menu items)
	Local $pTogglePattern, $oTogglePattern
	$oElement.GetCurrentPattern($UIA_TogglePatternId, $pTogglePattern)
	If $pTogglePattern Then
		$oTogglePattern = ObjCreateInterface($pTogglePattern, $sIID_IUIAutomationTogglePattern, $dtagIUIAutomationTogglePattern)
		If IsObj($oTogglePattern) Then
			If TimerDiff($iStartTime) > $iTimeoutMs Then
				Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
				Return False
			EndIf
			Debug("Using Toggle pattern for: '" & $sElementName & "'", "VERBOSE")
			$oTogglePattern.Toggle()
			Debug("Element toggled via Toggle pattern.", "VERBOSE")
			Return True
		EndIf
	EndIf

	; Method 5: Fallback - Mouse click at element center
	If TimerDiff($iStartTime) > $iTimeoutMs Then
		Debug("Click operation timed out after " & $iTimeoutMs & "ms", "VERBOSE")
		Return False
	EndIf
	If Not ClickByBoundingRectangle($oElement) Then
		Return False
	EndIf

	; All click methods failed
	Debug(t("ERROR_FAILED_CLICK_ELEMENT") & ": '" & $sElementName & "'", "VERBOSE")
	Return False
EndFunc   ;==>_ClickElement

Func ClickByBoundingRectangle($oElement)
	; Method 0.1: Click by bounding rectangle center
	Local $sElementName = GetElementName($oElement)
	Local $tRect
	$oElement.GetCurrentPropertyValue($UIA_BoundingRectanglePropertyId, $tRect)
	UIA_GetArrayPropertyValueAsString($tRect)
	Debug("Element bounding rectangle: " & $tRect, "VERBOSE")
	If Not $tRect Then
		Debug("No bounding rectangle for element: '" & $sElementName & "'", "VERBOSE")
		Return False
	EndIf

	Local $aRect = StringSplit($tRect, ",")
	If $aRect[0] < 4 Then
		Debug("Invalid rectangle format for: '" & $sElementName & "'", "VERBOSE")
		Return False
	EndIf

	Local $iLeft = Number($aRect[1])
	Local $iTop = Number($aRect[2])
	Local $iWidth = Number($aRect[3])
	Local $iHeight = Number($aRect[4])

	Local $iCenterX = $iLeft + ($iWidth / 2)
	Local $iCenterY = $iTop + ($iHeight / 2)

	Debug("Using mouse click fallback at position: " & $iCenterX & "," & $iCenterY & " for: '" & $sElementName & "'", "VERBOSE")

	; Ensure element is clickable before attempting
	Local $bIsEnabled, $bIsOffscreen
	$oElement.GetCurrentPropertyValue($UIA_IsEnabledPropertyId, $bIsEnabled)
	$oElement.GetCurrentPropertyValue($UIA_IsOffscreenPropertyId, $bIsOffscreen)

	If $bIsEnabled And Not $bIsOffscreen Then
		MouseClick("primary", $iCenterX, $iCenterY, 1, 0)
		Debug("Element clicked via mouse at center.", "VERBOSE")
		Return True
	Else
		Debug("Element not clickable - Enabled: " & $bIsEnabled & ", Offscreen: " & $bIsOffscreen, "WARN")
		Return False
	EndIf
EndFunc   ;==>ClickByBoundingRectangle


; Gets the name property of a UI element
; @param $oElement - The UI element object
; @return String - Element name or empty string if not found
Func GetElementName($oElement)
	Local $sName = ""
	If IsObj($oElement) Then
		$oElement.GetCurrentPropertyValue($UIA_NamePropertyId, $sName)
	EndIf
	Return $sName
EndFunc   ;==>GetElementName


; Hovers over a UI element by moving the mouse to its center
; @param $oElement - The UIA element object
; @param $iHoverTime - Time in milliseconds to hold the hover (default: 1000ms)
; @param $SlightOffset - If True, adds slight random offset to avoid exact center
; @return Boolean - True if successful, False otherwise
Func _HoverElement($oElement, $iHoverTime = $HOVER_DEFAULT_MS, $SlightOffset = False)
	Sleep(300) ; Small buffer before hover
	If Not IsObj($oElement) Then
		Debug("Invalid element passed to _HoverElement", "WARN")
		Return False
	EndIf

	; Get element name for debugging
	Local $sElementName = GetElementName($oElement)
	Debug("Attempting to hover element: '" & $sElementName & "'", "VERBOSE")

	; Get bounding rectangle
	Local $tRect
	$oElement.GetCurrentPropertyValue($UIA_BoundingRectanglePropertyId, $tRect)
	UIA_GetArrayPropertyValueAsString($tRect)
	Debug("Element bounding rectangle: " & $tRect, "VERBOSE")
	If Not $tRect Then
		Debug("No bounding rectangle for element: '" & $sElementName & "'", "WARN")
		Return False
	EndIf

	Local $aRect = StringSplit($tRect, ",")
	If $aRect[0] < 4 Then
		Debug("Invalid rectangle format for: '" & $sElementName & "'", "WARN")
		Return False
	EndIf

	Local $iLeft = Number($aRect[1])
	Local $iTop = Number($aRect[2])
	Local $iWidth = Number($aRect[3])
	Local $iHeight = Number($aRect[4])

	Local $iCenterX = $iLeft + ($iWidth / 2)
	Local $iCenterY = $iTop + ($iHeight / 2)

	If $SlightOffset Then
		; Add slight random offset to avoid exact center (may help with some UI elements)
		Local $iOffsetX = Random(2, 5, 1)
		Local $iOffsetY = Random(-5, -2, 1)
		$iCenterX += $iOffsetX
		$iCenterY += $iOffsetY
		Debug("Applying slight offset to hover position: " & $iOffsetX & "," & $iOffsetY, "VERBOSE")
	EndIf

	Debug("Hovering at: " & $iCenterX & "," & $iCenterY & " for " & $iHoverTime & "ms", "VERBOSE")

	; Move mouse to center of element and hold position
	MouseMove($iCenterX, $iCenterY, 0)
	Sleep($iHoverTime)

	Debug("Hover completed on element: '" & $sElementName & "'", "VERBOSE")
	Return True
EndFunc   ;==>_HoverElement

; Moves mouse to the start of an element and optionally clicks it
; @param $oElement - The UIA element object
; @param $Click - If True, performs a click after moving (default: False)
; @return Boolean - True if successful, False otherwise
Func _MoveMouseToStartOfElement($oElement, $Click = False)
	Sleep(300) ; Small buffer before move
	If Not IsObj($oElement) Then
		Debug("Invalid element passed to _MoveMouseToStartOfElement", "WARN")
		Return False
	EndIf

	; Get element name for debugging
	Local $sElementName = GetElementName($oElement)
	Debug("Attempting to move mouse to start of element: '" & $sElementName & "'", "VERBOSE")

	; Get bounding rectangle
	Local $tRect
	$oElement.GetCurrentPropertyValue($UIA_BoundingRectanglePropertyId, $tRect)
	UIA_GetArrayPropertyValueAsString($tRect)
	Debug("Element bounding rectangle: " & $tRect, "VERBOSE")
	If Not $tRect Then
		Debug("No bounding rectangle for element: '" & $sElementName & "'", "WARN")
		Return False
	EndIf

	Local $aRect = StringSplit($tRect, ",")
	If $aRect[0] < 4 Then
		Debug("Invalid rectangle format for: '" & $sElementName & "'", "WARN")
		Return False
	EndIf

	Local $iLeft = Number($aRect[1])
	Local $iTop = Number($aRect[2])
;~ Local $iWidth = Number($aRect[3])
	Local $iHeight = Number($aRect[4])

	; Move mouse to start (left edge, vertically centered)
	Local $iStartX = $iLeft + Random(5, 30, 1) ; Random offset from left edge
	Local $iStartY = $iTop + ($iHeight / 2) + Random(-5, 5, 1) ; Random offset from center

	Debug("Moving mouse to start position: " & $iStartX & "," & $iStartY, "VERBOSE")

	; Move mouse to start of element
	MouseMove($iStartX, $iStartY, 0)
	Sleep(200) ; Brief pause after move
	Debug("Mouse moved to start of element: '" & $sElementName & "'", "VERBOSE")

	If $Click Then
		MouseClick("primary", $iStartX, $iStartY, 1, 0)
		Debug("Element clicked at start position.", "VERBOSE")
	EndIf

	Return True
EndFunc   ;==>_MoveMouseToStartOfElement
