<img src="LibreWolf-Portable.ico" align="right">

# LibreWolf Portable
by ltGuillaume: [Codeberg](https://codeberg.org/ltguillaume) | [GitHub](https://github.com/ltguillaume) | [Buy me a beer](https://coff.ee/ltguillaume) 🍺

This is the portable launcher that's bundled with LibreWolf. It allows for changing paths (so you can put it on removable storage) and will clean up remnants on the system after closing the browser.

- Multiple portable versions can be run simultaneously
- Portable versions can also be run together with an installed LibreWolf instance
- Passing command line arguments like an URL to a portable instance via `LibreWolf-Portable.exe` is only possible when that portable version is not yet running

## Getting started
- Download and extract [`librewolf-xxx.x.x-windows-x86_64-portable.zip`](https://librewolf.net/installation/windows/) (second blue button). It already contains a compiled version of the project hosted here.
- The portable version already includes [`LibreWolf-WinUpdater.exe`](https://codeberg.org/ltguillaume/librewolf-winupdater/releases) to automatically apply updates when you start `LibreWolf-Portable.exe` (checks for new versions once a day). If you wish to perform update checks manually instead, just rename WinUpdater to e.g. `LibreWolf-ManualUpdater.exe` and run it when needed.
- If you need a portable [`librewolf.overrides.cfg`](https://librewolf.net/docs/settings/), you can put it inside the profile folder (`Profiles\Default` is the standard location).  
LibreWolf Portable will _not_ use `%USERPROFILE%\.librewolf\librewolf.overrides.cfg`.

## Using multiple profiles
You can easily create batch files to quickly load LibreWolf with a specific profile. An example, using the profile name `Custom Profile #1`:
1. Create a new file called `LibreWolf Custom Profile #1.cmd` with the following contents:  
    ```
    @start /d "%~dp0" LibreWolf-Portable.exe -P "Custom Profile #1"
    ```
2. Double-click on the file you just saved. The profile will be created automatically.
- Change `Custom Profile #1` to whatever you like, as long as the used characters can be part of a folder name (e.g. no `:\/"`).
- Absolute paths can also be used, such as `-P "C:\Users\Username\LibreWolf\Profiles\Custom Profile #1"`.

## Hiding the launcher's tray icon
1. Create a new file called `LibreWolf-Portable.ini` with the following contents:
    ```
    [Settings]
    HideTrayIcon=1
    ```
2. Put it in the same folder as `LibreWolf-Portable.exe`

## Pinning LibreWolf to the taskbar
If you choose to pin a running LibreWolf window to the taskbar, you'll actually pin `librewolf.exe`, not `LibreWolf-Portable.exe`. As such, the next time you start LibreWolf via the pinned taskbar icon, you'll start a non-portable LibreWolf instance which will create a profile inside `%AppData%\LibreWolf\Profiles`. Registry traces and other files that the portable launcher would normally clean up will all stay on your system. While you can manually pin `LibreWolf-Portable.exe` to the taskbar to prevent this, it will cause a separate LibreWolf icon to show up once you run LibreWolf.

## Credits
* [LibreWolf](https://librewolf.net) by the [LibreWolf Community](https://librewolf.net/#core-contributors)
* [Icon](https://codeberg.org/librewolf/branding) by the [LibreWolf Community](https://librewolf.net/#core-contributors)
* The included [dejsonlz4](https://github.com/avih/dejsonlz4/) (BSD 2-Clause "Simplified" License) and jsonlz4 are the binaries from [PortableApps.com Firefox®](https://portableapps.com/apps/internet/firefox_portable) (GPLv2)
