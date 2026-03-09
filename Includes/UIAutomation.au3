#include-once
; ================================================================================================
; UI AUTOMATION - UI element discovery and window management
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UIA_Functions-a.au3"

; ================================================================================================
; ZOOM WINDOW AND UI ELEMENT DISCOVERY
; ================================================================================================

; Finds UI element by class name within a specified scope
; @param $sClassName - Class name to search for
; @param $iScope - Search scope (default: descendants)
; @param $oParent - Parent element to search within (default: desktop)
; @return Object - Found element or 0 if not found
Func FindElementByClassName($sClassName, $iScope = Default, $oParent = Default)
	Debug("Searching for element with class: '" & $sClassName & "'", "VERBOSE")

	; Use desktop as default parent if not specified
	Local $oSearchParent = $oDesktop
	If $oParent <> Default Then $oSearchParent = $oParent

	; Create condition for class name search
	Local $pClassCondition
	$oUIAutomation.CreatePropertyCondition($UIA_ClassNamePropertyId, $sClassName, $pClassCondition)

	; Perform the search
	Local $pElement
	Local $scope = $TreeScope_Descendants
	If $iScope <> Default Then $scope = $iScope
	$oSearchParent.FindFirst($scope, $pClassCondition, $pElement)

	; Create element interface
	Local $oElement = ObjCreateInterface($pElement, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
	If Not IsObj($oElement) Then
		Debug("Element with class '" & $sClassName & "' not found.", "WARN")
		Return 0
	EndIf

	Debug("Element with class '" & $sClassName & "' found.", "VERBOSE")
	Return $oElement
EndFunc   ;==>FindElementByClassName

; Gets reference to the main Zoom meeting window
; @return Object - Zoom window element or error
Func _GetZoomWindow()
	$oZoomWindow = FindElementByClassName("ConfMultiTabContentWndClass", $TreeScope_Children)
	If Not IsObj($oZoomWindow) Then
		Debug(t("ERROR_ZOOM_WINDOW_NOT_FOUND"), "ERROR")
		Return SetError(1, 0, 0)
	EndIf
	Debug("Zoom window obtained.", "UIA")
	Return $oZoomWindow
EndFunc   ;==>_GetZoomWindow

; Internal function to find Zoom window (used by cache)
Func _FindZoomWindowInternal()
	Return FindElementByClassName("ConfMultiTabContentWndClass", $TreeScope_Children)
EndFunc   ;==>_FindZoomWindowInternal

; Focuses the main Zoom meeting window
; @return Boolean - True if successful, False otherwise
Func FocusZoomWindow($oWindow = Default)
	Debug("Focusing Zoom window...", "VERBOSE")

	; Reuse already-resolved window object when provided/cached to avoid refetch races.
	Local $oWindowToFocus = 0
	If $oWindow <> Default And IsObj($oWindow) Then
		$oWindowToFocus = $oWindow
	ElseIf IsObj($oZoomWindow) Then
		$oWindowToFocus = $oZoomWindow
	Else
		$oWindowToFocus = _GetZoomWindow()
	EndIf

	If Not IsObj($oWindowToFocus) Then Return False

	; Get the native HWND property from the UIA element
	Local $hWnd
	$oWindowToFocus.GetCurrentPropertyValue($UIA_NativeWindowHandlePropertyId, $hWnd)

	If $hWnd And $hWnd <> 0 Then
		; Convert to HWND pointer
		$hWnd = Ptr($hWnd)
		WinActivate($hWnd)
		If WinWaitActive($hWnd, "", 3) Then
			Debug("Zoom window activated and focused.", "VERBOSE")
			Return True
		Else
			Debug(t("ERROR_ZOOM_WINDOW_NOT_FOUND"), "ERROR")
		EndIf
	Else
		Debug(t("ERROR_ZOOM_WINDOW_NOT_FOUND"), "ERROR")
	EndIf

	Return False
EndFunc   ;==>FocusZoomWindow


; Snaps the Zoom window to a side of the primary monitor using Windows snap shortcuts
; @return Boolean - True if moved, False otherwise
Func _SnapZoomWindowToSide()
	Local $snapSide = GetUserSetting("SnapZoomSide")
	If StringLower($snapSide) = "disabled" Then
		Debug("Zoom window snapping disabled; skipping.", "VERBOSE")
		Return False
	EndIf

	_GetZoomWindow()
	If Not IsObj($oZoomWindow) Then Return False

	; Activate the Zoom window first using the proper focus function
	If Not FocusZoomWindow() Then Return False

	; Check if window is already snapped to the desired side (with tolerance for taskbar/borders)
	Local $aBoundingRect
	$oZoomWindow.GetCurrentPropertyValue($UIA_BoundingRectanglePropertyId, $aBoundingRect)

	Debug("UIA Bounding Rectangle: " & $aBoundingRect & " (raw)", "VERBOSE")

	If IsArray($aBoundingRect) And UBound($aBoundingRect) >= 4 Then
		; UIA BoundingRectangle format: [left, top, width, height]
		Local $iLeft = $aBoundingRect[0]
		Local $iTop = $aBoundingRect[1]
		Local $iWidth = $aBoundingRect[2]
		Local $iHeight = $aBoundingRect[3]

		Debug("Parsed position - X:" & $iLeft & " Y:" & $iTop & " W:" & $iWidth & " H:" & $iHeight, "VERBOSE")

		Local $iScreenWidth = @DesktopWidth
		Local $iScreenHeight = @DesktopHeight

		; Calculate expected positions for snapped windows (with 50px tolerance for borders/taskbar)
		Local $iTolerance = $SNAP_TOLERANCE_PX
		Local $iHalfWidth = $iScreenWidth / 2

		Debug("Window position check - X:" & $iLeft & " Y:" & $iTop & " W:" & $iWidth & " H:" & $iHeight & " | Screen:" & $iScreenWidth & "x" & $iScreenHeight & " | Half:" & $iHalfWidth & " | Tolerance:" & $iTolerance, "VERBOSE")

		Local $bIsLeftSnapped = ($iLeft <= $iTolerance And _
				$iTop >= -$iTolerance And $iTop <= $iTolerance And _
				Abs($iWidth - $iHalfWidth) <= $iTolerance And _
				Abs($iHeight - $iScreenHeight) <= $iTolerance)

		Local $bIsRightSnapped = ($iLeft >= $iHalfWidth - $iTolerance And _
				$iLeft <= $iHalfWidth + $iTolerance And _
				$iTop >= -$iTolerance And $iTop <= $iTolerance And _
				Abs($iWidth - $iHalfWidth) <= $iTolerance And _
				Abs($iHeight - $iScreenHeight) <= $iTolerance)

		Debug("Position analysis - LeftSnapped:" & $bIsLeftSnapped & " RightSnapped:" & $bIsRightSnapped & " | TargetSide:" & $snapSide, "VERBOSE")

		If StringLower($snapSide) = "left" And $bIsLeftSnapped Then
			Debug("Zoom window already snapped to left side; skipping.", "VERBOSE")
			Return True
		ElseIf StringLower($snapSide) = "right" And $bIsRightSnapped Then
			Debug("Zoom window already snapped to right side; skipping.", "VERBOSE")
			Return True
		EndIf
	Else
		Debug("Failed to get UIA BoundingRectangle - IsArray:" & IsArray($aBoundingRect) & " UBound:" & (IsArray($aBoundingRect) ? UBound($aBoundingRect) : "N/A"), "WARN")
	EndIf

	; Use Windows snap shortcuts instead of manual positioning
	If StringLower($snapSide) = "left" Then
		Send("#{LEFT}") ; Windows + Left arrow
		Debug("Sent Windows+Left to snap Zoom window to left half", "VERBOSE")
	ElseIf StringLower($snapSide) = "right" Then
		Send("#{RIGHT}") ; Windows + Right arrow
		Debug("Sent Windows+Right to snap Zoom window to right half", "VERBOSE")
	Else
		Debug(t("ERROR_INVALID_SNAP_SELECTION", $snapSide), "ERROR")
		Return False
	EndIf

	; Wait 0.5 seconds for snap animation to complete
	Sleep($WINDOW_SNAP_DELAY_MS)

	; Send Escape to dismiss any remaining Windows snap UI
	Send("{ESC}")
	Debug("Sent Escape to dismiss Windows snap UI", "VERBOSE")

	Debug("Zoom window snapped to " & $snapSide & " half of primary monitor using Windows shortcuts.", "VERBOSE")
	Return True
EndFunc   ;==>_SnapZoomWindowToSide


; Finds UI element by partial name match across multiple control types
; @param $sPartial - Partial text to search for in element names
; @param $aControlTypes - Array of control types to search (default: button and menu item)
; @param $oParent - Parent element to search within (default: desktop)
; @return Object - Found element or 0 if not found
Func FindElementByPartialName($sPartial, $aControlTypes = Default, $oParent = Default)
	Debug("Searching for element containing: '" & $sPartial & "'", "VERBOSE")

	; Use desktop as default parent if not specified
	Local $oSearchParent = $oDesktop
	If $oParent <> Default Then
		$oSearchParent = $oParent
		Debug("Using custom parent element for search", "VERBOSE")
	Else
		Debug("Using desktop as search parent", "VERBOSE")
	EndIf

	; Default to button and menu item if not specified
	If $aControlTypes = Default Then
		Local $aDefaultTypes[2] = [$UIA_ButtonControlTypeId, $UIA_MenuItemControlTypeId]
		$aControlTypes = $aDefaultTypes
	EndIf

	; Search through each specified control type
	For $iType = 0 To UBound($aControlTypes) - 1
		Local $iControlType = $aControlTypes[$iType]
		Debug("Searching control type: " & $iControlType)

		; Create condition for this control type
		Local $pCondition
		$oUIAutomation.CreatePropertyCondition($UIA_ControlTypePropertyId, $iControlType, $pCondition)

		; Find all elements of this type
		Local $pElements
		$oSearchParent.FindAll($TreeScope_Descendants, $pCondition, $pElements)

		Local $oElements = ObjCreateInterface($pElements, $sIID_IUIAutomationElementArray, $dtagIUIAutomationElementArray)
		If IsObj($oElements) Then
			Local $iCount
			$oElements.Length($iCount)
			Debug("Found " & $iCount & " elements of this type.", "VERBOSE")

			; Check each element for partial name match
			For $i = 0 To $iCount - 1
				Local $pElement
				$oElements.GetElement($i, $pElement)

				Local $oElement = ObjCreateInterface($pElement, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
				If IsObj($oElement) Then
					; Get element name and check for partial match
					Local $sName
					$oElement.GetCurrentPropertyValue($UIA_NamePropertyId, $sName)
					Debug("Element found with name: '" & $sName & "'", "VERBOSE")

					If StringInStr($sName, $sPartial, $STR_NOCASESENSEBASIC) > 0 Then
						Debug("Matching element found with name: '" & $sName & "'", "VERBOSE")
						Return $oElement
					EndIf
				EndIf
			Next
		EndIf
	Next

	Debug("No element found containing: '" & $sPartial & "'", "WARN")
	Return 0
EndFunc   ;==>FindElementByPartialName

; Recursively prints element name + children
Func _PrintElementTree($oElem, $level = 0)
	If Not IsObj($oElem) Then Return

	; Get element name
	Local $sName = ""
	$oElem.GetCurrentPropertyValue($UIA_NamePropertyId, $sName)

	; Print with indentation
	Local $indent = StringFormat("%" & ($level * 2) & "s", "")
	Debug($indent & "- " & $sName, "TREE")

	; Get children (no condition)
	Local $pChildren
	$oElem.FindAll($TreeScope_Children, 0, $pChildren)

	Local $oChildren = ObjCreateInterface($pChildren, $sIID_IUIAutomationElementArray, $dtagIUIAutomationElementArray)
	If Not IsObj($oChildren) Then Return

	Local $childCount
	$oChildren.Length($childCount)

	For $i = 0 To $childCount - 1
		Local $pChild
		$oChildren.GetElement($i, $pChild)

		Local $oChild = ObjCreateInterface($pChild, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
		If IsObj($oChild) Then
			_PrintElementTree($oChild, $level + 1)
		EndIf
	Next
EndFunc   ;==>_PrintElementTree
