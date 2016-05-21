#NoTrayIcon
AutoItSetOption("TrayMenuMode", 1)
AutoItSetOption("TrayOnEventMode", 1)
Global Const $GUI_EVENT_CLOSE		= -3
Global Const $WS_CAPTION			= 0x00C00000
Global Const $WS_SYSMENU			= 0x00080000
Global Const $VK_MEDIA_NEXT_TRACK	= 0xB0
Global Const $VK_MEDIA_PREV_TRACK	= 0xB1
Global Const $sName					= "radio script v0.12"
Global Const $debug					= 0
Global Const $debugToFile			= @ScriptDir&"\"& StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) &"log"
; changelog:
; 0.00 -> 0.10 (?):
;  beginning, idea became script/program
; 0.10 -> 0.11 (?):
;  script rewrote, now using object events
; 0.11 -> 0.12 (09.06.2009):
;  removed bug when "Set volume"/"About" was clicked more then once and runs as follows (same item)
;  added dynamic volume change when moving slider
;  changed info display method
; 0.11 -> 0.13 (18.06.2009):
;  removed bug with info display, when radio was stopped for too long
;  added debug

Func _SendMessage($hWnd, $iMsg, $wParam = 0, $lParam = 0, $iReturn = 0, $wParamType = "wparam", $lParamType = "lparam", $sReturnType = "lparam")
	Local $aResult = DllCall("user32.dll", $sReturnType, "SendMessage", "hwnd", $hWnd, "int", $iMsg, $wParamType, $wParam, $lParamType, $lParam)
	If @error Then Return SetError(@error, @extended, "")
	If $iReturn >= 0 And $iReturn <= 4 Then Return $aResult[$iReturn]
	Return $aResult
EndFunc
Func _GUICtrlSlider_GetPos($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, 0x400)  ; $TBM_GETPOS -> $TBM_GETPOS = $TWM_USER -> $TWM_USER = 0x400
EndFunc
Func _GUICtrlSlider_SetPos($hWnd, $iPosition)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	_SendMessage($hWnd, 0x405, True, $iPosition)  ; $TBM_SETPOS = ($TWM_USER + 5) -> 0x405
EndFunc

DllCall("kernel32.dll", "int", "CreateMutex", "int", 0, "long", 1, "str", $sName)
$lastError = DllCall("kernel32.dll", "int", "GetLastError")
If $lastError[0] == 183 Then
	$wList = WinList("[TITLE:"& $sName &"]")
	If $wList[0][0] > 0 Then
		For $i = 1 To $wList[0][0]
			If WinGetProcess($wList[$i][1]) <> @AutoItPID Then WinActivate($wList[$i][1])
		Next
	EndIf
	Exit
EndIf

Global $player		= 0
Global $pEvent		= 0
Global $pURL		= "http://www.polskieradio.pl/st/program3M.asx"
Global $pVolume		= 30
Global $lastBuffer	= -1
Global $infoStr		= ""

If $CmdLine[0] > 1 Then
	For $i = 1 To $CmdLine[0]
		If $i < $CmdLine[0] Then
			Switch $CmdLine[$i]
				Case "-volume", "-v", "/volume", "/v"
					$tmpInt = Int($CmdLine[$i+1])
					If $tmpInt > 0 And $tmpInt <= 100 Then
						$pVolume = $tmpInt
					Else
						MsgBox(48, $sName, "Invalid volume parameter.")
					EndIf

					Case "-url", "-u", "/url", "/u"
					If StringLeft($CmdLine[$i+1], 7) == "http://" Then
						$pURL = $CmdLine[$i+1]
					Else
						MsgBox(48, $sName, "Invalid URL parameter.")
					EndIf
			EndSwitch
		EndIf
	Next
EndIf

$tVolume = TrayCreateItem("Set volume")
$tState = TrayCreateItem("Stop")
TrayCreateItem("")
$tAbout = TrayCreateItem("About")
$tExit = TrayCreateItem("Exit")
TraySetClick(8)
TraySetIcon("shell32.dll", 247)
TraySetToolTip($sName)
TrayItemSetOnEvent($tVolume, "_tEvent")
TrayItemSetOnEvent($tState, "_tEvent")
TrayItemSetOnEvent($tAbout, "_tEvent")
TrayItemSetOnEvent($tExit, "_tEvent")
TraySetState(1)

$player = ObjCreate("WMPlayer.OCX.7")
If @error Then
	MsgBox(16, $sName, "Error occured while creating object.", 5)
	Exit
EndIf
$pEvent = ObjEvent($player, "_WMPOCXEvents_", "_WMPOCXEvents")
If @error Then
	MsgBox(16, $sName, "Error occured creating object event handler.", 5)
	Exit
EndIf
If $player.isOnline == 0 Then
	MsgBox(16, $sName, "First connect to the internet.", 5)
	Exit
EndIf
$player.URL = $pURL
$player.settings.volume = $pVolume
HotKeySet("{MEDIA_NEXT}", "_VolumeUp")
HotKeySet("{MEDIA_PREV}", "_VolumeDown")
While 1
	Sleep(25)
	If $infoStr == "null" Then
		ToolTip("")
		$infoStr = ""
	ElseIf $infoStr <> "" Then
		ToolTip(StringRegExpReplace($pURL, "http://|www.", "") &@CRLF& $infoStr, 10, 10)
	EndIf
WEnd

Func _tEvent()
	Local $gui = 0
	Local $gSlider = 0
	Local $gMsg = 0
	Local $callResult = 0
	Local $user32 = "user32.dll"


	TrayItemSetOnEvent(@TRAY_ID, "")
	Switch @TRAY_ID
		Case $tVolume
			ToolTip("")
			$user32 = DllOpen($user32)
			If $user32 == -1 Then
				MsgBox(16, $sName, "Couldn't open DLL.", 5)
				Exit
			EndIf
			$gui = GUICreate("Volume", 150, 45, @DesktopWidth-200, @DesktopHeight-200, $WS_CAPTION+$WS_SYSMENU)
			$gSlider = GUICtrlCreateSlider(5, 5, 140, 35)
			GUICtrlSetLimit($gSlider, 100, 0)
			GUICtrlSetData($gSlider, $pVolume)
			GUISetState(@SW_SHOW, $gui)
			$tmpSliderPos = $pVolume
			Do
				$gMsg = GUIGetMsg()
				If $gMsg == -11 Or $gMsg == $gSlider Then  ; $GUI_EVENT_MOUSEMOVE
					$tmpSliderPos =  _GUICtrlSlider_GetPos($gSlider)
					If $tmpSliderPos <> $pVolume Then
						$pVolume = $tmpSliderPos
						$player.settings.volume = $pVolume
					EndIf
				EndIf
				$callResult = DllCall($user32, "int", "GetAsyncKeyState", "int", $VK_MEDIA_PREV_TRACK)
				If Not @error And BitAND($callResult[0], 0x8000) = 0x8000 Then
					_GUICtrlSlider_SetPos($gSlider, $pVolume)
				EndIf
				$callResult = DllCall($user32, "int", "GetAsyncKeyState", "int", $VK_MEDIA_NEXT_TRACK)
				If Not @error And BitAND($callResult[0], 0x8000) = 0x8000 Then
					_GUICtrlSlider_SetPos($gSlider, $pVolume)
				EndIf
			Until $gMsg == $GUI_EVENT_CLOSE
			ToolTip("")
			GUIDelete($gui)
			DllClose($user32)

		Case $tState
			If TrayItemGetText($tState) == "Stop" Then
				TrayItemSetText($tState, "Play")
				$player.controls.stop()
			ElseIf TrayItemGetText($tState) == "Play" Then
				TrayItemSetText($tState, "Stop")
				$player.controls.play()
			EndIf

		Case $tAbout
			MsgBox(64, $sName, "Created by fastnick1oo (Tomasz Maj)" &@CRLF& "Build date: ...")

		Case $tExit
			Exit
	EndSwitch
	TrayItemSetOnEvent(@TRAY_ID, "_tEvent")
EndFunc

; a co gdy uruchomione jest okienko od zmiany glosnosci?
; wtedy te funkcje kluca sie ze sliderem
Func _VolumeUp()
	If $pVolume < 100 Then
		$pVolume += 10
		If $pVolume > 100 Then $pVolume = 100
	EndIf
	$player.settings.volume = $pVolume
EndFunc
Func _VolumeDown()
	If $pVolume > 0 Then
		$pVolume -= 10
		If $pVolume < 0 Then $pVolume = 0
	EndIf
	$player.settings.volume = $pVolume
EndFunc

; http://msdn.microsoft.com/en-us/library/dd564680(VS.85).aspx
Func _WMPOCXEvents_($pEvent)
	; ConsoleWrite($pEvent &@CRLF)
EndFunc
Func _WMPOCXEvents_AudioLanguageChange($langID)
	; ConsoleWrite("AudioLanguageChange: "& $langID &@CRLF)
EndFunc
Func _WMPOCXEvents_StatusChange()
	; ConsoleWrite("StatusChange" &@CRLF)
EndFunc
Func _WMPOCXEvents_OpenStateChange($newState)
	; ConsoleWrite("OpenStateChange: "& $newState &@CRLF)
EndFunc
Func _WMPOCXEvents_CurrentItemChange($pdispMedia)
	; ConsoleWrite("CurrentItemChange: "& $pdispMedia &@CRLF)
EndFunc
Func _WMPOCXEvents_CurrentPlaylistChange($change)
	; ConsoleWrite("CurrentPlaylistChange: "& $change &@CRLF)
EndFunc
Func _WMPOCXEvents_CurrentMediaItemAvailable($bstrItemName)
	; ConsoleWrite("CurrentMediaItemAvailable: "& $bstrItemName &@CRLF)
EndFunc
Func _WMPOCXEvents_PlayStateChange($newState)
	ConsoleWrite("PlayStateChange: "& $newState &@CRLF)
	Switch $newState
		Case 7  ; wait
		Case 6
			$tmpInt = $player.network.bufferingProgress
			If $tmpInt <> $lastBuffer Then
				$infoStr = "Buffering... ("& $tmpInt &"%)"
				$lastBuffer = $tmpInt
			EndIf
		Case 1, 3
			$infoStr = "null"
		Case 9
			$infoStr = "(Re)Connecting..."
		Case Else
			$player.controls.play()
	EndSwitch
	If $debug == 1 Then FileWriteLine($debugToFile, @YEAR&"-"&@MON&"-"&@MDAY&" "&@HOUR&":"&@MIN&":"&@SEC&":"&@MSEC&" _WMPOCXEvents_PlayStateChange = "& $newState &", $infoStr = "& $infoStr)
EndFunc
Func _WMPOCXEvents_PlaylistChange($playlist, $change)
	; ConsoleWrite("PlaylistChange: "& $playlist &", "& $change &@CRLF)
EndFunc
Func _WMPOCXEvents_Buffering($start)
	; ConsoleWrite("Buffering: "& $start &@CRLF)
EndFunc
Func _WMPOCXEvents_MediaChange($pItem)
	; ConsoleWrite("MediaChange: "& $pItem &@CRLF)
EndFunc
Func _WMPOCXEvents_MediaError($pMediaObject)
	; ConsoleWrite("MediaError: "& $pMediaObject &@CRLF)
EndFunc
Func _WMPOCXEvents_Error()
	; ConsoleWrite("Error" &@CRLF)
EndFunc
