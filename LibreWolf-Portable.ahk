; LibreWolf Portable - https://github.com/ltGuillaume/LibreWolf-Portable
;@Ahk2Exe-SetFileVersion 1.4.0

;@Ahk2Exe-Bin Unicode 64*
;@Ahk2Exe-SetDescription LibreWolf Portable
;@Ahk2Exe-SetMainIcon LibreWolf-Portable.ico
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,160`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

ProgramPath     := A_ScriptDir "\LibreWolf"
ExeFile         := ProgramPath "\librewolf.exe"
ProfilePath     := A_ScriptDir "\Profiles\Default"
MozCommonPath   := A_AppDataCommon "\Mozilla-1de4eec8-1241-4177-a864-e594e8d1fb38"
PortableRunning := False

; Strings
_Title                = LibreWolf Portable
_NoDefaultBrowser     = Could not open your default browser.
_GetProgramPathError  = Could not find the path to LibreWolf:`n%ProgramPath%
_GetProfilePathError  = Could not find the path to the profile folder:`n%ProfilePath%`nIf this is the first time you are running LibreWolf Portable, you can ignore this. Continue?
_BackupKeyFound       = A backup registry key has been found:
_BackupFoundActions   = This means LibreWolf Portable has probably not been closed correctly. Continue to restore the found backup key after running, or remove the backup key yourself and press Retry to back up the current key.
_ErrorStarting        = LibreWolf could not be started. Exit code:
_MissingDLLs          = You probably don't have msvcp140.dll and vcruntime140.dll present on your system. Put these files in the folder %ProgramPath%,`nor install the Visual C++ runtime libraries via https://librewolf.net.
_FileReadError        = Error reading file for modification:

; Preparation
#SingleInstance Off
#NoEnv
EnvGet, LocalAppData, LocalAppData
FileEncoding, UTF-8-RAW
OnExit, Exit
FileGetVersion, PortableVersion, %A_ScriptFullPath%
PortableVersion := SubStr(PortableVersion, 1, -2)
SetWorkingDir, %A_Temp%
Menu, Tray, Tip, %_Title% %PortableVersion% [%ProgramPath%]
Menu, Tray, NoStandard
Menu, Tray, Add, Portable, About
Menu, Tray, Add, WinUpdater, About
Menu, Tray, Add, Exit, Exit
Menu, Tray, Default, Portable

About(ItemName) {
	Url = https://github.com/ltGuillaume/LibreWolf-%ItemName%
	Try Run, %Url%
	Catch {
		RegRead, DefBrowser, HKCR, .html
		RegRead, DefBrowser, HKCR, %DefBrowser%\Shell\Open\Command
		Run, % StrReplace(DefBrowser, "%1", Url)
		If ErrorLevel
		MsgBox, 48, %_Title%, %_NoDefaultBrowser%
	}
}

; Check for running LibreWolf-Portable processes
DetectHiddenWindows, On
SetTitleMatchMode 2
WinGet, Self, List, %A_ScriptName% ahk_exe %A_ScriptName%
Loop, %Self%
	If (Self%A_Index% != A_ScriptHwnd) {
		PortableRunning := True
;MsgBox, LibreWolf Portable is already running.`nSkipping preparation.
		Goto, Run
	}

; Check for updates (once a day) if LibreWolf-WinUpdater is found and no arguments were passed
WinUpdater := A_ScriptDir "\LibreWolf-WinUpdater"
If (!A_Args.Length() And FileExist(WinUpdater ".exe")) {
	If FileExist(WinUpdater ".ini")
		FileGetTime, LastUpdate, %WinUpdater%.ini
	If (!LastUpdate Or SubStr(LastUpdate, 1, 8) < SubStr(A_Now, 1, 8)) {
		Run, %WinUpdater%.exe /Portable
		Exit
	}
}

; Check path to LibreWolf and profile
If !FileExist(ExeFile) {
	MsgBox, 48, %_Title%, %_GetProgramPathError%
	Exit
}
If !FileExist(ProfilePath) {
	MsgBox, 52, %_Title%, %_GetProfilePathError%
	IfMsgBox No
		Exit
	IfMsgBox Yes
		FileCreateDir, %ProfilePath%
}

; Backup existing registry key
RegKey  := "HKCU\Software\LibreWolf"

PrepRegistry:
RegKeyFound := False
BackupKeyFound := False

Loop, Reg, %RegKey%, K
	RegKeyFound := True
If RegKeyFound {
	Loop, Reg, %RegKey%.pbak, K
		BackupKeyFound := True
	If BackupKeyFound {
		MsgBox, 54, %_Title%, %_BackupKeyFound%`n%RegKey%.pbak`n%_BackupFoundActions%
		IfMsgBox Cancel
			Exit
		IfMsgBox TryAgain
			Goto, PrepRegistry
	} Else
		RunWait, reg copy %RegKey% %RegKey%.pbak /s /f,, Hide
	RegDelete, %RegKey%
}

; Skip path adjustment if profile path hasn't changed since last run
If FileExist(ProfilePath "\.portable-lastpath") {	; Compatibility for older versions
	FileDelete, %ProfilePath%\.portable-lastpath
	Goto, ReplacePaths
}

IniRead, LastPlatformDir, %ProfilePath%\compatibility.ini, Compatibility, LastPlatformDir
If (LastPlatformDir = ProgramPath)
	Goto, Run
;MsgBox, Time to adjust the absolute profile path

; Adjust absolute profile folder paths to current path
ReplacePaths:
ProgramPathDS := StrReplace(ProgramPath, "\", "\\")
VarSetCapacity(ProgramPathUri, 300*2)
DllCall("shlwapi\UrlCreateFromPathW", "Str", ProgramPath, "Str", ProgramPathUri, "UInt*", 300, "UInt", 0x00040000)	// 0x00040000 = URL_ESCAPE_AS_UTF8
ProfilePathDS := StrReplace(ProfilePath, "\", "\\")
VarSetCapacity(ProfilePathUri, 300*2)
DllCall("shlwapi\UrlCreateFromPathW", "Str", ProfilePath, "Str", ProfilePathUri, "UInt*", 300, "UInt", 0x00040000)
OverridesPath := "user_pref(""autoadmin.global_config_url"", """ ProfilePathUri "/librewolf.overrides.cfg"");"

If FileExist(ProfilePath "\addonStartup.json.lz4") {
	FileInstall, dejsonlz4.exe, dejsonlz4.exe, 0
	FileInstall, jsonlz4.exe, jsonlz4.exe, 0
	FileCopy, %ProfilePath%\addonStartup.json.lz4, %A_WorkingDir%

	RunWait, dejsonlz4.exe addonStartup.json.lz4 addonStartup.json,, Hide
	If ReplacePaths("addonStartup.json") {
		RunWait, jsonlz4.exe addonStartup.json addonStartup.json.lz4,, Hide
		FileMove, addonStartup.json.lz4, %ProfilePath%, 1
	}
	FileDelete, addonStartup.json
}

If FileExist(ProfilePath "\extensions.json")
	ReplacePaths(ProfilePath "\extensions.json")

ReplacePaths(ProfilePath "\prefs.js")

ReplacePaths(FilePath) {
	Local File, FileOrg	; Assume-global mode

	If (!FileExist(FilePath) And FilePath = ProfilePath "\prefs.js") {
			FileAppend, %OverridesPath%, %FilePath%
		Return
	}

	FileRead, File, %FilePath%
	If Errorlevel {
		MsgBox, 48, %_Title%, %_FileReadError%`n%FilePath%
		Return
	}		
	FileOrg := File

	If (FilePath = ProfilePath "\prefs.js") {
		File := RegExReplace(File, "i)(, "")[^""]+?(\Qlibrewolf.overrides.cfg""\E)", "$1" ProfilePathUri "/$2", Count)
;MsgBox, librewolf.overrides.cfg path was replaced %Count% times
		If (Count = 0)
			File .= OverridesPath
	}
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\browser\\features\E)", ProgramPathDS "$1")
	File := RegExReplace(File, "i)file:\/\/\/[^""]+?(\Q/browser/features\E)", ProgramPathUri "$1")
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\extensions\E)", ProfilePathDS "$1")
	File := RegExReplace(File, "i)file:\/\/\/[^""]+?(\Q/extensions\E)", ProfilePathUri "$1")

	If (File = FileOrg)
		Return False
	Else {
		FileMove, %FilePath%, %FilePath%.pbak, 1
		FileAppend, %File%, %FilePath%
		Return True
	}
}

; Get CityHash for current instance
GetCityHash() {
	Global RegKey, CityHash
	Loop, Reg, %RegKey%\Firefox\Installer, K
		CityHash := A_LoopRegName
	If CityHash {
		SetTimer,, Delete
;MsgBox, CityHash = %CityHash%
	}
}

; Run LibreWolf
Run:
If !PortableRunning
	SetTimer, GetCityHash, 1000

If !LibreWolfRunning()
	Args := "--new-instance"
For i, Arg in A_Args
	Args .= " """ Arg """"

;MsgBox, %ExeFile% -profile "%ProfilePath%" %Args%
RunWait, %ExeFile% -profile "%ProfilePath%" %Args%,, UseErrorLevel

If ErrorLevel {
	Message := _ErrorStarting " " ErrorLevel
	If Errorlevel = -1073741515
		Message .= "`n`n" _MissingDLLs
	MsgBox, 48, %_Title%, %Message%
}

; Leave the rest to the already running LibreWolf-Portable instance
If PortableRunning
	Exit

; Wait for all LibreWolf processes of current user to be closed
WaitClose:
Sleep, 5000
While LibreWolfRunning()
	Goto, WaitClose

; Restore backed up registry key
RegDelete, %RegKey%
If RegKeyFound {
	RunWait, reg copy %RegKey%.pbak %RegKey% /s /f,, Hide
	RegDelete, %RegKey%.pbak
}

; Remove files with CityHash of this instance
If CityHash {
	FileDelete, %MozCommonPath%\*%CityHash%*.*
	FileRemoveDir, %MozCommonPath%\updates\%CityHash%, 1
}

; Remove AppData and Temp folders if empty
Folders := [ MozCommonPath, A_AppData "\LibreWolf\Extensions", A_AppData "\LibreWolf", LocalAppData "\LibreWolf", "mozilla-temp-files" ]
For i, Folder in Folders
	FileRemoveDir, %Folder%

; Clean-up
Exit:
If !PortableRunning
	FileDelete, *jsonlz4.exe


LibreWolfRunning() {
	Global ExeFile
	For Process in ComObjGet("winmgmts:").ExecQuery("Select ProcessId from Win32_Process where ExecutablePath=""" StrReplace(ExeFile, "\", "\\") """") {
		 Try {
			oUser := ComObject(0x400C, &User)	; VT_BYREF
			Process.GetOwner(oUser)
;MsgBox, % oUser[]
			If (oUser[] = A_UserName)
				Return True
		} Catch e
			Return True
	}
	Return False
}