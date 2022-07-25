# MiguruWM (見苦窓経営笑)
**Work in Progress**

There already are various tiling window managers for Windows (see [Tiling WMs for Windows](#tiling-wms-for-windows)).
However, among the ones I gave a try, the stability or the behaviour in general
was not always what I was expecting.

So I'll be rolling my own...

## Caveats
For workspaces, Windows' virtual desktops are used (by means of their COM
interfaces, tested on Win10 Build 19044). Thus the integration is better and
e.g. windows can't get lost due to not being correctly restored, on the other
hand, Windows' virtual desktops can't be switched on per-monitor basis (at least on Win10).

## Tiling WMs for Windows
- [Amethyst Windows](https://github.com/glsorre/amethystwindows)
- [b3](https://github.com/ritschmaster/b3)
- [bug.n](https://github.com/fuhsjr00/bug.n)
- [dwm-win32](https://github.com/prabirshrestha/dwm-win32)
- [komorebi](https://github.com/LGUG2Z/komorebi)
- [nog](https://github.com/TimUntersberger/nog)
- [PyleWM](https://github.com/GGLucas/PyleWM)
- [win3wm](https://github.com/McYoloSwagHam/win3wm)
- [workspacer](https://github.com/workspacer/workspacer)

## Credits
### Virtual Desktops
- https://github.com/FuPeiJiang/VD.ahk/tree/b0a68a7
- https://github.com/MScholtes/VirtualDesktop
- https://github.com/Grabacr07/VirtualDesktop
- https://github.com/Ciantic/VirtualDesktopAccessor

### Ahk and COM
- https://autohotkey.com/boards/viewtopic.php?p=170967#p170967
- https://docs.microsoft.com/en-us/windows/win32/directshow/how-iunknown-works
- https://docs.microsoft.com/en-us/office/client-developer/outlook/mapi/implementing-iunknown-in-c-plus-plus

