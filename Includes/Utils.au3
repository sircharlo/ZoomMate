#include-once
; ================================================================================================
; UTILITIES - Core utility functions
; ================================================================================================

#include "Globals.au3"
#include "GUI.au3"

; ================================================================================================
; UNICODE STRING HANDLING FUNCTIONS (Simplified)
; ================================================================================================

; Converts a Unicode string to UTF-8 bytes for INI file storage
; @param $sText - Unicode string to convert
; @return String - UTF-8 encoded string
Func _StringToUTF8($sText)
	Return BinaryToString(StringToBinary($sText, 4), 1)
EndFunc   ;==>_StringToUTF8

; Converts UTF-8 bytes from INI file back to Unicode string
; @param $sUTF8 - UTF-8 encoded string from INI file
; @return String - Unicode string
Func _UTF8ToString($sUTF8)
	Return BinaryToString(StringToBinary($sUTF8, 1), 4)
EndFunc   ;==>_UTF8ToString


; ================================================================================================
; DEBUG AND STATUS FUNCTIONS
; ================================================================================================

; Debug logging and status update function with enhanced formatting and user notification
; @param $string - Message to log/display
; @param $type - Message type (DEBUG, INFO, ERROR, SUCCESS, VERBOSE, etc.)
; @param $noNotify - If True, suppress overlay notifications
; @param $isVerbose - If True, this is verbose debug logging (only shown in console)
; @param $functionName - Name of the calling function (optional, auto-detected if not provided)
Func Debug($string, $type = "VERBOSE", $noNotify = False, $isVerbose = False)

	If ($string) Then
		; Format timestamp for better log readability
		Local $timestamp = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC

		; Console logging with enhanced formatting
		If $isVerbose Then
			; Verbose debug logging - only to console, no user notification
			ConsoleWrite("[" & $timestamp & "] " & " VERBOSE: " & $string & @CRLF)
		Else
			; Standard logging - to console with type identification
			ConsoleWrite("[" & $timestamp & "] " & $type & ": " & $string & @CRLF)

			; Update status for important messages (non-verbose)
			If $type = "INFO" Or $type = "ERROR" Then
				$g_StatusMsg = $string

				; Show overlay notification for important messages (unless suppressed)
				If Not $noNotify Then
					Local $isError = ($type = "ERROR")
					ShowOverlayMessage($string, $isError, Not $isError)
				EndIf
			EndIf

			; Change tray icon for errors
			If $type = "ERROR" Then
				TraySetIcon($g_TrayIcon, 1) ; Error icon
			EndIf
		EndIf
	EndIf
EndFunc   ;==>Debug

; Updates the tray icon tooltip with current status
Func UpdateTrayTooltip()
	TraySetToolTip("ZoomMate: " & $g_StatusMsg)
EndFunc   ;==>UpdateTrayTooltip
