# 「見苦窓経営」笑

**Miguru** is an automatically tiling window manager for Windows 10 à la Amethyst/xmonad.

## Documentation

See [the wiki](https://github.com/imawizard/MiguruWM/wiki).

## Motivation

There already are a bunch of really nice tiling window managers for Windows – see [Other tiling WMs for Windows](https://github.com/imawizard/MiguruWM/wiki#other-tiling-wms-for-windows) – so far I did not settle with any, though. So I'll be rolling my own...

The goal is a basic but hopefully stable window manager that should behave somewhere close to Amethyst/xmonad.

## Caveats

- Uses native virtual desktops as workspaces, *which can't be switched on per-monitor basis*, integrate however with:
    - [Windows' Task View](https://support.microsoft.com/en-us/windows/get-more-done-with-multitasking-in-windows-b4fa0333-98f8-ef43-e25c-06d4fb1d6960) and programs like [VirtualSpace](https://github.com/newlooper/VirtualSpace)
    - Settings like `VirtualDesktopAltTabFilter` and `VirtualDesktopTaskbarFilter` in `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`

- *No binary space partitioning, no moving in specific directions*, just the basics of xmonad:
    - Divide screen into master and secondary pane
    - Cycle through windows forwards/backwards
    - Layouts: tall, wide, fullscreen (aka monocle) and floating (i.e. no tiling)

- Tested on Win10 Build 19042-19045, *Windows 11 is currently not supported*
    - Particularly the GUIDs for the virtual desktop COM interfaces are missing/untested

<!-- vim: set tw=0 wrap ts=4 sw=4 et: -->
