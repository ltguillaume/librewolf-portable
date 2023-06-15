<img src="LibreWolf-Portable.ico" align="right">

# LibreWolf Portable
by ltGuillaume: [Codeberg](https://codeberg.org/ltGuillaume) | [GitHub](https://github.com/ltGuillaume) | [Buy me a beer](https://buymeacoff.ee/ltGuillaume) 🍺

This is the portable launcher that's bundled with LibreWolf. It allows for changing paths (so you can put it on removable storage) and will clean up remnants on the system after closing the browser.

- Multiple portable versions can be run simultaneously
- Portable versions can also be run together with an installed LibreWolf instance
- Passing command line arguments like an URL to a portable instance via `LibreWolf-Portable.exe` is only possible when that portable version is not yet running

## Getting started
- Download and extract [`librewolf-xx.x.en-US.xxx.portable.zip`](https://gitlab.com/librewolf-community/browser/bsys6/-/releases). It already contains a compiled version of the project hosted here.
- Optionally, put [`LibreWolf-WinUpdater.exe`](https://codeberg.org/ltGuillaume/LibreWolf-WinUpdater/releases) in the same folder to automatically apply updates when starting `LibreWolf-Portable.exe` (checks for new versions once a day).
- If you need a portable [`librewolf.overrides.cfg`](https://librewolf.net/docs/settings/#where-do-i-find-my-librewolfoverridescfg), you can put it inside the profile folder `Profiles\Default`.  
LibreWolf Portable will _not_ use `%USERPROFILE%\.librewolf\librewolf.overrides.cfg`.

## Multiple profiles
You can create batch files to quickly load LibreWolf with a specific profile. An example, using the profile name `Custom Profile #1`:
1. Create a new file called `LibreWolf Custom Profile #1.cmd` with the following contents:
    ```
    @start /d "%~dp0" LibreWolf-Portable.exe -P "Custom Profile #1"
    ```
2. Double-click on the file you just saved. The profile will be created.
- Change `Custom Profile #1` to whatever you like, as long as the used characters can be part of a filename.
- Absolute paths can also be used, such as `-P "C:\Users\Username\LibreWolf\Profiles\Profile1"`.

## Credits
* [LibreWolf](https://librewolf.net) by [ohfp](https://gitlab.com/ohfp), [stanzabird](https://stanzabird.nl), [fxbrit](https://gitlab.com/fxbrit), [maltejur](https://gitlab.com/maltejur), [bgstack15](https://bgstack15.wordpress.com) et al.
* Icon by the [LibreWolf Community](https://gitlab.com/librewolf-community/branding/-/tree/master/icon)
* The included [dejsonlz4](https://github.com/avih/dejsonlz4/) (BSD 2-Clause "Simplified" License) and jsonlz4 are the binaries from [PortableApps.com Firefox®](https://portableapps.com/apps/internet/firefox_portable) (GPLv2)
