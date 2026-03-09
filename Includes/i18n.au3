#include-once
; ================================================================================================
; ZoomMate Translation Manager - Imports all language files (5 languages supported)
; ================================================================================================

#include <StringConstants.au3>
#include <UserSettings.au3>

#include "en.au3"
#include "es.au3"
#include "fr.au3"
#include "ru.au3"
#include "uk.au3"

Global $TRANSLATIONS = 0

; Initialize translations for each language
_InitializeTranslations()

Func _InitializeTranslations()
	; Create dictionary lazily and make initialization idempotent.
	If Not IsObj($TRANSLATIONS) Then
		$TRANSLATIONS = ObjCreate("Scripting.Dictionary")
		If Not IsObj($TRANSLATIONS) Then
			Return SetError(1, 0, 0)
		EndIf
	EndIf

	; Avoid duplicate-key runtime errors when this function is called more than once.
	If $TRANSLATIONS.Exists("en") Then Return True

	$TRANSLATIONS.Add("en", $TRANSLATIONS_EN)
	$TRANSLATIONS.Add("es", $TRANSLATIONS_ES)
	$TRANSLATIONS.Add("fr", $TRANSLATIONS_FR)
	$TRANSLATIONS.Add("ru", $TRANSLATIONS_RU)
	$TRANSLATIONS.Add("uk", $TRANSLATIONS_UK)
	Return True
EndFunc   ;==>_InitializeTranslations

; Helper function to get translations for a specific language
; @param $langCode - Language code (e.g., "en", "es")
; @return Object - Dictionary containing translations for the specified language
Func _GetLanguageTranslations($langCode)
	; Ensure translations are initialized
	If (Not IsObj($TRANSLATIONS)) Or $TRANSLATIONS.Count = 0 Then _InitializeTranslations()

	If $TRANSLATIONS.Exists($langCode) Then
		Return $TRANSLATIONS.Item($langCode)
	Else
		; Fallback to English if requested language not found
		Return $TRANSLATIONS.Item("en")
	EndIf
EndFunc   ;==>_GetLanguageTranslations

; Builds a comma-separated list of available language display names
; @return String - Comma-separated list of language names
Func _ListAvailableLanguageNames()
	Local $list = ""
	; Ensure translations are initialized
	If (Not IsObj($TRANSLATIONS)) Or $TRANSLATIONS.Count = 0 Then _InitializeTranslations()

	For $langCode In $TRANSLATIONS.Keys
		Local $oLangTranslations = _GetLanguageTranslations($langCode)
		If $oLangTranslations.Exists("LANGNAME") Then
			Local $langName = $oLangTranslations.Item("LANGNAME")
			$list &= ($list = "" ? $langName : "|" & $langName)
		EndIf
	Next
	Return $list
EndFunc   ;==>_ListAvailableLanguageNames

; Gets the language code for a display name
; @param $displayName - Display name (e.g., "English", "Español")
; @return String - Language code or empty string if not found
Func _GetLanguageCodeFromDisplayName($displayName)
	; Ensure translations are initialized
	If (Not IsObj($TRANSLATIONS)) Or $TRANSLATIONS.Count = 0 Then _InitializeTranslations()

	For $langCode In $TRANSLATIONS.Keys
		Local $oLangTranslations = _GetLanguageTranslations($langCode)
		If $oLangTranslations.Exists("LANGNAME") And $oLangTranslations.Item("LANGNAME") = $displayName Then
			Return $langCode
		EndIf
	Next
	Return ""      ; Not found
EndFunc   ;==>_GetLanguageCodeFromDisplayName

; Gets the display name for a language code
; @param $code - Language code (e.g., "en", "es")
; @return String - Display name or the code itself if not found
Func _GetLanguageDisplayName($code)
	Local $oLangTranslations = _GetLanguageTranslations($code)
	If $oLangTranslations.Exists("LANGNAME") Then
		Return $oLangTranslations.Item("LANGNAME")
	EndIf
	Return $code
EndFunc   ;==>_GetLanguageDisplayName

; Translation lookup function with placeholder support
; @param $key - Translation key to look up
; @param $p0-$p2 - Optional placeholder values for {0}, {1}, {2} substitution
; @return String - Translated text with placeholders replaced
Func t($key, $p0 = Default, $p1 = Default, $p2 = Default)
	; Get the configured language from settings (fallback to English if not set)
	Local $currentLang = GetUserSetting("Language")
	If $currentLang = "" Then $currentLang = "en"

	; Get translations for the current language
	Local $oLangTranslations = _GetLanguageTranslations($currentLang)

	If $oLangTranslations.Exists($key) Then
		Local $s = $oLangTranslations.Item($key)
		; Replace placeholders if provided
		If $p0 <> Default Then $s = StringReplace($s, "{0}", $p0, 0, $STR_CASESENSE)
		If $p1 <> Default Then $s = StringReplace($s, "{1}", $p1, 0, $STR_CASESENSE)
		If $p2 <> Default Then $s = StringReplace($s, "{2}", $p2, 0, $STR_CASESENSE)
		Return $s
	EndIf

	; Ultimate fallback: return the key itself
	Return $key
EndFunc   ;==>t
