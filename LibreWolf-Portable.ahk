; LibreWolf Portable - https://codeberg.org/ltguillaume/librewolf-portable
;@Ahk2Exe-SetFileVersion 1.6.4

;@Ahk2Exe-Base Unicode 32*
;@Ahk2Exe-SetCompanyName LibreWolf Community
;@Ahk2Exe-SetDescription LibreWolf Portable
;@Ahk2Exe-SetMainIcon LibreWolf-Portable.ico
;@Ahk2Exe-SetOrigFilename LibreWolf-Portable.exe
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,160`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

#NoEnv
#NoTrayIcon
#Persistent
#SingleInstance Off

Global Args     := ""
, CityHash      := False
, LibreWolfPath := A_ScriptDir "\LibreWolf"
, LibreWolfExe  := LibreWolfPath "\librewolf.exe"
, MozCommonPath := A_AppDataCommon "\Mozilla-1de4eec8-1241-4177-a864-e594e8d1fb38"
, ProfilePath   := A_ScriptDir "\Profiles\Default"
, UpdaterBase   := A_ScriptDir "\LibreWolf-WinUpdater"
, RegKey        := "HKCU\Software\LibreWolf"
, RegKeyFound   := False
, RegBackedUp   := False

; Strings
Global _Title            := "LibreWolf Portable"
, _GetBuildError         := "Could not determine the build architecture (32/64-bit) of LibreWolf. The file librewolf.exe may be corrupt.`n`n{}"
, _Waiting               := "Waiting for all LibreWolf processes to close..."
, _NoDefaultBrowser      := "Could not open your default browser."
, _GetLibreWolfPathError := "Could not find the path to LibreWolf:`n" LibreWolfPath
, _CreateProfileDirError := "The profile folder does not exist yet and the automatic creation of the folder failed. Check if your Windows user has write permissions to the folder " A_ScriptDir
, _BackupKeyFound        := "A backup registry key has been found:"
, _BackupFoundActions    := "This means LibreWolf Portable has probably not been closed correctly. Continue to restore the found backup key after running, or remove the backup key yourself and press Retry to back up the current key."
, _ErrorStarting         := "LibreWolf could not be started. Exit code:"
, _MissingDLLs           := "You probably don't have msvcp140.dll and vcruntime140.dll present on your system. Put these files in the folder " LibreWolfPath ",`nor install the Visual C++ runtime libraries via https://librewolf.net."
, _FileReadError         := "Error reading file for modification:`n{}"
, _FileWriteError        := "Error writing to file:`n{}`n`nClose all LibreWolf processes and check if your Windows user has write permissions to the profile folder " ProfilePath

Init()
CheckPaths()
CheckArgs()
If (ThisLauncherRunning()) {
	UpdateProfile()	; Still needed for -P(rofile) ...
	RunLibreWolf()
	Exit()
}
CheckUpdates()
RegBackup()
UpdateProfile()
RunLibreWolf()
SetTimer, WaitForClose, 2000

DSlash(Path) {
	Return StrReplace(Path, "\", "\\")
}

Init() {
	FileEncoding, UTF-8-RAW
	FileGetVersion, PortableVersion, %A_ScriptFullPath%
	PortableVersion := SubStr(PortableVersion, 1, -2)
	SetWorkingDir, %A_Temp%
	Menu, Tray, Tip, %_Title% %PortableVersion% [%A_ScriptDir%]`n%_Waiting%
	Menu, Tray, NoStandard
	Menu, Tray, Add, Portable, About
	Menu, Tray, Add, WinUpdater, About
	Menu, Tray, Add, Exit, Exit
	Menu, Tray, Default, Portable

	SplitPath, A_ScriptFullPath,,,, BaseName
	IniFile := A_ScriptDir "\" BaseName ".ini"
	IniRead, HideTrayIcon, %IniFile%, Settings, HideTrayIcon, 0
	If (!HideTrayIcon)
		Menu, Tray, Icon
}

About(ItemName) {
	Url := "https://codeberg.org/ltguillaume/librewolf-" ItemName
	Try Run, %Url%
	Catch {
		RegRead, DefBrowser, HKCR, .html
		RegRead, DefBrowser, HKCR, %DefBrowser%\Shell\Open\Command
		Run, % StrReplace(DefBrowser, "%1", Url)
		If (ErrorLevel)
			MsgBox, 48, %_Title%, %_NoDefaultBrowser%
	}
}

CheckPaths() {
	If (!FileExist(LibreWolfExe))
		Die(_GetLibreWolfPathError)

	Call := DllCall("GetBinaryTypeW", "Str", "\\?\" LibreWolfExe, "UInt *", Build)
	If (Call And Build = 6)
		SetRegView, 64
	Else If (Call And Build = 0)
		SetRegView, 32
	Else
		Die(_GetBuildError, "Call = " Call ", Build = " Build)

	; Check for profile path argument
	If (A_Args.Length() > 1)
		For i, Arg in A_Args
			If (A_Args[i+1] And (Arg = "-P" Or Arg = "-Profile")) {
				Profile := A_Args[i+1]
				SplitPath, Profile,,,,, ProfileDrive	; Absolute path
				If (!ProfileDrive)
					Profile := RegExReplace(Profile, "i)^Profiles\\")	; Fix custom profile location
				ProfilePath := (ProfileDrive ? "" : A_ScriptDir "\Profiles\") Profile
				A_Args.RemoveAt(i, 2)
			}

	If (!FileExist(ProfilePath)) {
		FileCreateDir, %ProfilePath%
		If (ErrorLevel)
			Die(_CreateProfileDirError)
	}
}

CheckArgs() {
	For i, Arg in A_Args
	{
		If (InStr(Arg, A_Space))
			Arg := """" Arg """"
		Args .= " " Arg
	}
}

; Check for updates (once a day) if LibreWolf-WinUpdater is found
CheckUpdates() {
	If (FileExist(UpdaterBase ".exe")) {
		If (FileExist(UpdaterBase ".ini"))
			FileGetTime, LastUpdate, %UpdaterBase%.ini
		If (!LastUpdate Or SubStr(LastUpdate, 1, 8) < SubStr(A_Now, 1, 8)) {
			Run, %UpdaterBase%.exe /Portable -P "%ProfilePath%" %Args%
			Exit()
		}
	}
}

RegBackup() {
	PrepRegistry:
	BackupKeyFound := False

	Loop, Reg, %RegKey%, K
		RegKeyFound := True
;MsgBox, RegKeyFound: %RegKeyFound%
	If (RegKeyFound) {
		Loop, Reg, %RegKey%.pbak, K
			BackupKeyFound := True
;MsgBox, BackupFound: %BackupKeyFound%
		If (BackupKeyFound) {
			If (OtherLauncherRunning())
				Return
			MsgBox, 54, %_Title%, %_BackupKeyFound%`n%RegKey%.pbak`n%_BackupFoundActions%
			IfMsgBox Cancel
				Exit()
			IfMsgBox TryAgain
				Goto, PrepRegistry
		} Else {
			RunWait, reg copy %RegKey% %RegKey%.pbak /s /f,, Hide
			RegBackedUp := True
		}
		RegDelete, %RegKey%
	}
}

UpdateProfile() {
	; Adjust absolute profile folder paths to current path
	VarSetCapacity(LibreWolfPathUri, 300*2)
	DllCall("shlwapi\UrlCreateFromPathW", "Str", LibreWolfPath, "Str", LibreWolfPathUri, "UInt*", 300, "UInt", 0x00040000)	// 0x00040000 = URL_ESCAPE_AS_UTF8
	VarSetCapacity(ProfilePathUri, 300*2)
	DllCall("shlwapi\UrlCreateFromPathW", "Str", ProfilePath, "Str", ProfilePathUri, "UInt*", 300, "UInt", 0x00040000)
	OverridesPath := "user_pref(""autoadmin.global_config_url"", """ ProfilePathUri "/librewolf.overrides.cfg"");"

	; Skip path adjustments if profile path hasn't changed since last run
	If (FileExist(ProfilePath "\prefs.js")) {
		FileRead, PrefsFile, %ProfilePath%\prefs.js
		If (InStr(PrefsFile, OverridesPath)) {
;MsgBox, Profile doesn't need to be updated.
			Return
		}
	}

	If (FileExist(ProfilePath "\addonStartup.json.lz4")) {
		FileInstall, dejsonlz4.exe, dejsonlz4.exe, 0
		FileInstall, jsonlz4.exe, jsonlz4.exe, 0
		FileDelete, %A_WorkingDir%\addonStartup.json.lz4
		FileCopy, %ProfilePath%\addonStartup.json.lz4, %A_WorkingDir%

		RunWait, dejsonlz4.exe addonStartup.json.lz4 addonStartup.json,, Hide
		If (!FileExist("addonStartup.json"))
			Die(_FileReadError, A_WorkingDir "addonStartup.json")
		If (ReplacePaths("addonStartup.json", LibreWolfPathUri, ProfilePathUri)) {
			RunWait, jsonlz4.exe addonStartup.json addonStartup.json.lz4,, Hide
			FileMove, addonStartup.json.lz4, %ProfilePath%, 1
			If (ErrorLevel)
				Die(_FileWriteError, ProfilePath "addonStartup.json.lz4")
		}
		FileDelete, addonStartup.json
	}

	If (FileExist(ProfilePath "\extensions.json"))
		ReplacePaths(ProfilePath "\extensions.json", LibreWolfPathUri, ProfilePathUri)

	ReplacePaths(ProfilePath "\prefs.js", LibreWolfPathUri, ProfilePathUri, OverridesPath)
}

ReplacePaths(FilePath, LibreWolfPathUri, ProfilePathUri, OverridesPath = False) {
	If (FilePath = ProfilePath "\prefs.js" And !FileExist(FilePath)) {
		FileAppend, %OverridesPath%, %FilePath%
		If (ErrorLevel)
			Die(_FileWriteError, FilePath)
		Return
	}

	FileRead, File, %FilePath%
	If (ErrorLevel)
		Die(_FileReadError, FilePath)
	FileOrg := File

	If (FilePath = ProfilePath "\prefs.js") {
		File := RegExReplace(File, "i)(,\s*"")[^""]+?(\Qlibrewolf.overrides.cfg""\E)", "$1" ProfilePathUri "/$2", Count)
;MsgBox, librewolf.overrides.cfg path was replaced %Count% times
		If (Count = 0)
			File .= OverridesPath
	}
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\browser\\features\E)", DSlash(LibreWolfPath) "$1")
	File := RegExReplace(File, "i)file:\/\/\/[^""]+?(\Q/browser/features\E)", LibreWolfPathUri "$1")
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\extensions\E)", DSlash(ProfilePath) "$1")
	File := RegExReplace(File, "i)file:\/\/\/[^""]+?(\Q/extensions\E)", ProfilePathUri "$1")

	If (File = FileOrg)
		Return False
	Else {
		FileMove, %FilePath%, %FilePath%.pbak, 1
		If (ErrorLevel)
			Die(_FileWriteError, FilePath ".pbak")
		FileAppend, %File%, %FilePath%
		If (ErrorLevel)
			Die(_FileWriteError, FilePath)
		Return True
	}
}

RunLibreWolf() {
	If (!ThisLauncherRunning)
		SetTimer, GetCityHash, 1000

	If (LibreWolfRunning() And !ThisLibreWolfRunning())
		Args := "--new-instance " Args

;MsgBox, %LibreWolfExe% -profile "%ProfilePath%" %Args%
	RunWait, %LibreWolfExe% -Profile "%ProfilePath%" %Args%,, UseErrorLevel

	If (ErrorLevel) {
		Message := _ErrorStarting " " ErrorLevel
		If (ErrorLevel = -1073741515)
			Message .= "`n`n" _MissingDLLs
		MsgBox, 48, %_Title%, %Message%
	}
}

GetCityHash() {
	Loop, Reg, %RegKey%\Firefox\Installer, K
		CityHash := A_LoopRegName
	If (CityHash) {
		SetTimer,, Delete
;MsgBox, CityHash = %CityHash%
	}
}

WaitForClose() {
	If (LibreWolfRunning())
		Return
	SetTimer,, Delete
	SetTimer, CleanUp, 2000
}

ThisLibreWolfRunning() {
	Return LibreWolfRunning(" and ExecutablePath=""" DSlash(LibreWolfExe) """")
}

LibreWolfRunning(Where := "") {
	Return ProcessRunning("Name=""librewolf.exe""" Where)
}

OtherLauncherRunning() {
	Return LauncherRunning("Name=""LibreWolf-Portable.exe"" and ExecutablePath<>""" DSlash(A_ScriptFullPath) """")
}

ThisLauncherRunning() {
	Return LauncherRunning("ExecutablePath=""" DSlash(A_ScriptFullPath) """")
}

LauncherRunning(Where) {
	Process, Exist	; Put launcher's process id into ErrorLevel
	Result := ProcessRunning("ProcessId!=" ErrorLevel " and " Where)
;MsgBox, LauncherRunning: %Result%
	Return %Result%
}

ProcessRunning(Where := "") {
;MsgBox, ProcessRunning Where:`n%Where%
	Query := "Select ProcessId from Win32_Process where " Where
	For Process in ComObjGet("winmgmts:").ExecQuery(Query) {
		 Try {
			VarSetCapacity(User, 64)	; Request memory capacity, otherwise the Where variable got filled with random data (specifically "lf\Firefox\Installer")
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

Die(Error, Var := False) {
		If (Var)
			Error := StrReplace(Error, "{}", Var)
		MsgBox, 48, %_Title%, %Error%
		CleanUp()
}

CleanUp() {
	; Wait until all launcher instances are closed before restoring backed up registry key
	If (RegBackedUp And OtherLauncherRunning())
		Return

	SetTimer, CleanUp, Delete

	; Remove files with CityHash of this LibreWolf instance
	If (CityHash) {
		FileDelete, %MozCommonPath%\*%CityHash%*.*
		FileRemoveDir, %MozCommonPath%\updates\%CityHash%, 1
	}

	If (OtherLauncherRunning())
		Exit()

	; Restore backed up registry key
;MsgBox, RegKey: %RegKey%`nRegKeyFound: %RegKeyFound%
	RegDelete, %RegKey%
	If (RegKeyFound) {
		RunWait, reg copy %RegKey%.pbak %RegKey% /s /f,, Hide
		If (!ErrorLevel)
			RegDelete, %RegKey%.pbak
	}

	; Remove AppData and Temp folders if empty
	EnvGet, LocalAppData, LocalAppData
	Folders := [ MozCommonPath, A_AppData "\LibreWolf\Extensions", A_AppData "\LibreWolf", LocalAppData "\LibreWolf", "mozilla-temp-files" ]
	For i, Folder in Folders
		FileRemoveDir, %Folder%

	; Remove Start menu shortcut
	FileDelete, %A_AppData%\Microsoft\Windows\Start Menu\Programs\{-brand-shortcut-name} Private Browsing.lnk
	FileDelete, %A_AppData%\Microsoft\Windows\Start Menu\Programs\LibreWolf Private Browsing.lnk

	; Clean-up
	FileDelete, *jsonlz4.exe
	FileDelete, %UpdaterBase%.exe.pbak

	Exit()
}

Exit() {
	ExitApp
}