; LibreWolf Portable - https://codeberg.org/librewolf/librewolf-portable
;@Ahk2Exe-SetFileVersion 1.10.0

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
, PortableExe   := A_IsCompiled ? A_ScriptFullPath : A_AhkPath
, ProfilePath   := A_ScriptDir "\Profiles\Default"
, UpdaterBase   := A_ScriptDir "\LibreWolf-WinUpdater"
, RegKey        := "HKCU\Software\Mozilla\LibreWolf"
, RegKeyFound   := False
, RegBackedUp   := False
, Shortcut      := A_AppData "\Microsoft\Windows\Start Menu\Programs\LibreWolf Private Browsing.lnk"

; Strings
Global _Title            := "LibreWolf Portable"
, _PortableHelp          := "Portable Help"
, _UpdaterHelp           := "WinUpdater Help"
, _Exit                  := "Exit"
, _ExitQuestion          := "Are you sure you want to close the launcher now? It's best to close all LibreWolf processes and then let this launcher clean up."
, _GetBuildError         := "Could not determine the build architecture (32/64-bit) of LibreWolf. The file librewolf.exe may be corrupt.`n`n{}"
, _Waiting               := "Waiting for all LibreWolf processes to close..."
, _NoDefaultBrowser      := "Could not open your default browser."
, _GetLibreWolfPathError := "Could not find the LibreWolf executable`n" LibreWolfExe
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
PreventShutdown()
Backup()
UpdateProfile()
RunLibreWolf()
WaitForClose()

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
	Menu, Tray, Add, %_PortableHelp%, Action
	Menu, Tray, Add, %_UpdaterHelp%, Action
	Menu, Tray, Add, %_Exit%, Action
	Menu, Tray, Default, %_PortableHelp%

	SplitPath, PortableExe,,,, BaseName
	IniFile := A_ScriptDir "\" BaseName ".ini"
	IniRead, HideTrayIcon, %IniFile%, Settings, HideTrayIcon, 0
	If (!HideTrayIcon)
		Menu, Tray, Icon
}

Action(ItemName) {
	; Tray items
	Switch ItemName
	{
		Case _Exit:
			MsgBox, 36, %_Title%, %_ExitQuestion%
			IfMsgBox, Yes
				ExitApp
			Return
		Default:
			Url := "https://codeberg.org/librewolf/librewolf-" StrReplace(ItemName, " Help") "#readme"
			Try Run, % Format("{:L}", Url)
			Catch {
				RegRead, DefBrowser, HKCR, .html
				RegRead, DefBrowser, HKCR, %DefBrowser%\Shell\Open\Command
				Run, % StrReplace(DefBrowser, "%1", Url)
				If (ErrorLevel)
					MsgBox, 48, %_Title%, %_NoDefaultBrowser%
			}
	}
}

CheckPaths() {
	If (UpdaterPid := UpdaterRunning()) {
		WinActivate, ahk_pid %UpdaterPid%
		Exit()
	} Else If (!FileExist(LibreWolfExe)) {
		If (FileExist(LibreWolfExe ".wubak"))
			CheckUpdates(True)
		Else
			Die(_GetLibreWolfPathError)
	}

	If (GetCurrentBuild() = "i686")
		SetRegView, 32
	Else
		SetRegView, 64

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

GetCurrentBuild() {
	; by RaptorX https://www.autohotkey.com/boards/viewtopic.php?t=132434
	Try {
		File := FileOpen(LibreWolfExe, "r")
		If (File) {
			File.Seek(0x3C, 0)	; MS-DOS header
			Offset := File.ReadUInt()
			File.Seek(Offset, 0)	; PE signature
			If (File.ReadUInt() = 0x4550) {	; "PE\0\0"
				File.Seek(Offset + 4, 0)	; Machine field from COFF header
				Machine := File.ReadUShort()
			}
			File.Close()

			Switch Machine {
				Case 0x8664:
					Return "x86_64"
				Case 0x014C:
					Return "i686"
				Case 0xAA64:
					Return "arm64"
			}
		}
		Die(_GetBuildError)
	} Catch e
		Die(_GetBuildError ": " e.Message)
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
CheckUpdates(Forced = False) {
	If (FileExist(UpdaterBase ".exe")) {
		If (FileExist(UpdaterBase ".ini"))
			FileGetTime, LastUpdate, %UpdaterBase%.ini
		If (Forced Or !LastUpdate Or SubStr(LastUpdate, 1, 8) < SubStr(A_Now, 1, 8)) {
			Run, %UpdaterBase%.exe /Portable -P "%ProfilePath%" %Args%
			Exit()
		}
	}
}

PreventShutdown() {
; https://www.autohotkey.com/docs/v1/lib/OnMessage.htm#shutdown
	DllCall("kernel32.dll\SetProcessShutdownParameters", "UInt", 0x1FF, "UInt", 0)	; 0x1FF := Application reserved last shutdown range
	OnMessage(0x0011, "BlockShutdown")
}

BlockShutdown(wParam, lParam) {
	DllCall("ShutdownBlockReasonCreate", "ptr", A_ScriptHwnd, "wstr", _Waiting)
	OnExit("AllowShutdown")
	Return False
}

AllowShutdown() {
	DllCall("ShutdownBlockReasonDestroy", "ptr", A_ScriptHwnd)
	OnExit(A_ThisFunc, 0)
}

Backup() {
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
			IfMsgBox Continue
				RegBackedUp := True
		} Else {
			RunWait, reg copy %RegKey% %RegKey%.pbak /s /f,, Hide
			If (!ErrorLevel)
				RegBackedUp := True
		}
		If (RegBackedUp)
			RegDelete, %RegKey%
	}

	FileMove, %Shortcut%, %Shortcut%.pbak
}

UpdateProfile() {
	; Adjust absolute profile folder paths to current path
	VarSetCapacity(LibreWolfPathUri, 300*2)
	DllCall("shlwapi\UrlCreateFromPathW", "Str", LibreWolfPath, "Str", LibreWolfPathUri, "UInt*", 300, "UInt", 0x00040000)	// 0x00040000 = URL_ESCAPE_AS_UTF8
	LibreWolfPathUri := StrReplace(LibreWolfPathUri, "///", "//")
	VarSetCapacity(ProfilePathUri, 300*2)
	DllCall("shlwapi\UrlCreateFromPathW", "Str", ProfilePath, "Str", ProfilePathUri, "UInt*", 300, "UInt", 0x00040000)
	ProfilePathUri := StrReplace(ProfilePathUri, "///", "//")
	OverridesPath := "user_pref(""autoadmin.global_config_url"", """ ProfilePathUri "/librewolf.overrides.cfg"");"
	JumpListPref := "browser.taskbar.lists.frequent.enabled"
	NoJumpList := "user_pref(""" JumpListPref """, false);"

	; Skip path adjustments if profile path hasn't changed since last run
	If (FileExist(ProfilePath "\prefs.js")) {
		FileRead, PrefsFile, %ProfilePath%\prefs.js

		; Prevent traces via jump list registry keys
		If (!InStr(PrefsFile, JumpListPref))
			FileAppend, %NoJumpList%`n, %ProfilePath%\prefs.js

		If (InStr(PrefsFile, OverridesPath)) {
;MsgBox, Profile paths don't need to be updated.
			Return
		}

		PrefsFile := ""
	}

	If (FileExist(ProfilePath "\addonStartup.json.lz4")) {
		FileInstall, dejsonlz4.exe, dejsonlz4.exe, 1
		FileInstall, jsonlz4.exe, jsonlz4.exe, 1
		FileDelete, addonStartup.json*
		FileCopy, %ProfilePath%\addonStartup.json.lz4, %A_WorkingDir%

		RunWait, dejsonlz4.exe addonStartup.json.lz4 addonStartup.json,, Hide
		If (!FileExist("addonStartup.json"))
			Die(_FileReadError, A_WorkingDir "\addonStartup.json")
		If (ReplacePaths("addonStartup.json", LibreWolfPathUri, ProfilePathUri)) {
			RunWait, jsonlz4.exe addonStartup.json addonStartup.json.lz4,, Hide
			FileMove, addonStartup.json.lz4, %ProfilePath%, 1
			If (ErrorLevel)
				Die(_FileWriteError, ProfilePath "addonStartup.json.lz4")
		}
		FileDelete, addonStartup.json*
	}

	If (FileExist(ProfilePath "\extensions.json"))
		ReplacePaths(ProfilePath "\extensions.json", LibreWolfPathUri, ProfilePathUri)

	If (FileExist(ProfilePath "\pkcs11.txt"))
		ReplacePaths(ProfilePath "\pkcs11.txt")

	ReplacePaths(ProfilePath "\prefs.js", LibreWolfPathUri, ProfilePathUri, OverridesPath, NoJumpList)

	FileDelete, %ProfilePath%\startupCache\*.*
}

ReplacePaths(FilePath, LibreWolfPathUri = False, ProfilePathUri = False, OverridesPath = False, NoJumpList = False) {
	If (FilePath = ProfilePath "\prefs.js" And !FileExist(FilePath)) {
		FileAppend, %OverridesPath%`n%NoJumpList%, %FilePath%
		If (ErrorLevel)
			Die(_FileWriteError, FilePath)
		Return
	}

	FileRead, File, %FilePath%
	If (ErrorLevel)
		Die(_FileReadError, FilePath)
	FileOrg := File

	If (FilePath = ProfilePath "\pkcs11.txt")
		File := RegExReplace(File, "i).:\\[^']+?'", DSlash(ProfilePath) "'")

	If (ProfilePathUri And FilePath = ProfilePath "\prefs.js") {
		File := RegExReplace(File, "i)(,\s*"")[^""]+?(\Qlibrewolf.overrides.cfg""\E)", "$1" ProfilePathUri "/$2", Count)
;MsgBox, librewolf.overrides.cfg path was replaced %Count% times
		If (Count = 0)
			File .= OverridesPath
	}
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\browser\\features\E)", DSlash(LibreWolfPath) "$1")
	File := RegExReplace(File, "i).:\\[^""]+?(\Q\\extensions\E)", DSlash(ProfilePath) "$1")
	If (LibreWolfPathUri)
		File := RegExReplace(File, "i)file:\/\/\/[^""]+?(\Q/browser/features\E)", LibreWolfPathUri "$1")
	If (ProfilePathUri)
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
;MsgBox, GetCityHash()
	Loop, Reg, %RegKey%\Installer, K
		CityHash := A_LoopRegName
	If (CityHash) {
		SetTimer,, Delete
;InputBox, CityHash, %_Title%, CityHash:,,,,,,,, %CityHash%
	}
}

WaitForClose() {
	While (Pid := LibreWolfRunning())
		Process, WaitClose, %Pid%
	CleanUp()
}

ThisLibreWolfRunning() {
	Return LibreWolfRunning(" and ExecutablePath=""" DSlash(LibreWolfExe) """")
}

LibreWolfRunning(Where := " and not ExecutablePath like ""%\\shims\\%""") {	; Exclude scoop shim
	Return ProcessRunning("Name=""librewolf.exe""" Where)
}

OtherLauncherRunning() {
	Return LauncherRunning("Name=""LibreWolf-Portable.exe"" and ExecutablePath<>""" DSlash(PortableExe) """")
}

ThisLauncherRunning() {
	Return LauncherRunning("ExecutablePath=""" DSlash(PortableExe) """")
}

LauncherRunning(Where) {
	Process, Exist	; Put launcher's process id into ErrorLevel
	Result := ProcessRunning("ProcessId!=" ErrorLevel " and " Where)
;MsgBox, LauncherRunning: %Result%
	Return %Result%
}

UpdaterRunning() {
	Return ProcessRunning("ExecutablePath=""" DSlash(UpdaterBase ".exe") """")
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
				Return Process.ProcessId
		} Catch e
			Return Process.ProcessId
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
	EnvGet, LocalAppData, LocalAppData

	; Wait until all launcher instances are closed before restoring backed up registry key
	While (RegBackedUp And Pid := OtherLauncherRunning())
		Process, WaitClose, %Pid%

	; Remove registry traces
	If (!OtherLauncherRunning()) {
	; Restore backed up registry key
;MsgBox, RegKey: %RegKey%`nRegKeyFound: %RegKeyFound%
		RegDelete, %RegKey%
		If (RegKeyFound) {
			RunWait, reg copy %RegKey%.pbak %RegKey% /s /f,, Hide
			If (!ErrorLevel)
				RegDelete, %RegKey%.pbak
		}
	}

	; Remove files and keys with CityHash of this LibreWolf instance
	If (CityHash) {
		FileDelete, %A_AppData%\Microsoft\Windows\Recent\%CityHash%*.*
		FileDelete, %LocalAppData%\Packages\Microsoft.Windows.Search*\LocalState\AppIconCache\100\%CityHash%*.*
		FileDelete, %MozCommonPath%\*%CityHash%*.*
		FileRemoveDir, %MozCommonPath%\updates\%CityHash%, 1

;		Recent  := A_AppData "\Microsoft\Windows\Recent"
;		Folders := [ "", "AutomaticDestinations", "CustomDestinations" ]	; TODO - These are random filenames, could search file contents for path and CityHash
;		For i, Folder in Folders
;			FileDelete, %Recent%\%Folder%\%CityHash%*.*

		CurVer := "HKCU\Software\Microsoft\Windows\CurrentVersion"
		Keys   := [ "Explorer\FeatureUsage\AppBadgeUpdated", "Explorer\FeatureUsage\AppLaunch", "Explorer\FeatureUsage\AppSwitched", "Explorer\FeatureUsage\ShowJumpView", "Search\JumplistData" ]
		For i, Key in Keys
		{
			RegDelete, %CurVer%\%Key%, %CityHash%
			RegDelete, %CurVer%\%Key%, %CityHash%;PrivateBrowsingAUMID
		}
	}

	RegDelete, HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Compatibility Assistant\Store, %PortableExe%
	RegDeleteNested("HKCU\Software\Classes\AppUserModelId")
	RegDeleteVals(RegKey "\DllPrefetchExperiment")
	RegDeleteVals(RegKey "\Launcher")
	RegDeleteVals(RegKey "\PreXULSkeletonUISettings")
	RegDeleteVals(RegKey ".pbak\DllPrefetchExperiment")
	RegDeleteVals(RegKey ".pbak\Launcher")
	RegDeleteVals(RegKey ".pbak\PreXULSkeletonUISettings")
	RegDeleteVals("HKCU\Software\Mozilla\Firefox\DllPrefetchExperiment")
	RegDeleteVals("HKCU\Software\Mozilla\Firefox\Launcher")
	RegDeleteVals("HKCU\Software\Mozilla\Firefox\PreXULSkeletonUISettings")

	Key := "HKCU\Software\Classes\CLSID"
	Loop, Reg, %Key%, K
	{
		RegRead, Data, %Key%\%A_LoopRegName%\InprocServer32
		If (InStr(Data, LibreWolfPath))
			RegDelete, %Key%\%A_LoopRegName%
	}

	Key := "HKCU\Software\Classes\AppUserModelId", Data := ""
	Loop, Reg, %Key%, K
	{
		RegRead, Data, %Key%\%A_LoopRegName%, IconUri
		If (InStr(Data, LibreWolfPath))
			RegDelete, %Key%\%A_LoopRegName%
	}

	; Remove ...shortcuts.ini
	RegRead, Group, HKCU\Software\Microsoft\Windows\CurrentVersion\Group Policy\GroupMembership, Group0
	If (!ErrorLevel) {
		Group := SubStr(Group, 1, InStr(Group, "-",, 0))
		FileDelete, %MozCommonPath%\LibreWolf_%Group%*_shortcuts.ini
	}

	; Remove AppData and Temp folders if empty
	Folders := [ MozCommonPath, A_AppData "\LibreWolf\Extensions", A_AppData "\LibreWolf\Profile Groups", A_AppData "\LibreWolf\Profiles", A_AppData "\LibreWolf", LocalAppData "\LibreWolf\Profiles", LocalAppData "\LibreWolf", "mozilla-temp-files" ]
	For i, Folder in Folders
		FileRemoveDir, %Folder%

	; Remove/restore Start menu shortcut
	FileDelete, %Shortcut%
	FileMove, %Shortcut%.pbak, %Shortcut%

	; Clean-up
	FileDelete, *jsonlz4.exe
	FileDelete, %UpdaterBase%.exe.wubak

	Exit()
}

RegDeleteNested(Key) {
	Loop, Reg, %Key%
	{
		CurKey := A_LoopRegName
		Loop, Reg, %CurKey%
			If (InStr(A_LoopRegName, LibreWolfExe))
				RegDelete, %Key%, %CurKey%
	}
}

RegDeleteVals(Key) {
	Loop, Reg, %Key%
		If (InStr(A_LoopRegName, LibreWolfExe))
			RegDelete, %Key%, %A_LoopRegName%
}

Exit() {
	ExitApp
}