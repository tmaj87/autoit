; found, modified
Func _InstallFont($sFileName)
	Local Const $HWND_BROADCAST = 0xFFFF
	Local Const $WM_FONTCHANGE = 0x1D
	
	If FileCopy($sFileName, @WindowsDir &"\Fonts", 1) Then
		$sFileName = @WindowsDir &"\Fonts\"& StringTrimLeft($sFileName, StringInStr($sFileName, "\", 0, -1))
		DllCall("gdi32", "int", "AddFontResource", "str", $sFileName)
		DllCall("user32", "int", "SendMessage", "hwnd", $HWND_BROADCAST, "int", $WM_FONTCHANGE, "int", 0, "int", 0)
		Return 1
	EndIf
	Return 0
EndFunc

; cpu usage, not mine
Global $liOldIdleTime = 0
Global $liOldSystemTime = 0
; \/\/\/ Should do this \/\/\/ to initialize CPU time calculations, but not necessary. First call will, with a delay.
; CurrentCPU(1)
Func _CurrentCPU($init = 0)
    Local $SYS_BASIC_INFO = 0
    Local $SYS_PERFORMANCE_INFO = 2
    Local $SYS_TIME_INFO = 3

    $SYSTEM_BASIC_INFORMATION = DllStructCreate("int;uint;uint;uint;uint;uint;uint;ptr;ptr;uint;byte;byte;short")
    $status = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", "int", $SYS_BASIC_INFO, _
            "ptr", DllStructGetPtr($SYSTEM_BASIC_INFORMATION), _
            "int", DllStructGetSize($SYSTEM_BASIC_INFORMATION), _
            "int", 0)
    
    If $status[0] Then Return -1

   While 1
        $SYSTEM_PERFORMANCE_INFORMATION = DllStructCreate("int64;int[76]")
        $SYSTEM_TIME_INFORMATION = DllStructCreate("int64;int64;int64;uint;int")
        
        $status = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", "int", $SYS_TIME_INFO, _
                "ptr", DllStructGetPtr($SYSTEM_TIME_INFORMATION), _
                "int", DllStructGetSize($SYSTEM_TIME_INFORMATION), _
                "int", 0)
        
        If $status[0] Then Return -2

        $status = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", "int", $SYS_PERFORMANCE_INFO, _
                "ptr", DllStructGetPtr($SYSTEM_PERFORMANCE_INFORMATION), _
                "int", DllStructGetSize($SYSTEM_PERFORMANCE_INFORMATION), _
                "int", 0)

        If $status[0] Then Return -3
        
        If $init = 1 Or $liOldIdleTime = 0 Then
            $liOldIdleTime = DLLStructGetData($SYSTEM_PERFORMANCE_INFORMATION,1)
            $liOldSystemTime = DLLStructGetData($SYSTEM_TIME_INFORMATION,2)
            Sleep(1000)
            If $init = 1 Then Return -99
        Else
            $dbIdleTime = DLLStructGetData($SYSTEM_PERFORMANCE_INFORMATION,1) - $liOldIdleTime
            $dbSystemTime = DLLStructGetData($SYSTEM_TIME_INFORMATION,2) - $liOldSystemTime
            $liOldIdleTime = DLLStructGetData($SYSTEM_PERFORMANCE_INFORMATION,1)
            $liOldSystemTime = DLLStructGetData($SYSTEM_TIME_INFORMATION,2)

            $dbIdleTime = $dbIdleTime / $dbSystemTime

            $dbIdleTime = 100.0 - $dbIdleTime * 100.0 / DLLStructGetData($SYSTEM_BASIC_INFORMATION,11) + 0.5
            
            Return $dbIdleTime
        EndIf
        $SYSTEM_PERFORMANCE_INFORMATION = 0
        $SYSTEM_TIME_INFORMATION = 0
   WEnd
EndFunc

; found function, monitor on/off
Func _Monitor($io_control = "on")
	Local $WM_SYSCommand = 274
	Local $SC_MonitorPower = 61808
	Local $HWND = WinGetHandle("[CLASS:Progman]")
	Switch StringUpper($io_control)
		Case "OFF"
			DllCall("user32.dll", "int", "SendMessage", "hwnd", $HWND, "int", $WM_SYSCommand, "int", $SC_MonitorPower, "int", 2)
		Case "ON"
			DllCall("user32.dll", "int", "SendMessage", "hwnd", $HWND, "int", $WM_SYSCommand, "int", $SC_MonitorPower, "int", -1)
		; Case Else
			; MsgBox(32, @ScriptName, "Command usage: on/off")
	EndSwitch
EndFunc