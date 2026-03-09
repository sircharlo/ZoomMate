
#include-once

#include <WindowsStylesConstants.au3>
#include <Array.au3>
#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include <GuiRichEdit.au3>
#include <GuiMenu.au3>
#include <StaticConstants.au3>
#include <TrayConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include "Config.au3"
#include "Globals.au3"
#include "i18n.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "Utils.au3"
#include "ZoomOperations.au3"


; ================================================================================================
; CONFIGURATION GUI FUNCTIONS
; ================================================================================================

; Initializes day name to number mappings using translations
; Maps localized day names (DAY_1 through DAY_7) to numbers 1-7
Func _InitDayLabelMaps()
	; Clear existing mappings before reinitializing
	$g_DayLabelToNum.RemoveAll()
	$g_DayNumToLabel.RemoveAll()

	Local $i
	For $i = 1 To 7
		Local $key = "DAY_" & $i
		Local $label = t($key)
		If Not $g_DayLabelToNum.Exists($label) Then $g_DayLabelToNum.Add($label, $i)
		If Not $g_DayNumToLabel.Exists(String($i)) Then $g_DayNumToLabel.Add(String($i), $label)
		Debug("  " & $label & " -> " & $i, "VERBOSE")
	Next
	Debug("Day mappings initialized", "VERBOSE")
EndFunc   ;==>_InitDayLabelMaps

; Converts a localized day label to its numeric value (1-7)
; @param $label - Localized day name (e.g., "Monday", "Lundi", etc.)
; @return String - Day number as string (1-7), or empty string if not found
Func _GetDayNumFromLabel($label)
	If $g_DayLabelToNum.Exists($label) Then
		Return String($g_DayLabelToNum.Item($label))
	EndIf
	Return ""
EndFunc   ;==>_GetDayNumFromLabel


; Shows the configuration GUI for user to input settings
Func ShowConfigGUI()
	; If GUI already exists, just show it
	If $g_ConfigGUI Then
		GUICtrlSetState($g_ConfigGUI, @SW_SHOW)
		Return
	EndIf

	; Initialize day mappings for current language
	_InitDayLabelMaps()

	; Create main configuration window with initial estimated height
	Local $initialWidth = 640
	Local $initialHeight = 630
	$g_ConfigGUI = GUICreate(t("CONFIG_TITLE"), $initialWidth, $initialHeight)
	GUISetOnEvent($GUI_EVENT_CLOSE, "SaveConfigGUI", $g_ConfigGUI)

	Local $currentY = 10

	; ================================================================================================
	; SECTION 1: MEETING INFORMATION
	; ================================================================================================
	Local $idSection1 = _AddSectionHeader(t("SECTION_MEETING_INFO"), 10, $currentY)
	If Not $g_FieldLabels.Exists("Section1") Then $g_FieldLabels.Add("Section1", $idSection1)
	$currentY += 25

	; Meeting configuration fields
	_AddTextInputField("MeetingID", t("LABEL_MEETING_ID"), 10, $currentY, 300, $currentY, 200)
	$currentY += 30

	; Midweek meeting settings
	_AddDayDropdownField("MidweekDay", t("LABEL_MIDWEEK_DAY"), 10, $currentY, 300, $currentY, 200)
	$currentY += 30
	_AddTextInputField("MidweekTime", t("LABEL_MIDWEEK_TIME"), 10, $currentY, 300, $currentY, 200)
	$currentY += 40

	; Weekend meeting settings
	_AddDayDropdownField("WeekendDay", t("LABEL_WEEKEND_DAY"), 10, $currentY, 300, $currentY, 200)
	$currentY += 30
	_AddTextInputField("WeekendTime", t("LABEL_WEEKEND_TIME"), 10, $currentY, 300, $currentY, 200)
	$currentY += 40

	; Add separator line
	GUICtrlCreateLabel("", 10, $currentY, 620, 2)
	GUICtrlSetBkColor(-1, 0xCCCCCC)
	$currentY += 15

	; ================================================================================================
	; SECTION 2: ZOOM INTERFACE LABELS
	; ================================================================================================
	Local $idSection2 = _AddSectionHeader(t("SECTION_ZOOM_LABELS"), 10, $currentY)
	If Not $g_FieldLabels.Exists("Section2") Then $g_FieldLabels.Add("Section2", $idSection2)
	$currentY += 25

	; Zoom UI element text values (for internationalization support)
	_AddTextInputFieldWithTooltipAndLookup("HostToolsValue", t("LABEL_HOST_TOOLS"), 10, $currentY, 300, $currentY, 200, "LABEL_HOST_TOOLS_EXPLAIN", "host_tools.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("MoreMeetingControlsValue", t("LABEL_MORE_MEETING_CONTROLS"), 10, $currentY, 300, $currentY, 200, "LABEL_MORE_MEETING_CONTROLS_EXPLAIN", "more_meeting_controls.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("ParticipantValue", t("LABEL_PARTICIPANT"), 10, $currentY, 300, $currentY, 200, "LABEL_PARTICIPANT_EXPLAIN", "participant.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("MuteAllValue", t("LABEL_MUTE_ALL"), 10, $currentY, 300, $currentY, 200, "LABEL_MUTE_ALL_EXPLAIN", "mute_all.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("YesValue", t("LABEL_YES"), 10, $currentY, 300, $currentY, 200, "LABEL_YES_EXPLAIN", "yes.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("UncheckedValue", t("LABEL_UNCHECKED_VALUE"), 10, $currentY, 300, $currentY, 200, "LABEL_UNCHECKED_VALUE_EXPLAIN", "")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("CurrentlyUnmutedValue", t("LABEL_CURRENTLY_UNMUTED_VALUE"), 10, $currentY, 300, $currentY, 200, "LABEL_CURRENTLY_UNMUTED_VALUE_EXPLAIN", "")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("UnmuteAudioValue", t("LABEL_UNMUTE_AUDIO_VALUE"), 10, $currentY, 300, $currentY, 200, "LABEL_UNMUTE_AUDIO_VALUE_EXPLAIN", "")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("StopVideoValue", t("LABEL_STOP_VIDEO_VALUE"), 10, $currentY, 300, $currentY, 200, "LABEL_STOP_VIDEO_VALUE_EXPLAIN", "")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("StartVideoValue", t("LABEL_START_VIDEO_VALUE"), 10, $currentY, 300, $currentY, 200, "LABEL_START_VIDEO_VALUE_EXPLAIN", "")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("ZoomSecurityUnmuteValue", t("LABEL_ZOOM_SECURITY_UNMUTE"), 10, $currentY, 300, $currentY, 200, "LABEL_ZOOM_SECURITY_UNMUTE_EXPLAIN", "security_unmute.jpg")
	$currentY += 30
	_AddTextInputFieldWithTooltipAndLookup("ZoomSecurityShareScreenValue", t("LABEL_ZOOM_SECURITY_SHARE_SCREEN"), 10, $currentY, 300, $currentY, 200, "LABEL_ZOOM_SECURITY_SHARE_SCREEN_EXPLAIN", "security_share_screen.jpg")
	$currentY += 40

	; Add separator line
	GUICtrlCreateLabel("", 10, $currentY, 620, 2)
	GUICtrlSetBkColor(-1, 0xCCCCCC)
	$currentY += 15

	; ================================================================================================
	; SECTION 3: GENERAL SETTINGS
	; ================================================================================================
	Local $idSection3 = _AddSectionHeader(t("SECTION_GENERAL_SETTINGS"), 10, $currentY)
	If Not $g_FieldLabels.Exists("Section3") Then $g_FieldLabels.Add("Section3", $idSection3)
	$currentY += 25

	; Language selection dropdown
	Local $idLanguageLabel = GUICtrlCreateLabel(t("LABEL_LANGUAGE"), 10, $currentY, 200, 20)
	$idLanguagePicker = GUICtrlCreateCombo("", 300, $currentY, 200, 20)
	If Not $g_FieldLabels.Exists("Language") Then $g_FieldLabels.Add("Language", $idLanguageLabel)
	; Ensure translations are initialized before getting language list
	If $g_Languages.Count = 0 Then _InitializeTranslations()
	Local $langList = _ListAvailableLanguageNames()
	Local $currentLang = GetUserSetting("Language")
	If $currentLang = "" Then $currentLang = "en"
	Local $currentDisplay = _GetLanguageDisplayName($currentLang)
	GUICtrlSetData($idLanguagePicker, $langList, $currentDisplay)
	GUICtrlSetOnEvent($idLanguagePicker, "_OnLanguageChanged") ; Handle language change
	$currentY += 30

	; Snap Zoom to side (Disabled|Left|Right)
	Local $idSnapLabel = GUICtrlCreateLabel(t("LABEL_SNAP_ZOOM_TO"), 10, $currentY, 200, 20)
	Global $idSnapZoom = GUICtrlCreateCombo("", 300, $currentY, 200, 20)
	If Not $g_FieldLabels.Exists("SnapZoomSide") Then $g_FieldLabels.Add("SnapZoomSide", $idSnapLabel)
	Local $snapVal = GetUserSetting("SnapZoomSide")
	Local $snapDisplay = t("SNAP_DISABLED")
	If $snapVal = "Left" Then
		$snapDisplay = t("SNAP_LEFT")
	ElseIf $snapVal = "Right" Then
		$snapDisplay = t("SNAP_RIGHT")
	EndIf
	GUICtrlSetData($idSnapZoom, t("SNAP_DISABLED") & "|" & t("SNAP_LEFT") & "|" & t("SNAP_RIGHT"), $snapDisplay)
	If Not $g_FieldCtrls.Exists("SnapZoomSide") Then $g_FieldCtrls.Add("SnapZoomSide", $idSnapZoom)
	GUICtrlSetOnEvent($idSnapZoom, "CheckConfigFields")
	$currentY += 40

	_AddTextInputFieldWithTooltip("KeyboardShortcut", t("LABEL_KEYBOARD_SHORTCUT"), 10, $currentY, 300, $currentY, 200, "LABEL_KEYBOARD_SHORTCUT_EXPLAIN", '')
	$currentY += 40

	; Error display area (wider to match new GUI width)
	$g_ErrorAreaLabel = GUICtrlCreateLabel("", 10, $currentY, 620, 20)
	GUICtrlSetColor($g_ErrorAreaLabel, 0xFF0000) ; Red text for errors
	$currentY += 30

	; Action buttons (adjusted for wider GUI)
	Global $idSaveBtn = GUICtrlCreateButton(t("BTN_SAVE"), 10, $currentY, 100, 30)
	Global $idQuitBtn = GUICtrlCreateButton(t("BTN_QUIT"), 120, $currentY, 100, 30)
	$g_DiagnosticsBtn = GUICtrlCreateButton("UI Diagnostics", 230, $currentY, 110, 30)
	$g_PathWizardBtn = GUICtrlCreateButton("Path Wizard", 350, $currentY, 100, 30)
	$currentY += 30


	; Set initial button states
	GUICtrlSetState($idSaveBtn, $GUI_DISABLE)  ; Disabled until all fields valid
	GUICtrlSetState($idQuitBtn, $GUI_ENABLE)

	; Set button event handlers
	GUICtrlSetOnEvent($idSaveBtn, "SaveConfigGUI")
	GUICtrlSetOnEvent($idQuitBtn, "QuitApp")
	GUICtrlSetOnEvent($g_DiagnosticsBtn, "RunUIDiagnostics")
	GUICtrlSetOnEvent($g_PathWizardBtn, "RunPathCaptureWizard")

	; ================================================================================================
	; DYNAMIC HEIGHT CALCULATION AND GUI RESIZING
	; ================================================================================================

	; Calculate required height based on content
	Local $buttonHeight = 30
	Local $buttonMargin = 20
	Local $requiredHeight = $currentY + $buttonHeight + $buttonMargin

	; Resize the GUI to fit the content exactly
	Local $aPos = WinGetPos($g_ConfigGUI)
	If $aPos[3] <> $requiredHeight Then
		WinMove($g_ConfigGUI, "", $aPos[0], $aPos[1], $initialWidth, $requiredHeight)
	EndIf

	; Perform initial validation check
	CheckConfigFields()

	; Show the GUI and register message handler for real-time validation
	GUISetState(@SW_SHOW, $g_ConfigGUI)
	; Shows a "Please Wait" message dialog during long operations
	GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND_EditChange")
EndFunc   ;==>ShowConfigGUI

; Helper function to return the maximum of two values
; @param $a - First value
; @param $b - Second value
; @return The maximum of the two values
Func _Max($a, $b)
	If $a = "" Then Return $b
	If $b = "" Then Return $a
	If $a = "" And $b = "" Then Return ""
	If Not IsNumber($a) Then Return $b
	If Not IsNumber($b) Then Return $a
	Return ($a > $b) ? $a : $b
EndFunc   ;==>_Max

; Immediately saves a specific field value to settings and INI file
; @param $key - Settings key name
; @param $value - Value to save
Func SaveFieldImmediately($key, $value)
	; Save to in-memory settings
	$g_UserSettings.Add($key, $value)

	; Save to INI file
	IniWrite($CONFIG_FILE, _GetIniSectionForKey($key), $key, _StringToUTF8($value))

	Debug("Immediately saved field " & $key & " with value: " & $value, "VERBOSE")
EndFunc   ;==>SaveFieldImmediately

; Handler for immediate saving of specific fields when they change
Func _OnImmediateSaveFieldChange()
	Local $idChanged = @GUI_CtrlId

	; Check if this is one of the fields that should save immediately
	If $idChanged = $g_FieldCtrls.Item("HostToolsValue") Or $idChanged = $g_FieldCtrls.Item("MoreMeetingControlsValue") Then
		Local $fieldKey = ""
		For $sKey In $g_FieldCtrls.Keys
			If $g_FieldCtrls.Item($sKey) = $idChanged Then
				$fieldKey = $sKey
				ExitLoop
			EndIf
		Next

		If $fieldKey <> "" Then
			Local $value = StringStripWS(GUICtrlRead($idChanged), 3)
			If $value <> "" Then
				SaveFieldImmediately($fieldKey, $value)
				Debug("Immediately saved " & $fieldKey & " with value: " & $value, "VERBOSE")
			EndIf
		EndIf
	EndIf

EndFunc   ;==>_OnImmediateSaveFieldChange

; Handler for when language selection changes - refreshes all GUI labels immediately
Func _OnLanguageChanged()
	Local $selDisplay = GUICtrlRead($idLanguagePicker)
	Local $selLang = _GetLanguageCodeFromDisplayName($selDisplay)
	If $selLang = "" Then $selLang = "en"  ; Fallback to English if not found

	; Update current language setting
	$g_UserSettings.Item("Language") = $selLang
	IniWrite($CONFIG_FILE, "General", "Language", _StringToUTF8($selLang))
	$g_CurrentLang = $selLang

	; Refresh day labels for new language
	_InitDayLabelMaps()

	; Refresh all GUI labels and field values
	_RefreshGUILabels()

EndFunc   ;==>_OnLanguageChanged

; Refreshes all GUI labels and field values when language changes
Func _RefreshGUILabels()
	If $g_ConfigGUI = 0 Then Return

	; Update window title
	WinSetTitle($g_ConfigGUI, "", t("CONFIG_TITLE"))

	; Update section headers (we need to find them by position or recreate)
	; For now, we'll focus on updating the key controls we can identify

	; Update language picker data with new language list
	Local $langList = _ListAvailableLanguageNames()
	Local $currentDisplay = _GetLanguageDisplayName($g_CurrentLang)
	GUICtrlSetData($idLanguagePicker, $langList, $currentDisplay)

	; Update snap zoom combo box data
	Local $snapVal = GetUserSetting("SnapZoomSide")
	Local $snapDisplay = t("SNAP_DISABLED")
	If $snapVal = "Left" Then
		$snapDisplay = t("SNAP_LEFT")
	ElseIf $snapVal = "Right" Then
		$snapDisplay = t("SNAP_RIGHT")
	EndIf
	GUICtrlSetData($idSnapZoom, t("SNAP_DISABLED") & "|" & t("SNAP_LEFT") & "|" & t("SNAP_RIGHT"), $snapDisplay)

	; Update button labels
	GUICtrlSetData($idSaveBtn, t("BTN_SAVE"))
	GUICtrlSetData($idQuitBtn, t("BTN_QUIT"))

	; Update day dropdowns with new language labels
	_RefreshDayDropdowns()

	; Update field labels for text inputs (this is more complex, would need to track label IDs)
	; For now, we'll update the main visible ones

	; Update field labels using the stored label control IDs
	For $sKey In $g_FieldLabels.Keys
		Local $labelCtrl = $g_FieldLabels.Item($sKey)
		If $labelCtrl <> 0 Then
			; For now, we'll update specific known labels
			Switch $sKey
				Case "MeetingID"
					GUICtrlSetData($labelCtrl, t("LABEL_MEETING_ID"))
				Case "MidweekDay"
					GUICtrlSetData($labelCtrl, t("LABEL_MIDWEEK_DAY"))
				Case "MidweekTime"
					GUICtrlSetData($labelCtrl, t("LABEL_MIDWEEK_TIME"))
				Case "WeekendDay"
					GUICtrlSetData($labelCtrl, t("LABEL_WEEKEND_DAY"))
				Case "WeekendTime"
					GUICtrlSetData($labelCtrl, t("LABEL_WEEKEND_TIME"))
				Case "HostToolsValue"
					GUICtrlSetData($labelCtrl, t("LABEL_HOST_TOOLS"))
				Case "MoreMeetingControlsValue"
					GUICtrlSetData($labelCtrl, t("LABEL_MORE_MEETING_CONTROLS"))
				Case "ParticipantValue"
					GUICtrlSetData($labelCtrl, t("LABEL_PARTICIPANT"))
				Case "MuteAllValue"
					GUICtrlSetData($labelCtrl, t("LABEL_MUTE_ALL"))
				Case "YesValue"
					GUICtrlSetData($labelCtrl, t("LABEL_YES"))
				Case "UncheckedValue"
					GUICtrlSetData($labelCtrl, t("LABEL_UNCHECKED_VALUE"))
				Case "CurrentlyUnmutedValue"
					GUICtrlSetData($labelCtrl, t("LABEL_CURRENTLY_UNMUTED_VALUE"))
				Case "UnmuteAudioValue"
					GUICtrlSetData($labelCtrl, t("LABEL_UNMUTE_AUDIO_VALUE"))
				Case "StopVideoValue"
					GUICtrlSetData($labelCtrl, t("LABEL_STOP_VIDEO_VALUE"))
				Case "StartVideoValue"
					GUICtrlSetData($labelCtrl, t("LABEL_START_VIDEO_VALUE"))
				Case "ZoomSecurityUnmuteValue"
					GUICtrlSetData($labelCtrl, t("LABEL_ZOOM_SECURITY_UNMUTE"))
				Case "ZoomSecurityShareScreenValue"
					GUICtrlSetData($labelCtrl, t("LABEL_ZOOM_SECURITY_SHARE_SCREEN"))
				Case "KeyboardShortcut"
					GUICtrlSetData($labelCtrl, t("LABEL_KEYBOARD_SHORTCUT"))
				Case "Language"
					GUICtrlSetData($labelCtrl, t("LABEL_LANGUAGE"))
				Case "SnapZoomSide"
					GUICtrlSetData($labelCtrl, t("LABEL_SNAP_ZOOM_TO"))
				Case "Section1"
					GUICtrlSetData($labelCtrl, t("SECTION_MEETING_INFO"))
				Case "Section2"
					GUICtrlSetData($labelCtrl, t("SECTION_ZOOM_LABELS"))
				Case "Section3"
					GUICtrlSetData($labelCtrl, t("SECTION_GENERAL_SETTINGS"))
			EndSwitch
		EndIf
	Next

	; Clear and rebuild error area
	If $g_ErrorAreaLabel <> 0 Then
		GUICtrlSetData($g_ErrorAreaLabel, "")
	EndIf

	; Re-run validation to update any error messages and button states
	CheckConfigFields()

EndFunc   ;==>_RefreshGUILabels

; Refreshes day dropdown controls with new language labels
Func _RefreshDayDropdowns()
	; Update MidweekDay dropdown
	Local $midweekCtrl = $g_FieldCtrls.Item("MidweekDay")
	If $midweekCtrl <> 0 Then
		Local $currentMidweekNum = String(GetUserSetting("MidweekDay"))
		Local $currentMidweekLabel = $currentMidweekNum
		If $g_DayNumToLabel.Exists($currentMidweekNum) Then
			$currentMidweekLabel = $g_DayNumToLabel.Item($currentMidweekNum)
		EndIf

		Local $dayList = ""
		For $i = 2 To 7  ; Monday through Saturday
			Local $lbl = t("DAY_" & $i)
			$dayList &= ($dayList = "" ? $lbl : "|" & $lbl)
		Next
		Local $lblSun = t("DAY_" & 1)  ; Sunday last
		$dayList &= ($dayList = "" ? $lblSun : "|" & $lblSun)

		GUICtrlSetData($midweekCtrl, $dayList, $currentMidweekLabel)
	EndIf

	; Update WeekendDay dropdown
	Local $weekendCtrl = $g_FieldCtrls.Item("WeekendDay")
	If $weekendCtrl <> 0 Then
		Local $currentWeekendNum = String(GetUserSetting("WeekendDay"))
		Local $currentWeekendLabel = $currentWeekendNum
		If $g_DayNumToLabel.Exists($currentWeekendNum) Then
			$currentWeekendLabel = $g_DayNumToLabel.Item($currentWeekendNum)
		EndIf

		Local $dayList = ""
		For $i = 2 To 7  ; Monday through Saturday
			Local $lbl = t("DAY_" & $i)
			$dayList &= ($dayList = "" ? $lbl : "|" & $lbl)
		Next
		Local $lblSun = t("DAY_" & 1)  ; Sunday last
		$dayList &= ($dayList = "" ? $lblSun : "|" & $lblSun)

		GUICtrlSetData($weekendCtrl, $dayList, $currentWeekendLabel)
	EndIf
EndFunc   ;==>_RefreshDayDropdowns


; Helper function to add a section header with styling
; @param $text - Header text to display
; @param $x - X position
; @param $y - Y position
Func _AddSectionHeader($text, $x, $y)
	Local $idLabel = GUICtrlCreateLabel($text, $x, $y, 620, 20)
	GUICtrlSetFont($idLabel, 10, 700, Default, "Segoe UI") ; Bold, larger font
	GUICtrlSetColor($idLabel, 0x0066CC) ; Blue color
	GUICtrlSetBkColor($idLabel, 0xE8F4FD) ; Light blue background
	Return $idLabel
EndFunc   ;==>_AddSectionHeader
; Shows a message dialog during long operations with i18n support and enhanced styling for errors vs info messages
; @param $messageType - Type of message to show ('PLEASE_WAIT', 'POST_MEETING_HIT_KEY', or custom error/info messages)
; @param $isError - Boolean indicating if this is an error message (red background, requires click to dismiss)
; @param $autoDismiss - Boolean indicating if the message should auto-dismiss (default true for info, false for errors)
Func ShowOverlayMessage($messageType = 'PLEASE_WAIT', $isError = False, $autoDismiss = True)
	; If already showing, just update it
	If $g_OverlayMessageGUI <> 0 Then
		; Update existing GUI with new message
		Local $text = t($messageType)
		WinSetTitle($g_OverlayMessageGUI, '', '')
		Local $idLblExisting = _GetOverlayMessageLabelControl()
		If $idLblExisting <> 0 Then
			; Use GUICtrl functions since we have the control ID
			GUICtrlSetData($idLblExisting, $text)
			; Update font styling to use default Windows system font
			GUICtrlSetFont($idLblExisting, 14, 700, Default, "Segoe UI")
			; Update background color based on error state
			If $isError Then
				GUICtrlSetBkColor($idLblExisting, 0xFFE6E6) ; Light red for errors
				GUICtrlSetColor($idLblExisting, 0xCC0000) ; Dark red text for errors
			Else
				GUICtrlSetBkColor($idLblExisting, 0xE6F3FF) ; Light blue for info
				GUICtrlSetColor($idLblExisting, 0x0066CC) ; Blue text for info
			EndIf
		EndIf
		GUISetState(@SW_SHOW, $g_OverlayMessageGUI)
		WinSetOnTop(HWnd($g_OverlayMessageGUI), '', $WINDOWS_ONTOP)
		; Set up auto-dismiss timer for non-error messages
		If Not $isError And $autoDismiss Then
			AdlibRegister("HideOverlayMessage", 5000) ; Auto-dismiss after 5 seconds for info messages
		EndIf
		Return
	EndIf

	Local $iW = 350
	Local $iH = 140
	Local $iX = (@DesktopWidth - $iW) / 2
	Local $iY = (@DesktopHeight - $iH) / 2

	; Create borderless, always-on-top popup on primary monitor
	$g_OverlayMessageGUI = GUICreate(t($messageType), $iW, $iH, $iX, $iY, $WS_POPUP, $WS_EX_TOPMOST)

	; Set background color based on error state
	Local $bgColor = ($isError ? 0xFFE6E6 : 0xE6F3FF) ; Light red for errors, light blue for info
	GUISetBkColor($bgColor, $g_OverlayMessageGUI)

	; Create a label that supports both centering and word wrapping
	Local $idLbl = GUICtrlCreateLabel(t($messageType), 10, 10, $iW - 20, $iH - 20, $SS_CENTER)
	; Set text color based on error state
	Local $textColor = ($isError ? 0xCC0000 : 0x0066CC) ; Dark red for errors, blue for info
	GUICtrlSetColor($idLbl, $textColor)
	GUICtrlSetFont($idLbl, 14, 700, Default, "Segoe UI") ; Use default Windows system font

	; Make the label clickable for dismissal (especially for error messages)
	GUICtrlSetCursor($idLbl, 0) ; Hand cursor
	GUICtrlSetOnEvent($idLbl, "HideOverlayMessage")

	GUISetState(@SW_SHOW, $g_OverlayMessageGUI)
	WinSetOnTop(HWnd($g_OverlayMessageGUI), '', $WINDOWS_ONTOP)

	; Set up auto-dismiss timer for non-error messages
	If Not $isError And $autoDismiss Then
		AdlibRegister("HideOverlayMessage", 3000) ; Auto-dismiss after 3 seconds for info messages
	EndIf
EndFunc   ;==>ShowOverlayMessage

; Hides and destroys the "Please Wait" message dialog
Func HideOverlayMessage()
	If $g_OverlayMessageGUI <> 0 Then
		; Unregister any auto-dismiss timer
		AdlibUnRegister("HideOverlayMessage")
		GUIDelete($g_OverlayMessageGUI)
		$g_OverlayMessageGUI = 0
	EndIf
EndFunc   ;==>HideOverlayMessage

Func _GetOverlayMessageLabelControl()
	If $g_OverlayMessageGUI = 0 Then Return 0

	; Get all controls in the GUI using WinAPI
	Local $aControls = _WinAPI_EnumChildWindows($g_OverlayMessageGUI)
	If @error Or Not IsArray($aControls) Then Return 0

	; Find the label control (usually the first and only control)
	For $i = 1 To $aControls[0][0]
		Local $hCtrl = $aControls[$i][0]
		Local $sClass = _WinAPI_GetClassName($hCtrl)
		If $sClass = "Static" Then
			; Try to get the control ID from the handle
			Local $ctrlID = _WinAPI_GetDlgCtrlID($hCtrl)
			If $ctrlID > 0 Then Return $ctrlID
		EndIf
	Next

	Return 0
EndFunc   ;==>_GetOverlayMessageLabelControl

; Helper function to add text input field with label
; @param $key - Settings key name
; @param $label - Display label text
; @param $xLabel,$yLabel - Label position
; @param $xInput,$yInput - Input position
; @param $wInput - Input width
Func _AddTextInputField($key, $label, $xLabel, $yLabel, $xInput, $yInput, $wInput)
	Local $idLabel = GUICtrlCreateLabel($label, $xLabel, $yLabel, 200, 20)
	Local $idInput = GUICtrlCreateInput(GetUserSetting($key), $xInput, $yInput, $wInput, 20)

	If Not $g_FieldCtrls.Exists($key) Then $g_FieldCtrls.Add($key, $idInput)
	If Not $g_FieldLabels.Exists($key) Then $g_FieldLabels.Add($key, $idLabel)

	GUICtrlSetOnEvent($idInput, "CheckConfigFields")
	GUICtrlSetOnEvent($idInput, "_OnFieldFocus") ; Track when field gets focus
EndFunc   ;==>_AddTextInputField

; Helper function to add text input field with label and info tooltip
Func _AddTextInputFieldWithTooltip($key, $label, $xLabel, $yLabel, $xInput, $yInput, $wInput, $explainKey, $imageName)
	Local $idLabel = GUICtrlCreateLabel($label, $xLabel, $yLabel, 200, 20)

	; Only create info icon if explanation is provided
	If $explainKey <> "" Then
		; Build tooltip text with explanation
		Local $tooltipText = t($explainKey)

		; Create info icon label logic would go here if needed for non-lookup fields
		; For now, just adding the label and input as normal
	EndIf

	Local $idInput = GUICtrlCreateInput(GetUserSetting($key), $xInput, $yInput, $wInput, 20)
	If Not $g_FieldCtrls.Exists($key) Then $g_FieldCtrls.Add($key, $idInput)
	If Not $g_FieldLabels.Exists($key) Then $g_FieldLabels.Add($key, $idLabel)
	GUICtrlSetOnEvent($idInput, "CheckConfigFields")
	GUICtrlSetOnEvent($idInput, "_OnFieldFocus") ; Track when field gets focus
EndFunc   ;==>_AddTextInputFieldWithTooltip

Func _AddTextInputFieldWithTooltipAndLookup($key, $label, $xLabel, $yLabel, $xInput, $yInput, $wInput, $explainKey, $imageName)
	Local $idLabel = GUICtrlCreateLabel($label, $xLabel, $yLabel, 200, 20)

	; Only create info icon if an image name is provided
	If $imageName <> "" Then
		; Build tooltip text with explanation and image reference
		Local $tooltipText = t($explainKey)
		Local $imagePath = @ScriptDir & "\images\" & $imageName

		; Check if image exists, if not use placeholder path
		If Not FileExists($imagePath) Then
			$imagePath = @ScriptDir & "\images\placeholder.jpg"
		EndIf

		; Get image dimensions for proper sizing
		Local $iImageWidth = 20, $iImageHeight = 20 ; Default fallback
		If FileExists($imagePath) Then
			_GDIPlus_Startup()
			Local $hImage = _GDIPlus_ImageLoadFromFile($imagePath)
			If $hImage <> 0 Then
				$iImageWidth = _GDIPlus_ImageGetWidth($hImage)
				$iImageHeight = _GDIPlus_ImageGetHeight($hImage)
				_GDIPlus_ImageDispose($hImage)

				; Scale down if too large (max 40px for icon)
				If $iImageWidth > 40 Or $iImageHeight > 40 Then
					Local $scale = 40 / _Max($iImageWidth, $iImageHeight)
					$iImageWidth *= $scale
					$iImageHeight *= $scale
				EndIf
			EndIf
			_GDIPlus_Shutdown()
		EndIf

		; Create info icon label with dynamic size
		Local $idInfoIcon = GUICtrlCreateLabel("[?]", $xLabel + 205, $yLabel, $iImageWidth, $iImageHeight)
		GUICtrlSetColor($idInfoIcon, 0x0066CC) ; Blue color
		GUICtrlSetFont($idInfoIcon, 10, 700) ; Bold
		GUICtrlSetCursor($idInfoIcon, 0) ; Hand cursor

		; Set standard tooltip with explanation text only
		GUICtrlSetTip($idInfoIcon, $tooltipText)

		; Store image path for custom tooltip display on click
		If Not $g_InfoIconData.Exists($idInfoIcon) Then
			$g_InfoIconData.Add($idInfoIcon, $imagePath)
		EndIf

		; Set click event to show image tooltip
		GUICtrlSetOnEvent($idInfoIcon, "_ShowImageTooltip")
	EndIf

	; Create text input field (slightly smaller width to make room for lookup button)
	Local $idInput = GUICtrlCreateInput(GetUserSetting($key), $xInput, $yInput, $wInput - 35, 20)
	If Not $g_FieldCtrls.Exists($key) Then $g_FieldCtrls.Add($key, $idInput)
	If Not $g_FieldLabels.Exists($key) Then $g_FieldLabels.Add($key, $idLabel)
	GUICtrlSetOnEvent($idInput, "CheckConfigFields")
	GUICtrlSetOnEvent($idInput, "_OnFieldFocus") ; Track when field gets focus

	; For HostToolsValue and MoreMeetingControlsValue, add immediate save functionality
	If $key = "HostToolsValue" Or $key = "MoreMeetingControlsValue" Then
		GUICtrlSetOnEvent($idInput, "_OnImmediateSaveFieldChange")
	EndIf

	_CreateLookupButton($xInput, $yInput, $wInput, $idInput)
EndFunc   ;==>_AddTextInputFieldWithTooltipAndLookup

Func _CreateLookupButton($xInput, $yInput, $wInput, $idInput)
	Local $idLookupBtn = GUICtrlCreateButton("...", $xInput + $wInput - 30, $yInput, 25, 20)
	GUICtrlSetFont($idLookupBtn, 8, 400)
	GUICtrlSetTip($idLookupBtn, "Lookup element names from Zoom")
	GUICtrlSetOnEvent($idLookupBtn, "_OnLookupButtonClick")

	; Store the relationship between lookup button and input field
	If Not $g_InfoIconData.Exists($idLookupBtn) Then
		$g_InfoIconData.Add($idLookupBtn, $idInput)
	EndIf

	Return $idLookupBtn
EndFunc   ;==>_CreateLookupButton

; Track when a field gets focus to know where to put looked-up values
Func _OnFieldFocus()
	; This function is called when a field gets focus
	; We can update the global active field variable
	Local $focusedCtrlID = @GUI_CtrlId
	$g_ActiveFieldForLookup = $focusedCtrlID
	Debug("Field focused: " & $focusedCtrlID, "VERBOSE")
EndFunc   ;==>_OnFieldFocus

; Handle lookup button click
Func _OnLookupButtonClick()
	Local $btnID = @GUI_CtrlId

	; Find the associated input field
	If $g_InfoIconData.Exists($btnID) Then
		Local $inputID = $g_InfoIconData.Item($btnID)
		$g_ActiveFieldForLookup = $inputID

		; Start the element name collection process
		GetElementNamesForField()
	Else
		Debug("No input field associated with lookup button " & $btnID, "WARN")
	EndIf
EndFunc   ;==>_OnLookupButtonClick

Func GetElementNamesForField()
	Debug("Lookup button clicked - collecting element names for field", "VERBOSE")

	; Check if Zoom meeting is in progress
	If Not FocusZoomWindow() Then
		Return
	EndIf

	; Get Zoom window object
	Local $oResolvedZoomWindow = _GetZoomWindow()
	If Not IsObj($oResolvedZoomWindow) Then Return

	; Open Host Tools menu to collect names from it too
	Local $oHostMenu = _OpenHostTools()
	If Not IsObj($oHostMenu) Then
		Debug("Failed to open Host Tools menu, collecting names from Zoom window only", "WARN")
	EndIf

	; Collect element names from both windows
	Local $aNames = GetElementNamesFromWindows($oZoomWindow, $oHostMenu)

	If UBound($aNames) = 0 Then
		Debug(t("ERROR_ELEMENT_NOT_FOUND", t("ERROR_VARIOUS_ELEMENTS")), "ERROR")
		Return
	EndIf

	; Show selection GUI with callback to populate the active field
	ShowElementNamesSelectionGUI($aNames, "OnFieldElementSelected")

	; Close Host Tools menu if it was opened
	If IsObj($oHostMenu) Then
		_CloseHostTools()
	EndIf

	Debug("Element names collection completed for field lookup", "VERBOSE")
EndFunc   ;==>GetElementNamesForField

Func OnFieldElementSelected($selectedName)
	; Populate the currently active field with the selected name
	If $g_ActiveFieldForLookup <> 0 Then
		GUICtrlSetData($g_ActiveFieldForLookup, $selectedName)
		; Trigger validation check
		CheckConfigFields()
		Debug("Populated field " & $g_ActiveFieldForLookup & " with: " & $selectedName, "VERBOSE")
	Else
		Debug("No active field to populate", "WARN")
	EndIf
EndFunc   ;==>OnFieldElementSelected

; Helper function to add day selection dropdown with label
; @param $key - Settings key name
; @param $label - Display label text
; @param $xLabel,$yLabel - Label position
; @param $xInput,$yInput - Input position
; @param $wInput - Input width
Func _AddDayDropdownField($key, $label, $xLabel, $yLabel, $xInput, $yInput, $wInput)
	Local $idLabel = GUICtrlCreateLabel($label, $xLabel, $yLabel, 200, 20)
	Local $idCombo = GUICtrlCreateCombo("", $xInput, $yInput, $wInput, 20)

	; Populate usage: Sunday=1, Monday=2, ... Saturday=7
	; Store mapping of day number to localized day name
	Local $dayList = ""

	; Map each day number to its localized name
	Local $currentDayNum = String(GetUserSetting($key))
	Local $currentDayLabel = $currentDayNum ; Default fallback

	; Find valid label for current setting
	If $g_DayNumToLabel.Exists($currentDayNum) Then
		$currentDayLabel = $g_DayNumToLabel.Item($currentDayNum)
	EndIf

	For $i = 2 To 7  ; Monday through Saturday
		Local $lbl = t("DAY_" & $i)
		$dayList &= ($dayList = "" ? $lbl : "|" & $lbl)
	Next
	Local $lblSun = t("DAY_" & 1)  ; Sunday last
	$dayList &= ($dayList = "" ? $lblSun : "|" & $lblSun)

	GUICtrlSetData($idCombo, $dayList, $currentDayLabel)

	If Not $g_FieldCtrls.Exists($key) Then $g_FieldCtrls.Add($key, $idCombo)
	If Not $g_FieldLabels.Exists($key) Then $g_FieldLabels.Add($key, $idLabel)

	GUICtrlSetOnEvent($idCombo, "CheckConfigFields")
EndFunc   ;==>_AddDayDropdownField

; Validates all configuration fields and updates UI accordingly
; Enables/disables save button, shows validation errors, and updates field styling
Func CheckConfigFields()
	Local $allFilled = True

	; Check if all fields have values
	For $sKey In $g_FieldCtrls.Keys
		Local $ctrlID = $g_FieldCtrls.Item($sKey)
		Local $val = StringStripWS(GUICtrlRead($ctrlID), 3)
		If $val = "" Then
			$allFilled = False
			; Mark required field with tooltip and light red background
			GUICtrlSetTip($ctrlID, t("ERROR_REQUIRED"))
			GUICtrlSetBkColor($ctrlID, 0xEEDDDD)
		EndIf
	Next

	; Additional format validation if all fields have values
	If $allFilled Then
		Local $ok = True

		; Validate meeting ID format
		Local $idCtrl = $g_FieldCtrls.Item("MeetingID")
		Local $idVal = StringStripWS(GUICtrlRead($idCtrl), 3)
		If Not StringRegExp($idVal, "^\d[\d -]+\d$") Then
			GUICtrlSetTip($idCtrl, t("ERROR_MEETING_ID_FORMAT"))
			GUICtrlSetBkColor($idCtrl, 0xEEDDDD)
			$ok = False
		Else
			GUICtrlSetBkColor($idCtrl, 0xFFFFFF) ; Reset color
			GUICtrlSetTip($idCtrl, "") ; Clear tooltip
		EndIf

		; Validate time formats (HH:MM or HH.MM)
		Local $midCtrl = $g_FieldCtrls.Item("MidweekTime")
		Local $wkdCtrl = $g_FieldCtrls.Item("WeekendTime")
		If Not _IsValidTime(GUICtrlRead($midCtrl)) Then $ok = False
		If Not _IsValidTime(GUICtrlRead($wkdCtrl)) Then $ok = False

		; Validate keyboard shortcut format (if not empty)
		Local $kbCtrl = $g_FieldCtrls.Item("KeyboardShortcut")
		Local $kbVal = StringStripWS(GUICtrlRead($kbCtrl), 3)
		If $kbVal <> "" And Not _IsValidKeyboardShortcut($kbVal) Then $ok = False

		$allFilled = $ok
	EndIf

	; Build error message and update field styling
	Local $aMsgs = ($allFilled ? "" : t("ERROR_FIELDS_REQUIRED"))

	; Clear required indicators for non-empty fields
	For $sKey In $g_FieldCtrls.Keys
		Local $ctrlID = $g_FieldCtrls.Item($sKey)
		Local $val = StringStripWS(GUICtrlRead($ctrlID), 3)
		If $val <> "" Then
			GUICtrlSetBkColor($ctrlID, 0xFFFFFF)
			GUICtrlSetTip($ctrlID, "")
		EndIf
	Next

	; Update error area label
	If $g_ErrorAreaLabel <> 0 Then
		GUICtrlSetData($g_ErrorAreaLabel, $aMsgs)
	EndIf

	; Enable/disable save button
	If $idSaveBtn <> 0 Then
		GUICtrlSetState($idSaveBtn, ($allFilled ? $GUI_ENABLE : $GUI_DISABLE))
	EndIf

	; Update snap zoom global variable immediately if it changed
	If $g_FieldCtrls.Exists("SnapZoomSide") Then
		Local $snapCtrl = $g_FieldCtrls.Item("SnapZoomSide")
		Local $snapValDisplay = GUICtrlRead($snapCtrl)
		Local $snapVal = "Disabled"

		; Map display value back to internal config value
		If $snapValDisplay = t("SNAP_LEFT") Then
			$snapVal = "Left"
		ElseIf $snapValDisplay = t("SNAP_RIGHT") Then
			$snapVal = "Right"
		EndIf

		Local $oldVal = GetUserSetting("SnapZoomSide")
		If $snapVal <> $oldVal Then
			$g_UserSettings.Item("SnapZoomSide") = $snapVal
			Debug("Updated SnapZoomSide in-memory to: " & $snapVal, "VERBOSE")
		EndIf
	EndIf

	; Handle day dropdown value updates (map display value to stored integer)
	_UpdateDaySettingFromDropdown("MidweekDay")
	_UpdateDaySettingFromDropdown("WeekendDay")
EndFunc   ;==>CheckConfigFields

; Helper to update day setting from dropdown selection
Func _UpdateDaySettingFromDropdown($key)
	If $g_FieldCtrls.Exists($key) Then
		Local $ctrl = $g_FieldCtrls.Item($key)
		Local $displayVal = GUICtrlRead($ctrl)
		Local $numVal = _GetDayNumFromLabel($displayVal)

		If $numVal <> "" Then
			$g_UserSettings.Item($key) = $numVal
			; Note: We don't write to INI yet, only on Save
		EndIf
	EndIf
EndFunc   ;==>_UpdateDaySettingFromDropdown

; Message handler for real-time edit control changes
Func _WM_COMMAND_EditChange($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF) ; Low word is CtrlID
	Local $iCode = BitShift($wParam, 16)    ; High word is notification code

	; EN_CHANGE = 768 (0x300)
	If $iCode = 768 Then
		; Check if the changed control is one of our input fields
		For $sKey In $g_FieldCtrls.Keys
			If $g_FieldCtrls.Item($sKey) = $iIDFrom Then
				CheckConfigFields()
				ExitLoop
			EndIf
		Next

		; Also check special inputs
		If $iIDFrom = $g_FieldCtrls.Item("KeyboardShortcut") Then CheckConfigFields()
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>_WM_COMMAND_EditChange

; Re-enables the standard window close button (X) which might be disabled by some styles
Func _EnableCloseButton($hGUI)
	Local $hMenu = DllCall("user32.dll", "handle", "GetSystemMenu", "hwnd", $hGUI, "bool", 0)
	If @error Then Return
	$hMenu = $hMenu[0]
	DllCall("user32.dll", "bool", "EnableMenuItem", "handle", $hMenu, "uint", 0xF060, "uint", 0x00000000) ; SC_CLOSE, MF_ENABLED
EndFunc   ;==>_EnableCloseButton

; Saves configuration settings to INI file and closes GUI
Func SaveConfigGUI()
	; Ensure all fields are valid before saving
	CheckConfigFields()
	Local $state = GUICtrlGetState($idSaveBtn)
	If BitAND($state, $GUI_DISABLE) Then
		MsgBox($MB_OK + $MB_ICONWARNING, t("CONFIG_TITLE"), t("ERROR_FIELDS_REQUIRED"))
		Return
	EndIf

	; Save all text fields to settings
	For $sKey In $g_FieldCtrls.Keys
		Local $ctrlID = $g_FieldCtrls.Item($sKey)
		; Skip dropdowns/special controls that are handled separately
		If $sKey <> "Language" And $sKey <> "SnapZoomSide" And $sKey <> "MidweekDay" And $sKey <> "WeekendDay" Then
			Local $val = StringStripWS(GUICtrlRead($ctrlID), 3)
			$g_UserSettings.Item($sKey) = $val
			IniWrite($CONFIG_FILE, _GetIniSectionForKey($sKey), $sKey, _StringToUTF8($val))
		EndIf
	Next

	; Save language setting
	Local $selDisplay = GUICtrlRead($idLanguagePicker)
	Local $selLang = _GetLanguageCodeFromDisplayName($selDisplay)
	If $selLang <> "" Then
		$g_UserSettings.Item("Language") = $selLang
		IniWrite($CONFIG_FILE, "General", "Language", _StringToUTF8($selLang))
	EndIf

	; Save snap zoom setting
	Local $snapVal = $g_UserSettings.Item("SnapZoomSide") ; Already updated in CheckConfigFields
	IniWrite($CONFIG_FILE, "General", "SnapZoomSide", _StringToUTF8($snapVal))

	; Save day settings (values are 1-7 ints)
	Local $midWeekDay = $g_UserSettings.Item("MidweekDay")
	Local $weekendDay = $g_UserSettings.Item("WeekendDay")
	IniWrite($CONFIG_FILE, "Meetings", "MidweekDay", $midWeekDay)
	IniWrite($CONFIG_FILE, "Meetings", "WeekendDay", $weekendDay)

	; Update keyboard shortcut
	_UpdateKeyboardShortcut()

	Debug("Configuration saved.", "INFO")
	CloseConfigGUI()
EndFunc   ;==>SaveConfigGUI

; Closes and destroys the configuration GUI
Func CloseConfigGUI()
	GUIDelete($g_ConfigGUI)
	$g_ConfigGUI = 0
	_CloseImageTooltip() ; Close any open image tooltip
EndFunc   ;==>CloseConfigGUI

; Shows a custom tooltip window with an image when info icon is clicked
Func _ShowImageTooltip()
	Local $idCtrl = @GUI_CtrlId

	If Not $g_InfoIconData.Exists($idCtrl) Then Return

	Local $imagePath = $g_InfoIconData.Item($idCtrl)

	; Close existing tooltip if any
	_CloseImageTooltip()

	; Get mouse position
	Local $mousePos = MouseGetPos()

	; Create tooltip GUI
	Local $iW = 300
	Local $iH = 200
	; Adjust dimensions if we can get image size
	_GDIPlus_Startup()
	Local $hImage = _GDIPlus_ImageLoadFromFile($imagePath)
	Local $iImageWidth = 280
	Local $iImageHeight = 180
	If $hImage <> 0 Then
		$iImageWidth = _GDIPlus_ImageGetWidth($hImage)
		$iImageHeight = _GDIPlus_ImageGetHeight($hImage)

		; Max size constraints
		If $iImageWidth > 400 Then
			Local $scale = 400 / $iImageWidth
			$iImageWidth *= $scale
			$iImageHeight *= $scale
		EndIf

		$iW = $iImageWidth + 20
		$iH = $iImageHeight + 40 ; Extra for label

		_GDIPlus_ImageDispose($hImage)
	EndIf
	_GDIPlus_Shutdown()

	$g_TooltipGUI = GUICreate("Help", $iW, $iH, $mousePos[0] + 20, $mousePos[1] + 20, $WS_POPUP + $WS_BORDER, $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW)
	GUISetBkColor(0xFFFFEE, $g_TooltipGUI) ; Light yellow tooltip color

	; Add image if it exists
	If FileExists($imagePath) Then
		GUICtrlCreatePic($imagePath, 10, 10, $iImageWidth, $iImageHeight)
	Else
		GUICtrlCreateLabel("Image not found:", 10, 10, $iImageWidth, 20)
		GUICtrlCreateLabel($imagePath, 10, 35, $iImageWidth, $iImageHeight - 25)
	EndIf

	GUISetState(@SW_SHOW, $g_TooltipGUI)

	; Auto-close after 5 seconds or when clicking anywhere
	AdlibRegister("_CloseImageTooltip", 5000)
EndFunc   ;==>_ShowImageTooltip

; Closes the custom image tooltip window
Func _CloseImageTooltip()
	If $g_TooltipGUI <> 0 Then
		GUIDelete($g_TooltipGUI)
		$g_TooltipGUI = 0
		AdlibUnRegister("_CloseImageTooltip")
	EndIf
EndFunc   ;==>_CloseImageTooltip

; Exits the application
Func QuitApp()
	Exit
EndFunc   ;==>QuitApp

; ================================================================================================
; TRAY ICON EVENT HANDLING
; ================================================================================================

; Initializes the tray icon
Func _InitTray()
	TraySetIcon($g_TrayIcon)
EndFunc   ;==>_InitTray

; Sets up tray icon and handles tray events
Func TrayEvent()
	Local $msg = TrayGetMsg()
	Switch $msg
		Case 0
			Return
		Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_PRIMARYUP
			; Show/Hide config on click
			If $g_ConfigGUI Then
				If BitAND(WinGetState($g_ConfigGUI), 2) Then ; Visible
					GUISetState(@SW_HIDE, $g_ConfigGUI)
				Else
					GUISetState(@SW_SHOW, $g_ConfigGUI)
					WinActivate($g_ConfigGUI)
				EndIf
			Else
				ShowConfigGUI()
			EndIf
		Case $TRAY_EVENT_SECONDARYDOWN, $TRAY_EVENT_SECONDARYUP ; Right-click
			ShowConfigGUI()
		Case $TRAY_EVENT_PRIMARYDOUBLE ; Double-click
			ShowConfigGUI()
	EndSwitch
EndFunc   ;==>TrayEvent

; Sleep function that continues to handle tray events during wait
; @param $s - Seconds to sleep
Func ResponsiveSleep($s)
	Local $elapsed = 0
	Local $ms = $s * 1000
	While $elapsed < $ms
		TrayEvent()           ; Continue handling tray events
		Sleep(50)            ; Small incremental sleep
		$elapsed += 50
	WEnd
EndFunc   ;==>ResponsiveSleep

; ================================================================================================
; ELEMENT NAME COLLECTION FUNCTIONS
; ================================================================================================

; Collects all element names (UIA_NamePropertyId) from specified windows using default control types
; @param $oZoomWindow - Zoom window element
; @param $oHostMenu - Host menu element (optional)
; @return Array - Array of unique element names, trimmed and sorted
Func GetElementNamesFromWindows($oZoomWindow, $oHostMenu = 0)
	Local $aNames = []

	If Not IsObj($oZoomWindow) Then
		Debug("GetElementNamesFromWindows: Invalid Zoom window object", "VERBOSE")
		Return $aNames
	EndIf

	; Define control types to search (same as FindElementByPartialName default)
	Local $aControlTypes[2] = [$UIA_ButtonControlTypeId, $UIA_MenuItemControlTypeId]

	; Collect names from Zoom window
	_CollectElementNames($oZoomWindow, $aControlTypes, $aNames)

	Debug("Collected these values: " & $aNames & " from Zoom window", "VERBOSE")

	; Collect names from Host menu if provided
	If IsObj($oHostMenu) Then
		_CollectElementNames($oHostMenu, $aControlTypes, $aNames)
	EndIf

	; Remove duplicates and sort
	$aNames = _ArrayUnique($aNames)
	_ArraySort($aNames)

	Debug("Collected " & UBound($aNames) & " unique element names", "VERBOSE")
	Return $aNames
EndFunc   ;==>GetElementNamesFromWindows

; Helper function to collect element names from a parent element
; @param $oParent - Parent element to search within
; @param $aControlTypes - Array of control types to search
; @param ByRef $aNames - Array to store collected names
Func _CollectElementNames($oParent, $aControlTypes, ByRef $aNames)
	If Not IsObj($oParent) Then Return

	; Search each control type
	For $iType = 0 To UBound($aControlTypes) - 1
		Local $iControlType = $aControlTypes[$iType]

		; Create condition for this control type
		Local $pCondition
		$oUIAutomation.CreatePropertyCondition($UIA_ControlTypePropertyId, $iControlType, $pCondition)

		; Find all elements of this type
		Local $pElements
		$oParent.FindAll($TreeScope_Descendants, $pCondition, $pElements)

		Local $oElements = ObjCreateInterface($pElements, $sIID_IUIAutomationElementArray, $dtagIUIAutomationElementArray)
		If IsObj($oElements) Then
			Local $iCount
			$oElements.Length($iCount)

			; Extract name from each element
			For $i = 0 To $iCount - 1
				Local $pElement
				$oElements.GetElement($i, $pElement)

				Local $oElement = ObjCreateInterface($pElement, $sIID_IUIAutomationElement, $dtagIUIAutomationElement)
				If IsObj($oElement) Then
					Local $sName
					$oElement.GetCurrentPropertyValue($UIA_NamePropertyId, $sName)

					; Trim whitespace and add if not empty
					$sName = StringStripWS($sName, 3)
					If $sName <> "" Then
						_ArrayAdd($aNames, $sName)
					EndIf
				EndIf
			Next
		EndIf
	Next
EndFunc   ;==>_CollectElementNames

; Shows a selectable list of collected element names for user to choose from
; @param $aNames - Array of element names to display
; @param $callbackFunc - Function to call when user makes a selection
Func ShowElementNamesSelectionGUI($aNames, $callbackFunc)
	; Close any existing selection GUI
	CloseElementNamesSelectionGUI()

	; Store callback function for when user makes selection
	$g_ElementNamesSelectionCallback = $callbackFunc

	Local $iW = 500
	Local $iH = 400
	Local $iX = (@DesktopWidth - $iW) / 2
	Local $iY = (@DesktopHeight - $iH) / 2

	; Create moveable and closeable GUI
	$g_ElementNamesSelectionGUI = GUICreate("Select Element Name", $iW, $iH, $iX, $iY, $WS_CAPTION + $WS_SYSMENU + $WS_MINIMIZEBOX, $WS_EX_TOPMOST)
	GUISetOnEvent($GUI_EVENT_CLOSE, "CloseElementNamesSelectionGUI")

	; Create list control for displaying element names
	Local $idList = GUICtrlCreateList("", 10, 10, $iW - 20, $iH - 80, $WS_VSCROLL)
	GUICtrlSetFont($idList, 9, 400, 0, "Courier New") ; Monospace font for better readability

	; Add element names to the list
	For $i = 0 To UBound($aNames) - 1
		GUICtrlSetData($idList, $aNames[$i])
	Next

	$g_ElementNamesSelectionList = $idList

	; Create selection button
	Local $idSelectBtn = GUICtrlCreateButton("Select", ($iW - 160) / 2, $iH - 60, 70, 25)
	GUICtrlSetOnEvent($idSelectBtn, "OnElementNameSelected")

	; Create cancel button
	Local $idCancelBtn = GUICtrlCreateButton("Cancel", ($iW - 160) / 2 + 90, $iH - 60, 70, 25)
	GUICtrlSetOnEvent($idCancelBtn, "CloseElementNamesSelectionGUI")

	; Make GUI moveable by dragging the title bar
	GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, "_StartDragElementNamesSelectionGUI")

	GUISetState(@SW_SHOW, $g_ElementNamesSelectionGUI)

	Debug("Element names selection GUI displayed with " & UBound($aNames) & " names", "VERBOSE")
EndFunc   ;==>ShowElementNamesSelectionGUI

; Handles selection of an element name from the list
Func OnElementNameSelected()
	Local $selectedIndex = GUICtrlRead($g_ElementNamesSelectionList)
	If $selectedIndex = "" Or $selectedIndex = -1 Then Return

	; Get the selected text from the list
	Local $selectedText = GUICtrlRead($g_ElementNamesSelectionList)

	; Store the result
	$g_ElementNamesSelectionResult = $selectedText

	; Call the callback function if it exists
	If $g_ElementNamesSelectionCallback <> "" Then
		Call($g_ElementNamesSelectionCallback, $selectedText)
	EndIf

	; Close the selection GUI
	CloseElementNamesSelectionGUI()

	Debug("Element name selected: " & $selectedText, "VERBOSE")
EndFunc   ;==>OnElementNameSelected

; Closes the element names selection GUI
Func CloseElementNamesSelectionGUI()
	If $g_ElementNamesSelectionGUI <> 0 Then
		GUIDelete($g_ElementNamesSelectionGUI)
		$g_ElementNamesSelectionGUI = 0
		$g_ElementNamesSelectionList = 0
		$g_ElementNamesSelectionResult = ""
		$g_ElementNamesSelectionCallback = ""
		Debug("Element names selection GUI closed", "VERBOSE")
	EndIf
EndFunc   ;==>CloseElementNamesSelectionGUI

; Handles dragging of the element names selection GUI
Func _StartDragElementNamesSelectionGUI()
	If $g_ElementNamesSelectionGUI = 0 Then Return

	; Get mouse position relative to GUI
	Local $mousePos = MouseGetPos()
	Local $guiPos = WinGetPos($g_ElementNamesSelectionGUI)

	Local $offsetX = $mousePos[0] - $guiPos[0]
	Local $offsetY = $mousePos[1] - $guiPos[1]

	; Drag while mouse is down
	While _IsMouseDown()
		$mousePos = MouseGetPos()
		WinMove($g_ElementNamesSelectionGUI, "", $mousePos[0] - $offsetX, $mousePos[1] - $offsetY)
		Sleep(10)
	WEnd
EndFunc   ;==>_StartDragElementNamesSelectionGUI

; Shows a closeable and moveable textarea with collected element names
; @param $aNames - Array of element names to display
Func ShowElementNamesGUI($aNames)
	; Close any existing GUI
	CloseElementNamesGUI()

	Local $iW = 500
	Local $iH = 400
	Local $iX = (@DesktopWidth - $iW) / 2
	Local $iY = (@DesktopHeight - $iH) / 2

	; Create moveable and closeable GUI
	$g_ElementNamesGUI = GUICreate("Zoom Element Names", $iW, $iH, $iX, $iY, $WS_CAPTION + $WS_SYSMENU + $WS_MINIMIZEBOX, $WS_EX_TOPMOST)
	GUISetOnEvent($GUI_EVENT_CLOSE, "CloseElementNamesGUI")

	; Create edit control for displaying element names
	Local $idEdit = GUICtrlCreateEdit(_ArrayToString($aNames, @CRLF), 10, 10, $iW - 20, $iH - 50, $ES_READONLY + $WS_VSCROLL + $WS_HSCROLL)
	GUICtrlSetFont($idEdit, 9, 400, 0, "Courier New") ; Monospace font for better readability
	$g_ElementNamesEdit = $idEdit

	; Create close button
	Local $idCloseBtn = GUICtrlCreateButton("Close", $iW - 80, $iH - 35, 70, 25)
	GUICtrlSetOnEvent($idCloseBtn, "CloseElementNamesGUI")

	; Make GUI moveable by dragging the title bar
	GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, "_StartDragElementNamesGUI")

	GUISetState(@SW_SHOW, $g_ElementNamesGUI)

	Debug("Element names GUI displayed with " & UBound($aNames) & " names", "VERBOSE")
EndFunc   ;==>ShowElementNamesGUI

; Closes the element names display GUI
Func CloseElementNamesGUI()
	If $g_ElementNamesGUI <> 0 Then
		GUIDelete($g_ElementNamesGUI)
		$g_ElementNamesGUI = 0
		$g_ElementNamesEdit = 0
		Debug("Element names GUI closed", "VERBOSE")
	EndIf
EndFunc   ;==>CloseElementNamesGUI

; Handles dragging of the element names GUI
Func _StartDragElementNamesGUI()
	If $g_ElementNamesGUI = 0 Then Return

	; Get mouse position relative to GUI
	Local $mousePos = MouseGetPos()
	Local $guiPos = WinGetPos($g_ElementNamesGUI)

	Local $offsetX = $mousePos[0] - $guiPos[0]
	Local $offsetY = $mousePos[1] - $guiPos[1]

	; Drag while mouse is down
	While _IsMouseDown()
		$mousePos = MouseGetPos()
		WinMove($g_ElementNamesGUI, "", $mousePos[0] - $offsetX, $mousePos[1] - $offsetY)
		Sleep(10)
	WEnd
EndFunc   ;==>_StartDragElementNamesGUI

; Helper function to check if mouse button is down
Func _IsMouseDown()
	Local $aState = DllCall("user32.dll", "int", "GetAsyncKeyState", "int", 0x01)
	If @error Or Not IsArray($aState) Then Return False
	Return BitAND($aState[0], 0x8000) <> 0
EndFunc   ;==>_IsMouseDown

; ================================================================================================
; MAIN BUTTON HANDLER
; ================================================================================================

; Button handler for "Get Element Names" button
Func GetElementNames()
	Debug("Get Element Names button clicked", "VERBOSE")

	; Check if Zoom meeting is in progress
	If Not FocusZoomWindow() Then
		Return
	EndIf

	; Meeting is in progress - collect element names
	Debug("Active Zoom meeting found, collecting element names...", "VERBOSE")

	; Get Zoom window object
	Local $oResolvedZoomWindow = _GetZoomWindow()
	If Not IsObj($oResolvedZoomWindow) Then Return

	; Open Host Tools menu to collect names from it too
	Local $oHostMenu = _OpenHostTools()
	If Not IsObj($oHostMenu) Then
		Debug("Failed to open Host Tools menu, collecting names from Zoom window only", "WARN")
	EndIf

	; Collect element names from both windows
	Local $aNames = GetElementNamesFromWindows($oZoomWindow, $oHostMenu)

	If UBound($aNames) = 0 Then
		Debug(t("ERROR_ELEMENT_NOT_FOUND", t("ERROR_VARIOUS_ELEMENTS")), "ERROR")
		Return
	EndIf

	; Display the collected names in the GUI
	ShowElementNamesGUI($aNames)

	; Close Host Tools menu if it was opened
	If IsObj($oHostMenu) Then
		_CloseHostTools()
	EndIf

	Debug("Element names collection completed", "VERBOSE")
EndFunc   ;==>GetElementNames


; Captures UI names from Zoom + HostTools and saves to a diagnostics file.
Func RunUIDiagnostics()
	Local $oResolvedZoomWindow = _GetZoomWindow()
	If Not IsObj($oResolvedZoomWindow) Then
		ReportUserFacingError("UI diagnostics failed: Zoom meeting window not found.")
		Return
	EndIf
	Local $oHostMenu = _OpenHostTools()
	Local $aNames = GetElementNamesFromWindows($oZoomWindow, $oHostMenu)
	If UBound($aNames) = 0 Then
		ReportUserFacingError("UI diagnostics found no element names.")
		Return
	EndIf

	Local $outFile = @ScriptDir & "\zoom_ui_diagnostics.txt"
	Local $h = FileOpen($outFile, $FO_OVERWRITE + $FO_CREATEPATH)
	If $h = -1 Then
		ReportUserFacingError("Could not write diagnostics file: " & $outFile)
		Return
	EndIf
	FileWriteLine($h, "ZoomMate UI Diagnostics - " & @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
	For $i = 0 To UBound($aNames) - 1
		FileWriteLine($h, $aNames[$i])
	Next
	FileClose($h)
	MsgBox(64 + 262144, "ZoomMate", "Diagnostics saved:" & @CRLF & $outFile)
EndFunc   ;==>RunUIDiagnostics

; Lightweight wizard to capture panel/button relationship labels and persist to ini.
Func RunPathCaptureWizard()
	Local $moreLabel = InputBox("Path Wizard", "Label for More button/menu item:", GetUserSetting("MoreMeetingControlsValue"))
	If @error Then Return
	Local $hostToolsLabel = InputBox("Path Wizard", "Label for Host Tools button/item:", GetUserSetting("HostToolsValue"))
	If @error Then Return
	Local $participantsLabel = InputBox("Path Wizard", "Label for Participants section/button:", GetUserSetting("ParticipantValue"))
	If @error Then Return

	IniWrite($CONFIG_FILE, "UiPathMap", "MoreButton", _StringToUTF8($moreLabel))
	IniWrite($CONFIG_FILE, "UiPathMap", "HostToolsButton", _StringToUTF8($hostToolsLabel))
	IniWrite($CONFIG_FILE, "UiPathMap", "ParticipantsNode", _StringToUTF8($participantsLabel))

	; Also update standard labels used by automation.
	$g_UserSettings.Item("MoreMeetingControlsValue") = $moreLabel
	$g_UserSettings.Item("HostToolsValue") = $hostToolsLabel
	$g_UserSettings.Item("ParticipantValue") = $participantsLabel
	IniWrite($CONFIG_FILE, "ZoomStrings", "MoreMeetingControlsValue", _StringToUTF8($moreLabel))
	IniWrite($CONFIG_FILE, "ZoomStrings", "HostToolsValue", _StringToUTF8($hostToolsLabel))
	IniWrite($CONFIG_FILE, "ZoomStrings", "ParticipantValue", _StringToUTF8($participantsLabel))

	CheckConfigFields()
	MsgBox(64 + 262144, "ZoomMate", "Path map saved. You can re-run this anytime after Zoom UI changes.")
EndFunc   ;==>RunPathCaptureWizard
