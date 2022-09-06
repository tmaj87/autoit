#include <Misc.au3>

Opt("MouseCoordMode", 2)
Opt("PixelCoordMode", 2)

HotKeySet("{DELETE}", "_Exit")
HotKeySet("{INSERT}", "_ToggleOnOff")
; HotKeySet("{INSERT}", "_GetMousePosition")
; HotKeySet("{INSERT}", "_Demo")

Global $resolution[2] = [2600, 1399]

Global $windowName = "xxx of yyy"
Global $processName = "poe.exe"
Global $windowHandle = WinGetHandle($windowName)
Global $user32 = DllOpen("user32.dll")
Global $now = TimerInit()

Global $healthCoord[2] = [182, 1168]
Global $healthChecksum = 0

Global $manaCoord[2] = [2424, 1341]
Global $manaChecksum = 0

Global $fullFlaskCoord[6][2] = [[0, 0], [412, 1334], [470, 1330], [529, 1331], [588, 1328], [644, 1330]]
Global $fullFlaskChecksum[6] = [0, 0, 0, 0, 0, 0]

Global $flaskInUseCoord[6][2] = [[0, 0], [394, 1353], [451, 1352], [511, 1351], [568, 1351], [626, 1350]]
Global $flaskInUseCheksum[6] = [0, 0, 0, 0, 0, 0]

Global $drinkDelay[6] = [0, 600, 600, 600, 600, 600]
Global $drinkTime[6] = [0, $now, $now, $now, $now, $now]

Global $inHideoutCoord[2] = [1644, 1324]
Global $inHideoutChecksum = 0

Global $masterSwitch = True

Dim $healthKeys[1] = [1]
; Global $healthKeys[2] = [1, 2]
; Global $manaKeys[1] = [3]
Global $cyclicKeys[4] = [2, 3, 4, 5]

WinActivate($windowHandle)
Sleep(1000)
WinMove($windowHandle, "", @DesktopWidth / 2 - $resolution[0] / 2, 0, $resolution[0], $resolution[1])
Sleep(1000)
InitVariables()

While True
	Local $inFlow = False
	Local $windowPosition
	If Not ProcessExists($processName) Then
		Exit
	EndIf
	If WinActive($windowHandle) Then
		$windowPosition = WinGetPos($windowHandle)
		$inFlow = IsInFlow()
		If $inFlow Then
			ToolTip("In flow", $windowPosition[0], $windowPosition[1])
			HealthWatch($healthKeys)
			; ManaWatch($manaKeys)
			CyclicWatch($cyclicKeys)
		Else
			ToolTip("Master switch: " & $masterSwitch, $windowPosition[0], $windowPosition[1])
		EndIf
	EndIf
WEnd

Func InitVariables()
	$healthChecksum = PixelGetColorWrapper($healthCoord[0], $healthCoord[1])
	$manaChecksum = PixelGetColorWrapper($manaCoord[0], $manaCoord[1])
	$inHideoutChecksum = PixelGetColorWrapper($inHideoutCoord[0], $inHideoutCoord[1])
	For $i = 1 to 5
		$fullFlaskChecksum[$i] = GetFlaskChecksum($i)
		$flaskInUseCheksum[$i] = GetFlaskCooldownChecksum($i)
	Next
EndFunc

Func PixelGetColorWrapper($x, $y)
	Return PixelGetColor($x, $y, $windowHandle)
EndFunc

Func GetFlaskChecksum($i)
	Return PixelGetColorWrapper($fullFlaskCoord[$i][0], $fullFlaskCoord[$i][1])
EndFunc

Func GetFlaskCooldownChecksum($i)
	Return PixelGetColorWrapper($flaskInUseCoord[$i][0], $flaskInUseCoord[$i][1])
EndFunc

Func PixelWatch($x, $y, $expected, ByRef $keys)
	Local $color
	For $key In $keys
		$color = PixelGetColorWrapper($x, $y)
		If $color <> $expected _
			And TimerDiff($drinkTime[$key]) > $drinkDelay[$key] _
		Then
			ControlSend($windowHandle, "", "", $key)
			$drinkTime[$key] = TimerInit()
		EndIf
	Next
EndFunc

Func HealthWatch(ByRef $keys)
	PixelWatch($healthCoord[0], $healthCoord[1], $healthChecksum, $keys)
EndFunc

Func ManaWatch(ByRef $keys)
	PixelWatch($manaCoord[0], $manaCoord[1], $manaChecksum, $keys)
EndFunc

Func CyclicWatch(ByRef $keys)
	Local $flaskChecksum
	Local $cooldownChecksum
	For $key In $keys
		$flaskChecksum = GetFlaskChecksum($key)
		$cooldownChecksum = GetFlaskCooldownChecksum($key)
		If $flaskChecksum = $fullFlaskChecksum[$key] _
			And $cooldownChecksum = $flaskInUseCheksum[$key] _
			And TimerDiff($drinkTime[$key]) > $drinkDelay[$key] _
		Then
			ControlSend($windowHandle, "", "", $key)
			$drinkTime[$key] = TimerInit()
		EndIf
	Next
EndFunc

Func IsInFlow()
	Local Static $idle = 0
	Local Static $lazyInit = 0
	Local $inHideout = PixelGetColorWrapper($inHideoutCoord[0], $inHideoutCoord[1])
	If Not $masterSwitch Then
		Return False
	EndIf
	If $inHideout = $inHideoutChecksum Then
		Return False
	EndIf
	If _IsPressed(1, $user32) _
		Or _IsPressed(2, $user32) _
		Or _IsPressed(5, $user32) _
		Or _IsPressed(6, $user32) _
	Then
		$idle = TimerInit()
	EndIf
	If TimerDiff($idle) < 1000 Then
		If TimerDiff($lazyInit) > 2000 Then
			Return True
		EndIf
	Else
		$lazyInit = TimerInit()
	EndIf
	Return False
EndFunc

Func _ToggleOnOff()
	$masterSwitch = Not $masterSwitch
EndFunc

Func _GetMousePosition()
	Local $position = MouseGetPos()
	ConsoleWrite(@CRLF & "mouse pos: " & $position[0] & " " & $position[1])
EndFunc

Func _Demo()
	WinActivate($windowHandle)
	Sleep(100)
	MouseMove($healthCoord[0], $healthCoord[1])
	Sleep(1000)
	For $i = 0 To UBound($fullFlaskCoord) - 1
		If $i = 0 Then
			ContinueLoop
		EndIf
		MouseMove($fullFlaskCoord[$i][0], $fullFlaskCoord[$i][1])
		Sleep(1000)
	Next
	For $i = 0 To UBound($flaskInUseCoord) - 1
		If $i = 0 Then
			ContinueLoop
		EndIf
		MouseMove($flaskInUseCoord[$i][0], $flaskInUseCoord[$i][1])
		Sleep(1000)
	Next
	MouseMove($manaCoord[0], $manaCoord[1])
EndFunc

Func _Exit()
	Exit
EndFunc
