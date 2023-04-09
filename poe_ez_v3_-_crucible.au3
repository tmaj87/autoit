#include <Misc.au3>
#include <Array.au3>

Opt("MouseCoordMode", 2)
Opt("PixelCoordMode", 2)

HotKeySet("{DELETE}", "_Exit")
HotKeySet("{INSERT}", "_ToggleOnOff")
; HotKeySet("{INSERT}", "_GetMousePosition")
; HotKeySet("{INSERT}", "_Demo")

; !!!
; EMPTY POTIONS BEFORE ENABLING! (EG. THROW AND PICKALL)
; !!!

; ---
; CONFIG
; ---
Global $hp = "1,2"
Global $mp = "3"
Global $util = "4,5"
; ---

Global $resolution[2] = [2600, 1399]

Global $windowName = "Path of Exile"
Global $processName = "PathOfExile.exe"
Global $windowHandle = WinGetHandle($windowName)
Global $user32 = DllOpen("user32.dll")
Global $now = TimerInit()

; Global $healthCoord[2] = [151, 1263] ; lifereserved ones ;
Global $healthCoord[2] = [182, 1168] ; regular ones
Global $healthChecksum = 0

Global $manaCoord[2] = [2424, 1331]
Global $manaChecksum = 0

gLOBAL $bubblePotionsDrinkDelay = 1000

Global $flaskCoords[6][2] = [[0, 0], [412, 1328], [470, 1328], [529, 1328], [588, 1328], [644, 1328]]
Global $emptyFlaskChecksum[6] = [0, 0, 0, 0, 0, 0]

Global $flaskInUseCoord[6][2] = [[0, 0], [394, 1353], [451, 1352], [511, 1351], [568, 1351], [626, 1350]]
Global $flaskInUseCheksum[6] = [0, 0, 0, 0, 0, 0]

Global $drinkDelay[6] = [0, 1000, 1000, 1000, 1000, 1000]
Global $drinkTime[6] = [0, $now, $now, $now, $now, $now]

Global $inHideoutCoord[2] = [1644, 1324]
Global $inHideoutChecksum = 0

Global $masterSwitch = True

Global $healthKeys = StringSplit($hp, ",", 2)
Global $manaKeys = StringSplit($mp, ",", 2)
Global $cyclicKeys = StringSplit($util, ",", 2)

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
			ManaWatch($manaKeys)
			CyclicWatch($cyclicKeys)
		Else
			ToolTip("Master switch: " & $masterSwitch, $windowPosition[0], $windowPosition[1])
		EndIf
	EndIf
WEnd

Func InitVariables()
	$healthChecksum = Checksum($healthCoord[0], $healthCoord[1])
	$manaChecksum = Checksum($manaCoord[0], $manaCoord[1])
	$inHideoutChecksum = Checksum($inHideoutCoord[0], $inHideoutCoord[1])
	For $i = 1 to 5
		$emptyFlaskChecksum[$i] = GetFlaskChecksum($i)
		$flaskInUseCheksum[$i] = GetFlaskCooldownChecksum($i)
	Next
EndFunc

Func Checksum($x, $y)
	Return PixelChecksum($x - 1, $y - 1, $x + 1, $y + 1, 1, $windowHandle)
EndFunc

Func GetFlaskChecksum($i)
	Return Checksum($flaskCoords[$i][0], $flaskCoords[$i][1])
EndFunc

Func GetFlaskCooldownChecksum($i)
	Return Checksum($flaskInUseCoord[$i][0], $flaskInUseCoord[$i][1])
EndFunc

Func HealthWatch(ByRef $keys)
	Local Static $lastDrunk
	$result = PixelWatch($healthCoord[0], $healthCoord[1], $healthChecksum, $lastDrunk, $keys)
	If $result Then
		$lastDrunk = TimerInit()
	EndIf
EndFunc

Func ManaWatch(ByRef $keys)
	Local Static $lastDrunk
	$result = PixelWatch($manaCoord[0], $manaCoord[1], $manaChecksum, $lastDrunk, $keys)
	If $result Then
		$lastDrunk = TimerInit()
	EndIf
EndFunc

Func PixelWatch($x, $y, $expected, $lastDrunk, ByRef $keys)
	Local $color
	Local $flaskChecksum
	If $keys[0] == "" Then
		Return False
	EndIf
	For $key In $keys
		$color = Checksum($x, $y)
		$flaskChecksum = GetFlaskChecksum($key)
		If $color <> $expected _
			And $flaskChecksum <> $emptyFlaskChecksum[$key] _
			And TimerDiff($drinkTime[$key]) > $drinkDelay[$key] _
			And TimerDiff($lastDrunk) > $bubblePotionsDrinkDelay _
		Then
			ControlSend($windowHandle, "", "", $key)
			$drinkTime[$key] = TimerInit()
			Return True
		EndIf
	Next
	Return False
EndFunc

Func CyclicWatch(ByRef $keys)
	Local $flaskChecksum
	Local $cooldownChecksum
	If $keys[0] == "" Then
		Return
	EndIf
	For $key In $keys
		$flaskChecksum = GetFlaskChecksum($key)
		$cooldownChecksum = GetFlaskCooldownChecksum($key)
		If $flaskChecksum <> $emptyFlaskChecksum[$key] _
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
	Local $inHideout = Checksum($inHideoutCoord[0], $inHideoutCoord[1])
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
	For $i = 0 To UBound($flaskCoords) - 1
		If $i = 0 Then
			ContinueLoop
		EndIf
		MouseMove($flaskCoords[$i][0], $flaskCoords[$i][1])
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
