Global $ini = "wall2paper.ini"

$iRead = IniRead($ini, "general", "timeOut", "null")
If $iRead = "null" Or Int($iRead) <= 0 Then IniWrite($ini, "general", "timeOut", "3600")

For $i = 0 To 2
	$iRead = IniRead($ini, "dir", $i, "null")
	If $iRead = "null" Or Not FileExists($iRead) Then
		If $i = 0 Then
			IniWrite($ini, "dir", $i, "wallpapers")
		Else
			IniWrite($ini, "dir", $i, "")
		EndIf
	EndIf
Next

$iRead = IniRead($ini, "general", "type", "null")
If $iRead = "null" Or Int($iRead) < 1 Or Int($iRead) > 3 Then IniWrite($ini, "general", "type", 3)

$iRead = IniRead($ini, "general", "hideTrayIcon", "null")
If $iRead = "null" Or Int($iRead) < 0 Or Int($iRead) > 1 Then IniWrite($ini, "general", "hideTrayIcon", 0)

Global $wpDir[3]
For $i = 0 To 2
	$wpDir[$i] = IniRead($ini, "dir", $i, "")
Next
Global $wpType = Int(IniRead($ini, "general", "type", 3))
Global $timeOut = Int(IniRead($ini, "general", "timeOut", "3600"))
Global $hideTray = Int(IniRead($ini, "general", "hideTrayIcon", 0))
