#include-once



; ================================================================================================
; TIMING AND PERFORMANCE CONSTANTS
; ================================================================================================
Global Const $HOVER_DEFAULT_MS = 1000
Global Const $CLICK_DELAY_MS = 500
Global Const $WINDOW_SNAP_DELAY_MS = 500
Global Const $PRE_MEETING_MINUTES = 60
Global Const $MEETING_START_WARNING_MINUTES = 1
Global Const $SNAP_TOLERANCE_PX = 50
Global Const $CLICK_TIMEOUT_MS = 5000
Global Const $ELEMENT_SEARCH_RETRY_COUNT = 3
Global Const $ELEMENT_SEARCH_RETRY_DELAY_MS = 500
Global Const $UI_AUTOMATION_CACHE_TIME_MS = 2000

; ================================================================================================
; CONFIGURATION AND GLOBAL VARIABLES
; ================================================================================================
; Configuration file path
Global Const $CONFIG_FILE = @ScriptDir & "\zoom_config.ini"

; Meeting automation state flags
Global $g_PrePostSettingsConfigured = False    ; Tracks if pre/post meeting settings are applied
Global $g_DuringMeetingSettingsConfigured = False ; Tracks if during-meeting settings are applied

; Notification control
Global $g_InitialNotificationWasShown = False ; Prevents repeated initial notifications

; User settings storage (Dictionary object for key-value pairs)
Global $g_UserSettings = ObjCreate("Scripting.Dictionary")

; Internationalization (i18n) containers
Global $g_Languages = ObjCreate("Scripting.Dictionary")        ; langCode -> translation dictionary
Global $g_LangCodeToName = ObjCreate("Scripting.Dictionary")   ; langCode -> display name
Global $g_LangNameToCode = ObjCreate("Scripting.Dictionary")   ; display name -> langCode
Global $g_CurrentLang = "en"                                   ; Current language setting

; GUI control references
Global $idSaveBtn                              ; Save button control ID
Global $idLanguagePicker                       ; Language dropdown control ID
Global $g_FieldCtrls = ObjCreate("Scripting.Dictionary")  ; Maps field names to control IDs
Global $g_ErrorAreaLabel = 0                   ; Error display label control ID
Global $g_ConfigGUI = 0                        ; Configuration GUI handle
Global $g_OverlayMessageGUI = 0                    ; Handle for the please-wait popup
Global $g_TooltipGUI = 0                       ; Handle for custom image tooltip
Global $g_InfoIconData = ObjCreate("Scripting.Dictionary")  ; Maps info icon IDs to image paths
Global $g_ElementNamesGUI = 0                      ; Handle for element names display GUI
Global $g_ElementNamesEdit = 0                     ; Handle for element names edit control
Global $g_ElementNamesSelectionGUI = 0             ; Handle for element names selection GUI
Global $g_ElementNamesSelectionList = 0            ; Handle for element names selection list
Global $g_ElementNamesSelectionResult = ""         ; Selected element name result
Global $g_ElementNamesSelectionCallback = ""       ; Callback function for selection
Global $g_ActiveFieldForLookup = 0                 ; Currently active field for lookup operations
Global $g_FieldLabels = ObjCreate("Scripting.Dictionary")  ; Maps field names to label control IDs
Global $g_DiagnosticsBtn = 0
Global $g_PathWizardBtn = 0
Global $g_StateProfilerBtn = 0

; Day mapping containers for internationalization
Global $g_DayLabelToNum = ObjCreate("Scripting.Dictionary")    ; Day name -> number (1-7)
Global $g_DayNumToLabel = ObjCreate("Scripting.Dictionary")    ; Day number -> name

; Status and tray icon variables
Global $g_StatusMsg = "Idle"                   ; Current status message
Global $g_TrayIcon = @ScriptDir & "\zoommate.ico" ; Tray icon path

; UIAutomation COM objects (for Zoom window interaction)
Global $oUIAutomation                          ; Main UIAutomation interface
Global $pDesktop                               ; Desktop element pointer
Global $oDesktop                               ; Desktop element object
Global $oZoomWindow = 0                        ; Zoom window element

; Meeting timing control
Global $previousRunDay = -1                    ; Tracks day changes for state reset

; Keyboard shortcut to trigger post-meeting settings
Global $g_KeyboardShortcut = ""               ; Current keyboard shortcut (e.g., "^!z")
Global $g_HotkeyRegistered = False             ; Tracks if hotkey is currently registered
