#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=C:\Program Files\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_outfile=\release\1h_breaker.exe
#AutoIt3Wrapper_UseAnsi=y
#AutoIt3Wrapper_Res_Description=fastnick1oo / Kecz4p
#AutoIt3Wrapper_Res_Fileversion=0.0.0.12
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_Language=1045
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#AutoIt3Wrapper_Run_Obfuscator=y
#Obfuscator_Parameters=/cs 1 /cn 1 /cf 1 /cv 1 /sf 1 /sv 1
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "1h_breaker_header.au3"
; Kecz4p / fastnick1oo
; 12.01.2008 - 13.01.2008
; 07.06.2008 - 11.06.2008
; 24.06.2008
; losowa czcionka dla komunikatu - ?
Global Const $scriptName = "1H Breaker"

DllCall("kernel32.dll", "int", "CreateMutex", "int", 0, "long", 1, "str", $scriptName)
$lastError = DllCall("kernel32.dll", "int", "GetLastError")
If $lastError[0] = 183 Then
	MsgBox(48, $scriptName, "Second run attempt", 2)
	Exit
EndIf

Opt("WinTitleMatchMode", 4)

Global Const $WS_POPUP					= 0x80000000
Global Const $WS_EX_TOOLWINDOW			= 0x00000080
Global Const $WS_EX_TOPMOST				= 0x00000008
Global Const $ES_CENTER					= 1
Global Const $GUI_EVENT_CLOSE			= -3
Global Const $GUI_EVENT_PRIMARYDOWN		= -7
Global Const $SPI_GETSCREENSAVERRUNNING = 114

; ini part
Global Const $iniFile = StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) &"ini"
If Not FileExists($iniFile) Then IniWrite($iniFile, "general", "demo", 1)
$demo = Int(IniRead($iniFile, "general", "demo", 1))
If $demo Then
	Dim $times[2] = [5, 10]
Else
	Dim $times[2] = [60*60, 5*60]
EndIf
; end of ini part
Global Const $activityTime = $times[0]
Global Const $breakTime = $times[1]
Global Const $showCPUUsage = 1
Global Const $wakeUpAfter = 1

If Not Int(IniRead($iniFile, "general", "introduced", 0)) Then
	MsgBox(64, $scriptName, "Too tierd of wasting hours in front of PC? 1 hour breaker will help You.", 15)
	IniWrite($iniFile, "general", "introduced", 1)
	If @Compiled And MsgBox(4+32, $scriptName, "Run at Windows startup?") == 6 Then FileCreateShortcut(@ScriptFullPath, @StartupDir &"\"& $scriptName &".lnk", @ScriptDir)
EndIf

If Not FileExists(@WindowsDir &"\Fonts\dinstik.ttf") Then
	FileInstall("fonts/dinstik.ttf", "dinstik.ttf")
	_InstallFont("dinstik.ttf")
	FileDelete("dinstik.ttf")
EndIf

Global $hoverWin = 0
Global $lastSec = -1
Global $videoWastedTime = 0
Global $screenSaverTime = 0
Global $breakTicks = TimerInit() ; main clock
Global $iState = DllStructCreate("int")
DllStructSetData($iState, 1, 0)
While 1
	If Not WinExists($hoverWin) Then
		$hoverWin = GUICreate($scriptName, @DesktopWidth, @DesktopHeight, 0, 0, $WS_POPUP, $WS_EX_TOOLWINDOW+$WS_EX_TOPMOST)
		GUISetBkColor("0x000000", $hoverWin)
		GUISetFont(14, 400, 0, "dinstik", $hoverWin)
		$breakLbl = GUICtrlCreateLabel("GET A BREAK", 0, @DesktopHeight/2-100, @DesktopWidth, 200, $ES_CENTER)
		GUICtrlSetFont($breakLbl, 120)
		GUICtrlSetColor($breakLbl, "0xFFFFFF")
		$breakClock = GUICtrlCreateLabel("", 0, @DesktopHeight/2+110, @DesktopWidth, 40, $ES_CENTER)
		GUICtrlSetColor($breakClock, "0xFFFFFF")
		GUISetCursor(16, 1, $hoverWin)
		WinSetTrans($hoverWin, "", 200)
		If Int(TimerDiff($breakTicks)/1000) > $activityTime-$screenSaverTime Then GUISetState(@SW_SHOW, $hoverWin)
	EndIf
	
	If Int(TimerDiff($breakTicks)/1000) == $activityTime+$screenSaverTime-180 Then
		If Not WinActive("[CLASS:MediaPlayerClassicW]") And Not WinActive("[CLASS:WMPlayerApp") And Not WinActive("[CLASS:Media Player 2") Then ; mpc/wmp addon
			MsgBox(48, $scriptName, "Three minutes left.", 5)
		EndIf
	ElseIf Int(TimerDiff($breakTicks)/1000) > $activityTime+$screenSaverTime And Not BitAnd(WinGetState($hoverWin), 2) Then
		; mpc/wmp addon
		$videoTick = TimerInit()
		While WinActive("[CLASS:MediaPlayerClassicW]") Or WinActive("[CLASS:WMPlayerApp") Or WinActive("[CLASS:Media Player 2")
			Sleep(250)
		WEnd
		$videoWastedTime = Int(TimerDiff($videoTick)/1000)
		; end of mpc/wmp addon
		If Not BitAND(WinGetState($hoverWin), 2) Then
			$lastSec = -1 ; reset last second
			GUISetState(@SW_SHOW, $hoverWin)
			ToolTip("")
		EndIf
	ElseIf Int(TimerDiff($breakTicks)/1000) > $activityTime+$screenSaverTime+$videoWastedTime+$breakTime-1 Then
		GUICtrlSetData($breakClock, "")
		GUICtrlSetData($breakLbl, "Click")
		If $wakeUpAfter Then _Monitor("on")
		Do
			If Not WinActive($hoverWin) Then WinActivate($hoverWin)
			$seconds = Int(TimerDiff($breakTicks)/1000)
			If Mod($seconds, 60) <> $lastSec Then ; every second event
				GUICtrlSetColor($breakLbl, "0x"& Hex(Random(0, 200, 1), 2) & Hex(Random(0, 200, 1), 2) & Hex(Random(0, 200, 1), 2))
				$lastSec = Mod($seconds, 60)
			EndIf
			$guiMsg = GUIGetMsg()
		Until $guiMsg == $GUI_EVENT_CLOSE Or $guiMsg == $GUI_EVENT_PRIMARYDOWN
		GUISetState(@SW_HIDE, $hoverWin)
		GUICtrlSetColor($breakLbl, "0xFFFFFF")
		GUICtrlSetData($breakLbl, "GET A BREAK")
		$videoWastedTime = 0
		$screenSaverTime = 0
		$breakTicks = TimerInit()
		If $demo Then
			MsgBox(64, $scriptName, "This is demo version. Change 'demo=1' to 'demo=0' in "& $iniFile &" to get full version.", 10)
			Exit
		EndIf
	ElseIf Int(TimerDiff($breakTicks)/1000) > $activityTime+$screenSaverTime Then
		If Not WinActive($hoverWin) Then WinActivate($hoverWin)
		$seconds = $activityTime+$screenSaverTime+$videoWastedTime+$breakTime-Int(TimerDiff($breakTicks)/1000)
		If Mod($seconds, 60) <> $lastSec Then ; every second event
			If $seconds == $breakTime-15 Then _Monitor("off")
			GUICtrlSetData($breakClock, StringFormat("%02i:%02i left", Mod(Int($seconds/60), 60), Mod($seconds, 60)))
			$lastSec = Mod($seconds, 60)
			$guiMsg = GUIGetMsg() ; removes gui event storage
		EndIf
	Else
		$seconds = Int(TimerDiff($breakTicks)/1000)-$screenSaverTime
		If Mod($seconds, 60) <> $lastSec Then ; every second event
			DllCall("user32.dll", "int", "SystemParametersInfo", "int", $SPI_GETSCREENSAVERRUNNING, "int", 0, "ptr", DllStructGetPtr($iState), "int", 0)
			If Not @error Then
				If DllStructGetData($iState, 1) Then
					ToolTip("")
					$dll = DllOpen("user32.dll")
					$screenSaverTick = TimerInit()
					Do
						Sleep(250)
						DllCall($dll, "int", "SystemParametersInfo", "int", $SPI_GETSCREENSAVERRUNNING, "int", 0, "ptr", DllStructGetPtr($iState), "int", 0)
					Until Not DllStructGetData($iState, 1)
					DllClose($dll)
					$screenSaverTime = Int(TimerDiff($screenSaverTick)/1000)
				EndIf
			EndIf
			
			If Not WinActive("[CLASS:MediaPlayerClassicW]") And Not WinActive("[CLASS:WMPlayerApp") And Not WinActive("[CLASS:Media Player 2") Then ; mpc/wmp addon
				If WinActive("[TITLE:Brood War; CLASS:SWarClass]") Then
					ToolTip(StringFormat("%02i:%02i", Mod(Int($seconds/60), 60), Mod($seconds, 60)) &", "& Int(_CurrentCPU()) &"%", 40, 20)
				Else
					If Int(TimerDiff($breakTicks)/1000) > $activityTime+$screenSaverTime-180 Then
						ToolTip("CPU "&  Int(_CurrentCPU()) &"%", @DesktopWidth-65, @DesktopHeight-75, StringFormat("brk %02i:%02i", Mod(Int($seconds/60), 60), Mod($seconds, 60)), 2, 2) ; get taskbar height?
					Else
						ToolTip("CPU "&  Int(_CurrentCPU()) &"%", @DesktopWidth-65, @DesktopHeight-75, StringFormat("brk %02i:%02i", Mod(Int($seconds/60), 60), Mod($seconds, 60)), 0, 2) ; get taskbar height?
					EndIf
				EndIf
			Else
				ToolTip("")
			EndIf
			$lastSec = Mod($seconds, 60)
		EndIf
	EndIf
	
	Sleep(250)
WEnd
