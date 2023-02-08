# 「見苦窓経営笑」 - MiguruWM

**mwm.ahk** is an automatically tiling window manager for Windows 10 à la Amethyst/xmonad.

## Motivation

There already are a bunch of really nice tiling window managers for Windows – see [Other tiling WMs for Windows](#other-tiling-wms-for-windows) – so far I did not settle with any, though. So I'll be rolling my own...

The goal is a basic but hopefully stable window manager that should behave somewhere close to Amethyst/xmonad.

## Caveats

- Uses native virtual desktops as workspaces, *which can't be switched on per-monitor basis*, integrate however with:
    - [Task View](https://support.microsoft.com/en-us/windows/get-more-done-with-multitasking-in-windows-b4fa0333-98f8-ef43-e25c-06d4fb1d6960) and programs like [VirtualSpace](https://github.com/newlooper/VirtualSpace)
    - Settings like `VirtualDesktopAltTabFilter` and `VirtualDesktopTaskbarFilter` in `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`

- *No binary space partitioning, no moving in specific directions*, just the basics of xmonad:
    - Divide screen into master and secondary pane
    - Cycle through windows forwards/backwards
    - Layouts: tall, wide, fullscreen (aka monocle) and floating (i.e. no tiling)

- Tested on Win10 Build 19042-19045, *Windows 11 is probably not supported*
    - Particularly the GUIDs for the virtual desktop COM interfaces are missing/untested

## Installation

1. Download and install AutoHotkey v2
    - Either from their [Github Releases-page](https://github.com/Lexikos/AutoHotkey_L/tags)
    - Or through [Scoop](https://scoop.sh) with `scoop install autohotkey`
2. Clone this repository with `git clone https://github.com/imawizard/MiguruWM.git`
3. Run `autohotkey MiguruWM\mwm.ahk`

(See [lib/miguru/api.ahk](lib/miguru/api.ahk) and [lib/vd/vd.ahk](lib/vd/vd.ahk#L134) for api docs)

## How to use

The hotkeys are the same as in [Getting started with xmonad](https://xmonad.org/tour.html), in short:

#### General
Hotkey|Description
--|--
`Alt-j`|Focus next window
`Alt-k`|Focus previous window
`Shift-Alt-c`|Kill window
`Shift-Alt-Return`|Open a new Windows Terminal
`Alt-p`|Open search (`Win-s`)
`Alt-q`|Restart script
`Shift-Alt-q`|Exit script

#### Tiling
Hotkey|Description
--|--
`Alt-m`|Focus master window
`Alt-Return`|Swap window with master window
`Shift-Alt-j`|Swap window with next
`Shift-Alt-k`|Swap window with previous

#### Floating
Hotkey|Description
--|--
`Alt-Left click`|Float and move a window
`Alt-Right click`|Float and resize a window
`Alt-t`|Tile floating window

#### Workspaces
Hotkey|Description
--|--
`Alt-1~9`|Switch to workspace 1~9
`Shift-Alt-1~9`|Move window to workspace 1~9

#### Monitors
Hotkey|Description
--|--
`Alt-w,e,r`|Focus monitor 1~3
`Shift-Alt-w,e,r`|Move window to monitor 1~3

#### Layout
Hotkey|Description
--|--
`Alt-Space`|Next layout
`Shift-Alt-Space`|Reset current workspace's layout
`Alt-h`|Shrink master pane
`Alt-l`|Expand master pane
`Alt-,`|More master windows
`Alt-.`|Fewer master windows

## Other tiling WMs for Windows

- [Amethyst Windows](https://github.com/glsorre/amethystwindows)
- [b3](https://github.com/ritschmaster/b3)
- [bug.n](https://github.com/fuhsjr00/bug.n)
- [dwm-win32](https://github.com/prabirshrestha/dwm-win32)
- [FancyWM](https://github.com/FancyWM/fancywm)
- [GlazeWM](https://github.com/lars-berger/GlazeWM)
- [JigsawWM](https://github.com/klesh/JigsawWM)
- [komorebi](https://github.com/LGUG2Z/komorebi)
- [nog](https://github.com/TimUntersberger/nog)
- [PyleWM](https://github.com/GGLucas/PyleWM)
- [win3wm](https://github.com/McYoloSwagHam/win3wm)
- [Workspacer](https://github.com/workspacer/workspacer)

## Non-automatically tiling WMs and similiar tools for Windows

- [FancyZones](https://docs.microsoft.com/en-us/windows/powertoys/fancyzones)
- [GridMove](https://github.com/jgpaiva/GridMove)
- [grout](https://github.com/tarkah/grout)
- [RectangleWin](https://github.com/ahmetb/RectangleWin)
- [win-vind](https://github.com/pit-ray/win-vind)

<!-- vim: set tw=0 wrap ts=4 sw=4 et: -->
