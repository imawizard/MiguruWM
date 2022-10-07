# MiguruWM (見苦窓経営笑)
**Work in Progress**

There already are a bunch of really nice tiling window managers for Windows – see [Tiling WMs for Windows](#tiling-wms-for-windows) – so far I did not settle with any, though. So I'll be rolling my own...

The goal is a basic but hopefully stable automatically tiling window manager that should behave somewhere close to Amethyst/xmonad.

## Features/Caveats
- Screen is divided into a master and a second pane
    - layouts are tall, wide, fullscreen and no tiling (floating)
    - forward/backward cycling through windows
    - *no binary space partitioning, no moving in specific directions*
- Uses Win10's native virtual desktops
    - thus integrates with `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\VirtualDesktopAltTabFilter`, `VirtualDesktopTaskbarFilter` and task view or programs like [VirtualSpace](https://github.com/newlooper/VirtualSpace)
    - windows are not programmatically hidden when switching desktops, so they can't get lost due to not being correctly restored
    - *Windows' virtual desktops can't be switched on per-monitor basis*
- Bring your own hotkeys
    - *comes as an AHK library, so no settings window etc.*

## Installation
1. Download and install AutoHotkey v2 from [Github Releases](https://github.com/Lexikos/AutoHotkey_L/tags) or via [`scoop install autohotkey2`](https://scoop.sh)
2. Run `example.ahk` and toggle layout with `right alt + shift + space`
3. See [example.ahk](example.ahk) and [lib/miguru/api.ahk](lib/miguru/api.ahk) for more usage.

Tested on Win10 Build 19044. Win11 is probably not supported, particularly the GUIDs for the virtual desktop COM interfaces are missing/untested.

## Tiling WMs for Windows
- [Amethyst Windows](https://github.com/glsorre/amethystwindows)
- [b3](https://github.com/ritschmaster/b3)
- [bug.n](https://github.com/fuhsjr00/bug.n)
- [dwm-win32](https://github.com/prabirshrestha/dwm-win32)
- [GlazeWM](https://github.com/lars-berger/GlazeWM)
- [komorebi](https://github.com/LGUG2Z/komorebi)
- [nog](https://github.com/TimUntersberger/nog)
- [PyleWM](https://github.com/GGLucas/PyleWM)
- [win3wm](https://github.com/McYoloSwagHam/win3wm)
- [workspacer](https://github.com/workspacer/workspacer)

## Non-automatically tiling WMs and similiar tools for Windows
- [FancyZones](https://docs.microsoft.com/en-us/windows/powertoys/fancyzones)
- [GridMove](https://github.com/jgpaiva/GridMove)
- [grout](https://github.com/tarkah/grout)
- [RectangleWin](https://github.com/ahmetb/RectangleWin)
- [win-vind](https://github.com/pit-ray/win-vind)

## Credits
### Virtual Desktops
- https://github.com/FuPeiJiang/VD.ahk/tree/b0a68a7
- https://github.com/MScholtes/VirtualDesktop
- https://github.com/Grabacr07/VirtualDesktop
- https://github.com/Ciantic/VirtualDesktopAccessor
- https://github.com/tyranid/oleviewdotnet
### Ahk and COM
- https://autohotkey.com/boards/viewtopic.php?p=170967#p170967
- https://docs.microsoft.com/en-us/windows/win32/directshow/how-iunknown-works
- https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/implementing-iunknown-in-c-plus-plus
### DPI
- https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows
- https://autohotkey.com/boards/viewtopic.php?t=13810
- https://autohotkey.com/boards/viewtopic.php?t=102586

<!-- vim: set tw=0 wrap ts=4 sw=4 et: -->
