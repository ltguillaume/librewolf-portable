<img src="LibreWolf-Portable.ico" align="right">

# LibreWolf Portable
by ltGuillaume: [Codeberg](https://codeberg.org/ltGuillaume) | [GitHub](https://github.com/ltGuillaume) | [Buy me a beer](https://buymeacoff.ee/ltGuillaume) 🍺

This is the portable launcher that's bundled with LibreWolf. It allows for changing paths (so you can put it on removable storage) and will clean up remnants on the system after closing the browser. The portable version and an installed instance of LibreWolf can be run simultaneously.

## Getting started
- Download and extract [`librewolf-xx.x.en-US.win64.portable.zip`](https://gitlab.com/librewolf-community/browser/windows/-/releases). It already contains a compiled version of the project hosted here.
- Optionally, put [`LibreWolf-WinUpdater.exe`](https://codeberg.org/ltGuillaume/LibreWolf-WinUpdater/releases) in the same folder to automatically apply updates when starting `LibreWolf-Portable.exe` (checks for new versions once a day).
- If you need a portable [`librewolf.overrides.cfg`](https://librewolf.net/docs/settings/#where-do-i-find-my-librewolfoverridescfg), you can put it inside the profile folder `Profiles\Default`.  
LibreWolf Portable will _not_ use `%USERPROFILE%\.librewolf\librewolf.overrides.cfg`.

## Credits
* [LibreWolf](https://librewolf.net) by [ohfp](https://gitlab.com/ohfp), [stanzabird](https://stanzabird.nl), [fxbrit](https://gitlab.com/fxbrit), [maltejur](https://gitlab.com/maltejur), [bgstack15](https://bgstack15.wordpress.com) et al.
* Icon by the [LibreWolf Community](https://gitlab.com/librewolf-community/branding/-/tree/master/icon)
* The included [dejsonlz4](https://github.com/avih/dejsonlz4/) (BSD 2-Clause "Simplified" License) and jsonlz4 are the binaries from [PortableApps.com Firefox®](https://portableapps.com/apps/internet/firefox_portable) (GPLv2)
