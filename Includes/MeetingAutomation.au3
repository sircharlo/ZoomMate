#include-once
; ================================================================================================
; MEETING AUTOMATION - Meeting automation logic and timing
; ================================================================================================

#include "Globals.au3"
#include "Utils.au3"
#include "UserSettings.au3"
#include "UIAutomation.au3"
#include "Settings.au3"

; ================================================================================================
; MEETING AUTOMATION FUNCTIONS
; ================================================================================================

; Launches Zoom with the configured meeting ID
; @return Boolean - True if successful, False otherwise
Func _LaunchZoom()
	Debug(t("INFO_ZOOM_LAUNCHING"), "INFO")

	Local $meetingID = GetUserSetting("MeetingID")
	If $meetingID = "" Then
		Debug(t("ERROR_MEETING_ID_NOT_CONFIGURED"), "ERROR")
		Return SetError(1, 0, 0)
	EndIf

	; Use Zoom URL protocol to launch meeting directly
	Local $zoomURL = "zoommtg://zoom.us/join?confno=" & $meetingID
	ShellExecute($zoomURL)
	Debug(t("INFO_ZOOM_LAUNCHED") & ": " & $meetingID, "INFO")
	Sleep(10000)  ; Wait for Zoom to launch

	If Not _GetZoomWindow() Then Return False

	_SnapZoomWindowToSide()

	Return IsObj($oZoomWindow)
EndFunc   ;==>_LaunchZoom

; Configures settings before and after meetings
; - Enables unmute permission for participants
; - Disables screen sharing permission
; - Turns off host audio and video
Func _SetPreAndPostMeetingSettings()
	Debug(t("INFO_CONFIG_BEFORE_AFTER_START"), "INFO")
	Sleep(3000)
	If Not FocusZoomWindow() Then
		Return
	EndIf
	SetSecuritySetting(GetUserSetting("ZoomSecurityUnmuteValue"), True)          ; Allow participants to unmute
	SetSecuritySetting(GetUserSetting("ZoomSecurityShareScreenValue"), False)   ; Prevent screen sharing
	ToggleFeed("Audio", False)                  ; Turn off host audio
	ToggleFeed("Video", False)                  ; Turn off host video
	EnsureGalleryView()
	; TODO: Unmute All function
	Debug(t("INFO_CONFIG_BEFORE_AFTER_DONE"), "INFO")
EndFunc   ;==>_SetPreAndPostMeetingSettings

; Configures settings during active meetings
; - Disables unmute permission (host controls audio)
; - Disables screen sharing permission
; - Mutes all participants
; - Turns on host audio and video
Func _SetDuringMeetingSettings()
	Debug(t("INFO_MEETING_STARTING_SOON_CONFIG"), "INFO")
	Sleep(3000)
	If Not FocusZoomWindow() Then
		Return
	EndIf
	SetSecuritySetting(GetUserSetting("ZoomSecurityUnmuteValue"), False)         ; Prevent participant self-unmute
	SetSecuritySetting(GetUserSetting("ZoomSecurityShareScreenValue"), False)   ; Prevent screen sharing
	MuteAll()                                   ; Mute all participants
	ToggleFeed("Audio", True)                   ; Turn on host audio
	ToggleFeed("Video", True)                   ; Turn on host video
	PulseSpotlightHostVideo(5000)
	EnsureGalleryView()
	_OpenParticipantsPanel()
	_SnapZoomWindowToSide()
	Debug(t("INFO_CONFIG_DURING_MEETING_DONE"), "INFO")
EndFunc   ;==>_SetDuringMeetingSettings

; Runs a named automation scene (useful for external trigger integrations such as Electron)
; @param $sScene - Supported values: "prepost", "prestart"
; @return Boolean - True when a valid scene was executed
Func RunAutomationScene($sScene)
	Local $sNormalizedScene = StringLower(StringStripWS($sScene, 3))

	Switch $sNormalizedScene
		Case "prepost"
			Debug("Running automation scene: prepost", "INFO")
			If Not _GetZoomWindow() Then Return False
			_SetPreAndPostMeetingSettings()
			Return True

		Case "prestart"
			Debug("Running automation scene: prestart", "INFO")
			If Not _GetZoomWindow() Then Return False
			_SetDuringMeetingSettings()
			Return True

		Case Else
			Debug("Unknown automation scene requested: '" & $sScene & "'", "WARN")
			Return False
	EndSwitch
EndFunc   ;==>RunAutomationScene

; Checks current time against meeting schedule and applies appropriate settings
; @param $meetingTime - Scheduled meeting time in HH:MM format
; Checks current time against meeting schedule and applies appropriate settings
; @param $meetingTime - Scheduled meeting time in HH:MM format
; @return Integer - Recommended sleep time in milliseconds before next check
Func CheckMeetingWindow($meetingTime)
	If $meetingTime = "" Then Return 60000

	Local $nextCheckDelay = 5000     ; Default interval between checks

	; Parse meeting time
	Local $aParts = StringSplit($meetingTime, ":")
	Local $hour = Number($aParts[1])
	Local $min = Number($aParts[2])

	; Convert current time and meeting time to minutes for easier comparison
	Local $nowMin = Number(@HOUR) * 60 + Number(@MIN)
	Local $meetingMin = $hour * 60 + $min

	If $nowMin >= ($meetingMin - $PRE_MEETING_MINUTES) And $nowMin < ($meetingMin - $MEETING_START_WARNING_MINUTES) Then
		; Pre-meeting window (1 hour before to 1 minute before)
		If Not $g_PrePostSettingsConfigured Then
			Local $zoomLaunched = _LaunchZoom()
			If Not $zoomLaunched Then
				Debug(t("ERROR_ZOOM_LAUNCH"), "ERROR")
			Else
				_SetPreAndPostMeetingSettings()
				$g_PrePostSettingsConfigured = True
			EndIf
		EndIf
		$nextCheckDelay = 5000

	ElseIf $nowMin = ($meetingMin - $MEETING_START_WARNING_MINUTES) Then
		; Meeting start window (1 minute before meeting)
		If Not $g_DuringMeetingSettingsConfigured Then
			If Not _GetZoomWindow() Then Return 1000 ; Retry quickly if window not found
			_SetDuringMeetingSettings()
			$g_DuringMeetingSettingsConfigured = True
		EndIf
		$nextCheckDelay = 5000

	ElseIf $nowMin >= $meetingMin Then
		; Meeting already started
		Local $minutesAgo = $nowMin - $meetingMin
		If $minutesAgo <= 120 Then
			Debug(t("INFO_MEETING_STARTED_AGO", $minutesAgo), "INFO", $g_InitialNotificationWasShown)
			$nextCheckDelay = 30000 ; Check every 30 seconds if meeting already started
		Else
			Debug(t("INFO_OUTSIDE_MEETING_WINDOW"), "INFO", $g_InitialNotificationWasShown)
			$nextCheckDelay = 60000 ; Check every minute
		EndIf

	Else
		; Too early - show countdown to meeting
		Local $minutesLeft = $meetingMin - $nowMin

		If $minutesLeft > 60 Then
			; If > 1 hour away, check every minute
			; Only log if it's the first run to show we are alive, otherwise silence
			If Not $g_InitialNotificationWasShown Then
				Debug(t("INFO_MEETING_STARTING_IN", $minutesLeft), "INFO")
			EndIf
			$nextCheckDelay = 60000
		Else
			Debug(t("INFO_MEETING_STARTING_IN", $minutesLeft), "INFO", $g_InitialNotificationWasShown)
			$nextCheckDelay = 5000
		EndIf
	EndIf

	$g_InitialNotificationWasShown = True
	Return $nextCheckDelay
EndFunc   ;==>CheckMeetingWindow
