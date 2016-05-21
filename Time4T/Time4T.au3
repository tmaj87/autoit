#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=C:\Program Files\AutoIt3\Aut2Exe\Icons\AutoIt_HighColor.ico
#AutoIt3Wrapper_outfile=release\Time4T.exe
#AutoIt3Wrapper_Res_Language=1045
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

DllCall("kernel32.dll", "int", "CreateMutex", "int", 0, "long", 1, "str", "Time4T")
$lastError = DllCall("kernel32.dll", "int", "GetLastError")
If $lastError[0] = 183 Then
	MsgBox(48, "Time4T", "Second run attempt", 2)
	Exit
EndIf
HotKeySet("{NUMPADSUB}", "_Exit")
Func _Exit()
	HotKeySet("{NUMPADSUB}")
	Exit
EndFunc
If @Compiled Then
	DirCreate(@AppDataDir&"\fn1oo software\Time4T")
	Global Const $sound = @AppDataDir&"\fn1oo software\Time4T\ring_signal2.wav"
	FileInstall("ring_signal2.wav", $sound)
EndIf
Global Const $title		= "Time4T (v1.0+)"
If @Compiled Then
	$preIni				= @AppDataDir&"\fn1oo software\Time4T\Time4T.ini"
Else
	$preIni				= "Time4T.ini"
EndIf
Global Const $ini		= $preIni

Global Const $WS_CAPTION			= 0x00C00000	; WindowsConstants.au3
Global Const $WS_SYSMENU			= 0x00080000	; WindowsConstants.au3
Global Const $WS_EX_TOPMOST			= 0x00000008	; WindowsConstants.au3
Global Const $GUI_EVENT_CLOSE		= -3			; GUIConstantsEx.au3
Global Const $GUI_SHOW				= 16			; GUIConstantsEx.au3
Global Const $GUI_HIDE 				= 32			; GUIConstantsEx.au3
Global Const $GUI_ENABLE			= 64			; GUIConstantsEx.au3
Global Const $GUI_DISABLE			= 128			; GUIConstantsEx.au3
Global Const $SS_CENTER				= 1				; StaticConstants.au3
Global Const $ES_NUMBER				= 8192			; EditConstants.au3

; version one+
; znane problemy:
;  podczas odliczania/alarmu przytrzymanie paska tytu³owego blokuje wykonywanie skryptu
$iRead = IniRead($ini, "time4T", "wait", "not found")
If $iRead = "not found" Or Int($iRead) < 1 Or Int($iRead) > 5940 Then
	IniWrite($ini, "time4T", "wait", 180)
	$wait = 180
Else
	$wait = Int($iRead)
EndIf

$gui = GUICreate($title, 150, 80, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
Dim $input[2]
$input[0] = GUICtrlCreateInput("00", 10, 10, 40, 30, $ES_NUMBER)
$input[1] = GUICtrlCreateInput("00", 60, 10, 40, 30, $ES_NUMBER)
$button = GUICtrlCreateButton("Start", 10, 50, 130, 20)
; GUICtrlSetFont(-1, 25)
$border = WinGetPos($gui)  ; change variable name..!
GUISetState(@SW_SHOW, $gui)

Dim $lastStr[2] = ["00", "00"]
While 1
	$gMsg = GUIGetMsg(1)
	If $gMsg[0] <> 0 Then
		ToolTip($gMsg[2])
		; nadal nie wiem jak w prosty sposób otrzymywaæ focus z input box'a...
		Select
			Case $gMsg[0] = $GUI_EVENT_CLOSE
				_Exit()
			Case $gMsg[0] = $button
				ExitLoop
			Case $gMsg[2] = $input[0]
				MsgBox(0, "", "0")
			Case $gMsg[2] = $input[1]
				MsgBox(0, "", "1")
		EndSelect
	EndIf
	#cs
	For $i = 0 To 1
		$msg = GUICtrlRead($input[$i])
		Sleep(10)
		If $msg <> $lastStr[$i] Then
			$msg = Int(StringLeft($msg, 2))
			$str = ""
			If $msg < 10 Then
				$str &= 0
			ElseIf $msg > 60 Then
				$msg = 60
			EndIf
			$str &= $msg
			GUICtrlSetData($input[$i], $str)
			$lastStr[$i] = $str
		EndIf
	Next
	#ce
WEnd

GUICtrlDelete($button)
$label = GUICtrlCreateLabel(StringFormat("%02i:%02i", $wait/60, Mod($wait, 60)), 5, 17, 140, 46, 1)
GUICtrlSetFont(-1, 30)
$now = WinGetPos($gui)
If $now[0] < $border[0]+20 And	$now[0] > $border[0]-20 And $now[1] < $border[1]+20 And $now[1] > $border[1]-20 Then
	$tray = WinGetPos("[CLASS:Shell_TrayWnd]")
	WinMove($gui, "", (@DesktopWidth-$border[2])-10, (@DesktopHeight-$border[3])-$tray[3]-10, $now[2], $now[3], 2)
EndIf
$lastSec = Mod($wait, 60)
$tInit = TimerInit()
While Int(TimerDiff($tInit)/1000) < $wait
	$tDiff = $wait-Int(TimerDiff($tInit)/1000)
	$sec = Mod($tDiff, 60)
	If $sec <> $lastSec Then
		GUICtrlSetData($label, StringFormat("%02i:%02i", $tDiff/60, $sec))
		$lastSec = $sec
	EndIf
WEnd
GUICtrlSetData($label, "00:00")
$gColor = 1
$tInitSound = TimerInit()
$tInitColor = TimerInit()
While 1
	If Int(TimerDiff($tInitSound)) > 900 Then
		If @Compiled Then
			If Not FileExists($sound) Then
				MsgBox(48, $title, "Sound file (ring_signal2.wav) missing!")
				_Exit()
			EndIf
			SoundPlay($sound)
		Else
			SoundPlay("ring_signal2.wav")
		EndIf
		$tInitSound = TimerInit()
	EndIf
	If Int(TimerDiff($tInitColor)) > 500 Then
		If $gColor Then
			GUICtrlSetColor($label, 0xFF0000)
			$gColor = 0
		ElseIf Not $gColor Then
			GUICtrlSetColor($label, 0x000000)
			$gColor = 1
		EndIf
		$tInitColor = TimerInit()
	EndIf
WEnd

; version two
; gui:
;  przyciski: time4T, minutnik
; time4T:
;  krok1: wybór, czarna/czerwona/zielona
;  krok2(je¿eli zielona): jak du¿o wody zosta³o zagotowane, 1/4l / 1/2l / 1l / wiêcej
;  krok3: moc herbaty, lekka/œrednia/mocna
;  krok4: odliczanie w³aœciwe
;  krok5: sygna³ koñca odliczania
;  zapamiêtuje ostatnie ustawienia
; minutnik:
;  trzy pola, format: [0-99]:[0-60]:[0-60], przycisk start/stop/reset, po rozpoczêciu odliczaia pola zmieniaj¹ siê na etykiety
;  czas zmniejsza siê co sekundê
;  sygnalizacja zakoñczenia odliczania
;  zapamiêtuje ostatnie ustawienia
#cs

$gui = GUICreate("Time4T", 200, 200, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
$gT4T = GUICtrlCreateButton("time4T", 40, 60, 120, 40)
GUICtrlSetFont(-1, 16)
$gTimer = GUICtrlCreateButton("minutnik", 60, 105, 80, 20)
$gBack = GUICtrlCreateButton("powrót", 130, 170, 60, 20)
GUICtrlSetState($gBack, BitOR($GUI_DISABLE, $GUI_HIDE))
GUISetState(@SW_SHOW)

While 1
	$gMsg = GUIGetMsg($gui)
	Switch $gMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $gT4T
			GUICtrlSetState($gT4T, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gTimer, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gBack, BitOR($GUI_ENABLE, $GUI_SHOW))
			;
			Dim $continue
			If $continue Then
				; ...
			EndIf
			If $continue Then
				; ...
			EndIf
			;
			GUICtrlSetState($gBack, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gT4T, BitOR($GUI_ENABLE, $GUI_SHOW))
			GUICtrlSetState($gTimer, BitOR($GUI_ENABLE, $GUI_SHOW))
		Case $gTimer
			GUICtrlSetState($gT4T, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gTimer, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gBack, BitOR($GUI_ENABLE, $GUI_SHOW))
			;
			Dim $gT_i[3], $gT_l[2], $gT_label
			For $i = 0 To 2
				$gT_i[$i] = GUICtrlCreateInput("", 13+($i*62), 53, 50, 42, BitOR($SS_CENTER, $ES_NUMBER))
				GUICtrlSetFont(-1, 24)
				; GUICtrlCreateUpdown(-1)
				GUICtrlSetLimit(-1, 2)
				$iRead = Int(IniRead("Time4T.ini", "timer", $i, 0))
				If $i Then
					If $iRead < 0 Or $iRead > 60 Then $iRead = 0
				Else
					If $iRead < 0 Or $iRead > 99 Then $iRead = 0
				EndIf
				GUICtrlSetData($gT_i[$i], StringFormat("%02i", $iRead))
				If $i < 2 Then
					$gT_l[$i] = GUICtrlCreateLabel(":", 64+($i*62), 55, 10, 42, $SS_CENTER)
					GUICtrlSetFont(-1, 24)
				EndIf
			Next
			$gT_start = GUICtrlCreateButton("start", 65, 100, 70, 30)
			$gT_reset = GUICtrlCreateButton("reset", 75, 130, 50, 20)
			While 1
				$gMsg = GUIGetMsg($gui)
				Switch $gMsg
					Case $GUI_EVENT_CLOSE
						Exit
					Case $gT_start
						If Not GUICtrlRead($gT_label) Then
							Dim $time[3]
							$time[0] = GUICtrlRead($gT_i[0])
							$time[1] = GUICtrlRead($gT_i[1])
							If $time[1] > 60 Then $time[1] = 60
							$time[2] = GUICtrlRead($gT_i[2])
							If $time[2] > 60 Then $time[2] = 60
							For $i = 0 To 2
								IniWrite("Time4T.ini", "timer", $i, $time[$i])
								GUICtrlDelete($gT_i[$i])
								If $i < 2 Then GUICtrlDelete($gT_l[$i])
							Next
							$gT_label = GUICtrlCreateLabel(StringFormat("%02i:%02i:%02i", $time[0], $time[1], $time[2]), 25, 53, 150, 42, $SS_CENTER)
							GUICtrlSetFont(-1, 24)
							GUICtrlSetData($gT_start, "stop")
						ElseIf GUICtrlRead($gT_label) Then
							If GUICtrlRead($gT_start) = "start" Then
								GUICtrlSetData($gT_start, "stop")
							ElseIf GUICtrlRead($gT_start) = "stop" Then
								GUICtrlSetData($gT_start, "start")
							EndIf
						EndIf
					Case $gT_reset
						If GUICtrlRead($gT_label) Then
							GUICtrlDelete($gT_label)
							$gT_label = 0
							For $i = 0 To 2
								$gT_i[$i] = GUICtrlCreateInput("", 13+($i*62), 53, 50, 42, BitOR($SS_CENTER, $ES_NUMBER))
								GUICtrlSetFont(-1, 24)
								GUICtrlSetLimit(-1, 2)
								$iRead = Int(IniRead("Time4T.ini", "timer", $i, 0))
								If $i Then
									If $iRead < 0 Or $iRead > 60 Then $iRead = 0
								Else
									If $iRead < 0 Or $iRead > 99 Then $iRead = 0
								EndIf
								GUICtrlSetData($gT_i[$i], StringFormat("%02i", $iRead))
								If $i < 2 Then
									$gT_l[$i] = GUICtrlCreateLabel(":", 64+($i*62), 55, 10, 42, $SS_CENTER)
									GUICtrlSetFont(-1, 24)
								EndIf
							Next
							GUICtrlSetData($gT_start, "start")
						EndIf
					Case $gBack
						For $i = 0 To 2
							GUICtrlDelete($gT_i[$i])
							If $i < 2 Then GUICtrlDelete($gT_l[$i])
						Next
						GUICtrlDelete($gT_start)
						GUICtrlDelete($gT_reset)
						GUICtrlDelete($gT_label)
						ExitLoop
				EndSwitch
			WEnd
			;
			GUICtrlSetState($gBack, BitOR($GUI_DISABLE, $GUI_HIDE))
			GUICtrlSetState($gT4T, BitOR($GUI_ENABLE, $GUI_SHOW))
			GUICtrlSetState($gTimer, BitOR($GUI_ENABLE, $GUI_SHOW))
	EndSwitch
WEnd
#ce
