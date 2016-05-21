#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_outfile=release/wall2paper.exe
#AutoIt3Wrapper_Res_Language=1045
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; fastnick1oo / Kecz4p
; 10.10.2007  v1.0.0
; 23.10.2007  v1.1.0
; 26.10.2007  v1.1.1
; 10.01.2008  v1.1.2

Global Const $scriptName = "wall2paper"

DllCall("kernel32.dll", "int", "CreateMutex", "int", 0, "long", 1, "str", $scriptName)
$lastError = DllCall("kernel32.dll", "int", "GetLastError")
If $lastError[0] == 183 Then
	Exit
EndIf

#include "wall2paper_ini.au3"  ; $wpDir[3], $wpType, $timeOut
FileInstall("pvw32con.exe", "pvw32con.exe")

Opt("OnExitFunc", "_Exit")
Opt("TrayMenuMode", 1)

HotKeySet("^{NUMPADSUB}", "_NextWallpaper")
HotKeySet("^{NUMPADADD}", "_ChangeIconState")

$trayChange = TrayCreateItem("Change wallpaper")
TrayCreateItem("")
$trayAbout = TrayCreateItem("About")
$trayExit = TrayCreateItem("Exit")
TraySetClick(8)
TraySetToolTip($scriptName)
If $hideTray == 1 Then
	TraySetState(2)
ElseIf $hideTray == 0 Then
	TraySetState(1)
EndIf

Global $timeStamp = TimerInit()
Global $current = ""
Global $showClock = 0
Global $randDir[4] = ["", "", "", ""]
Global $toolPos[3] = [0, 0, 0]


While 1
	$trayMsg = TrayGetMsg()
	If Int(TimerDiff($timeStamp)/1000) > $timeOut Then
		$trayMsg = $trayChange
	EndIf
	Switch $trayMsg
		Case -7  ; $TRAY_EVENT_PRIMARYDOWN
			If $showClock == 1 Then
				$showClock = 0
				TrayTip("", "", 1)
			ElseIf $showClock == 0 Then
				$showClock = 1
			EndIf

		Case $trayChange
			TraySetState(4)
			_NextWallpaper()
			TraySetState(8)

		Case $trayAbout
			MsgBox(0, $scriptName, "Copyright Kecz4p / fastnick1oo 2008" _
				&@CRLF&@CRLF& "Hotkeys:" &@CRLF& "CTRL+NUMPADSUB : Change wallpaper" &@CRLF& "CTRL+NUMPADADD : Show/hide tray icon" &@CRLF&  "LEFT MOUSE BUTTON on tray icon : Show/hide countdown clock" _
				&@CRLF&@CRLF& "What does it do?" &@CRLF& "It's serial wallpaper changer." _
				&@CRLF&@CRLF& "Config:" &@CRLF& "[general]" &@CRLF& "timeOut : in seconds" &@CRLF& "type : 1=tiled; 2=centered; 3=stretched" &@CRLF& "hideTrayIcon : 0/1" &@CRLF& "[dir]" &@CRLF& "1, 2, 3 : wallpaper directories")

		Case $trayExit
			_Exit()
	EndSwitch

	If $showClock == 1 Then
		If $current <> "" Then
			ToolTip("current: "& $current &@CRLF& _TickTackClock(($timeOut*1000)-TimerDiff($timeStamp)), 15, 15)
		Else
			ToolTip(_TickTackClock(($timeOut*1000)-TimerDiff($timeStamp)), 15, 15)
		EndIf
	Else
		ToolTip("")
	EndIf
WEnd


Func _NextWallpaper()
	$randDir[0] = 0
	For $i = 0 To 2
		If FileExists($wpDir[$i]) Then
			$randDir[0] += 1
			$randDir[$randDir[0]] = $wpDir[$i]
		EndIf
	Next
	If $randDir[0] > 0 Then
		$dir = $randDir[Random(1, $randDir[0], 1)]
	Else
		$dir = ""
	EndIf
	$files = _DirGetFilesToArray($dir)
	If IsArray($files) Then
		If $files[0] > 1 Then
			Do
				$randFile = Random(1, $files[0], 1)
			Until $current <> $files[$randFile]
		Else
			$randFile = 1
		EndIf
		$current = $files[$randFile]
		_ChangeWallpaper($dir&"\"&$current, $wpType)
	EndIf
	$timeStamp = TimerInit()
EndFunc

Func _ChangeIconState()
	If $hideTray == 1 Then
		TraySetState(1)
		$hideTray = 0
	ElseIf $hideTray == 0 Then
		TraySetState(2)
		$hideTray = 1
	EndIf
EndFunc

Func _ChangeWallpaper($iFile, $iType)
	If Not FileExists($iFile) Then SetError(1, 0, 0)  ; file is missing
	If StringRight($iFile, 3) <> "bmp" Then
		Switch StringRight($iFile, 4)
			Case ".jpg"
				;
			Case "jpeg"
				;
			Case ".png"
				;
			Case ".gif"
				;
			Case Else
				SetError(2, 0, 0)  ; unsupported format
		EndSwitch
		RunWait("pvw32con.exe "&'"'&$iFile&'"'&" -w --o "&'"'&@WindowsDir&"\wall2paper.bmp"&'"', "", @SW_HIDE)
	Else
		FileCopy($iFile, @WindowsDir&"\wall2paper.bmp", 1)
	EndIf
	Switch $iType
		Case 1  ; tiled
			RegWrite("HKCU\Control Panel\Desktop", "TileWallpaper", "REG_SZ", "1")
			RegWrite("HKCU\Control Panel\Desktop", "WallpaperStyle", "REG_SZ", "0")
		Case 2  ; centered
			RegWrite("HKCU\Control Panel\Desktop", "TileWallpaper", "REG_SZ", "0")
			RegWrite("HKCU\Control Panel\Desktop", "WallpaperStyle", "REG_SZ", "0")
		Case 3  ; stretched
			RegWrite("HKCU\Control Panel\Desktop", "TileWallpaper", "REG_SZ", "0")
			RegWrite("HKCU\Control Panel\Desktop", "WallpaperStyle", "REG_SZ", "2")
		Case Else
			SetError(3, 0, 0)  ; wrong iType
	EndSwitch
	RegWrite("HKCU\Control Panel\Desktop", "Wallpaper", "REG_SZ", @WindowsDir&"\wall2paper.bmp")
	DllCall("user32", "int", "SystemParametersInfo", "int", 20, "int", 0, "str", @WindowsDir&"\wall2paper.bmp", "int", 0)
	Return 1
EndFunc

Func _DirGetFilesToArray($iDir)
	If Not FileExists($iDir) Then SetError(1, 0, 0)  ; dir is missing
	Local $oFileList[1] = [0]
	Local $sHandle = FileFindFirstFile($iDir&"\*")
	While 1
		$sFile = FileFindNextFile($sHandle)
		If @error Then ExitLoop
		If Not StringInStr(FileGetAttrib($iDir&"\"&$sFile), "D") Then
			$oFileList[0] = UBound($oFileList)
			ReDim $oFileList[UBound($oFileList)+1]
			$oFileList[UBound($oFileList)-1] = $sFile
		EndIf
	WEnd
	FileClose($sHandle)
	Return $oFileList
EndFunc

Func _TickTackClock($iTicks)
	If Not IsNumber($iTicks) Then SetError(1, 0, 0)  ; invalid ticks
	If $iTicks < 0 Then SetError(2, 0, "00:00:00")  ; 0 ticks
	$iTicks = Int($iTicks/1000)
	Local $y = Int($iTicks/31536000)
	Local $d = Mod(Int($iTicks/86400), 365)
	Local $h = Mod(Int($iTicks/3600), 24)
	Local $m = Mod(Int($iTicks/60), 60)
	Local $s = Mod($iTicks, 60)
	If $d = 0 Then
		Return StringFormat("%02i:%02i:%02i", $h, $m, $s)
	ElseIf $d = 1 Then
		Return StringFormat("1 day %02i:%02i:%02i", $h, $m, $s)
	ElseIf $d > 1 Then
		If $y = 0 Then
			Return StringFormat("%i days %02i:%02i:%02i", $d, $h, $m, $s)
		ElseIf $y = 1 Then
			Return StringFormat("1 year %i days %02i:%02i:%02i", $d, $h, $m, $s)
		ElseIf $y > 1 Then
			Return StringFormat("%i years %i days %02i:%02i:%02i", $y, $d, $h, $m, $s)
		EndIf
	EndIf
EndFunc

Func _Exit()
	HotKeySet("^{NUMPADSUB}")
	HotKeySet("^{NUMPADADD}")
	Exit
EndFunc
