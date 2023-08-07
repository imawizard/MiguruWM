DPI_AWARENESS_CONTEXT                      := 0
DPI_AWARENESS_CONTEXT_UNAWARE              := DPI_AWARENESS_CONTEXT - 1
DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         := DPI_AWARENESS_CONTEXT - 2
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    := DPI_AWARENESS_CONTEXT - 3
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 := DPI_AWARENESS_CONTEXT - 4
DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED    := DPI_AWARENESS_CONTEXT - 5

DPI_UNAWARE  := DPI_AWARENESS_CONTEXT_UNAWARE
DPI_SYSAWARE := DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
DPI_PMv1     := DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE
DPI_PMv2     := DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2

DPI_AWARENESS_INVALID           := -1
DPI_AWARENESS_UNAWARE           :=  0
DPI_AWARENESS_SYSTEM_AWARE      :=  1
DPI_AWARENESS_PER_MONITOR_AWARE :=  2

SetDpiAwareness(value) {
    return DllCall(
        "SetThreadDpiAwarenessContext",
        "UInt", value,
        "UInt",
    )
}

GetDpiAwareness() {
    return DllCall(
        "GetThreadDpiAwarenessContext",
        "UInt",
    )
}

RunDpiAware(fn) {
    old := SetDpiAwareness(DPI_PMv2)
    try {
        fn()
    } catch {
        throw
    } finally {
        SetDpiAwareness(old)
    }
}

DWMWA_NCRENDERING_ENABLED            := 1
DWMWA_NCRENDERING_POLICY             := 2
DWMWA_TRANSITIONS_FORCEDISABLED      := 3
DWMWA_ALLOW_NCPAINT                  := 4
DWMWA_CAPTION_BUTTON_BOUNDS          := 5
DWMWA_NONCLIENT_RTL_LAYOUT           := 6
DWMWA_FORCE_ICONIC_REPRESENTATION    := 7
DWMWA_FLIP3D_POLICY                  := 8
DWMWA_EXTENDED_FRAME_BOUNDS          := 9
DWMWA_HAS_ICONIC_BITMAP              := 10
DWMWA_DISALLOW_PEEK                  := 11
DWMWA_EXCLUDED_FROM_PEEK             := 12
DWMWA_CLOAK                          := 13
DWMWA_CLOAKED                        := 14
DWMWA_FREEZE_REPRESENTATION          := 15
DWMWA_PASSIVE_UPDATE_MODE            := 16
DWMWA_USE_HOSTBACKDROPBRUSH          := 17
DWMWA_USE_IMMERSIVE_DARK_MODE        := 20
DWMWA_WINDOW_CORNER_PREFERENCE       := 33
DWMWA_BORDER_COLOR                   := 34
DWMWA_CAPTION_COLOR                  := 35
DWMWA_TEXT_COLOR                     := 36
DWMWA_VISIBLE_FRAME_BORDER_THICKNESS := 37
DWMWA_SYSTEMBACKDROP_TYPE            := 38
DWMWA_LAS                            := 39

DWM_CLOAKED_APP       := 1
DWM_CLOAKED_SHELL     := 2
DWM_CLOAKED_INHERITED := 4

ExtendedFrameBounds(hwnd) {
    buf := Buffer(4 * 4)
    if DllCall(
        "dwmapi.dll\DwmGetWindowAttribute",
        "Ptr", hwnd,
        "UInt", DWMWA_EXTENDED_FRAME_BOUNDS,
        "Ptr", buf,
        "UInt", buf.Size,
        "UInt",
    ) {
        return { left: 0, top: 0, right: 0, bottom: 0 }
    }

    boundsLeft   := NumGet(buf,  0, "Int")
    boundsTop    := NumGet(buf,  4, "Int")
    boundsRight  := NumGet(buf,  8, "Int")
    boundsBottom := NumGet(buf, 12, "Int")

    WinGetPos(&left, &top, &width, &height, "ahk_id" hwnd)
    right := left + width
    bottom := top + height

    return {
        left:   boundsLeft - left,
        top:    boundsTop  - top,
        right:  right  - boundsRight,
        bottom: bottom - boundsBottom,
    }
}

IsWindowCloaked(hwnd) {
    buf := Buffer(A_PtrSize)
    return DllCall(
        "dwmapi.dll\DwmGetWindowAttribute",
        "Ptr", hwnd,
        "UInt", DWMWA_CLOAKED,
        "Ptr", buf,
        "UInt", buf.Size,
        "Int",
    )
        ? false
        : NumGet(buf, 0, "UInt") !== 0
}

WindowFromPoint(x, y) {
    return DllCall(
        "WindowFromPoint",
        "UInt64", (x & 0xffffffff) | (y << 32),
        "Ptr",
    )
}

SPI_GETBEEP                     := 0x0001
SPI_SETBEEP                     := 0x0002
SPI_GETMOUSE                    := 0x0003
SPI_SETMOUSE                    := 0x0004
SPI_GETBORDER                   := 0x0005
SPI_SETBORDER                   := 0x0006
SPI_GETKEYBOARDSPEED            := 0x000A
SPI_SETKEYBOARDSPEED            := 0x000B
SPI_ICONHORIZONTALSPACING       := 0x000D
SPI_GETSCREENSAVETIMEOUT        := 0x000E
SPI_SETSCREENSAVETIMEOUT        := 0x000F
SPI_GETSCREENSAVEACTIVE         := 0x0010
SPI_SETSCREENSAVEACTIVE         := 0x0011
SPI_SETDESKWALLPAPER            := 0x0014
SPI_SETDESKPATTERN              := 0x0015
SPI_GETKEYBOARDDELAY            := 0x0016
SPI_SETKEYBOARDDELAY            := 0x0017
SPI_ICONVERTICALSPACING         := 0x0018
SPI_GETICONTITLEWRAP            := 0x0019
SPI_SETICONTITLEWRAP            := 0x001A
SPI_GETMENUDROPALIGNMENT        := 0x001B
SPI_SETMENUDROPALIGNMENT        := 0x001C
SPI_SETDOUBLECLKWIDTH           := 0x001D
SPI_SETDOUBLECLKHEIGHT          := 0x001E
SPI_GETICONTITLELOGFONT         := 0x001F
SPI_SETDOUBLECLICKTIME          := 0x0020
SPI_SETMOUSEBUTTONSWAP          := 0x0021
SPI_SETICONTITLELOGFONT         := 0x0022
SPI_SETDRAGFULLWINDOWS          := 0x0025
SPI_GETDRAGFULLWINDOWS          := 0x0026
SPI_GETNONCLIENTMETRICS         := 0x0029
SPI_SETNONCLIENTMETRICS         := 0x002A
SPI_GETMINIMIZEDMETRICS         := 0x002B
SPI_SETMINIMIZEDMETRICS         := 0x002C
SPI_GETICONMETRICS              := 0x002D
SPI_SETICONMETRICS              := 0x002E
SPI_SETWORKAREA                 := 0x002F
SPI_GETWORKAREA                 := 0x0030
SPI_GETFILTERKEYS               := 0x0032
SPI_SETFILTERKEYS               := 0x0033
SPI_GETTOGGLEKEYS               := 0x0034
SPI_SETTOGGLEKEYS               := 0x0035
SPI_GETMOUSEKEYS                := 0x0036
SPI_SETMOUSEKEYS                := 0x0037
SPI_GETSHOWSOUNDS               := 0x0038
SPI_SETSHOWSOUNDS               := 0x0039
SPI_GETSTICKYKEYS               := 0x003A
SPI_SETSTICKYKEYS               := 0x003B
SPI_GETACCESSTIMEOUT            := 0x003C
SPI_SETACCESSTIMEOUT            := 0x003D
SPI_GETSERIALKEYS               := 0x003E
SPI_SETSERIALKEYS               := 0x003F
SPI_GETSOUNDSENTRY              := 0x0040
SPI_SETSOUNDSENTRY              := 0x0041
SPI_GETHIGHCONTRAST             := 0x0042
SPI_SETHIGHCONTRAST             := 0x0043
SPI_GETKEYBOARDPREF             := 0x0044
SPI_SETKEYBOARDPREF             := 0x0045
SPI_GETSCREENREADER             := 0x0046
SPI_SETSCREENREADER             := 0x0047
SPI_GETANIMATION                := 0x0048
SPI_SETANIMATION                := 0x0049
SPI_GETFONTSMOOTHING            := 0x004A
SPI_SETFONTSMOOTHING            := 0x004B
SPI_SETDRAGWIDTH                := 0x004C
SPI_SETDRAGHEIGHT               := 0x004D
SPI_GETLOWPOWERTIMEOUT          := 0x004F
SPI_GETPOWEROFFTIMEOUT          := 0x0050
SPI_SETLOWPOWERTIMEOUT          := 0x0051
SPI_SETPOWEROFFTIMEOUT          := 0x0052
SPI_GETLOWPOWERACTIVE           := 0x0053
SPI_GETPOWEROFFACTIVE           := 0x0054
SPI_SETLOWPOWERACTIVE           := 0x0055
SPI_SETPOWEROFFACTIVE           := 0x0056
SPI_SETCURSORS                  := 0x0057
SPI_SETICONS                    := 0x0058
SPI_GETDEFAULTINPUTLANG         := 0x0059
SPI_SETDEFAULTINPUTLANG         := 0x005A
SPI_SETLANGTOGGLE               := 0x005B
SPI_SETMOUSETRAILS              := 0x005D
SPI_GETMOUSETRAILS              := 0x005E
SPI_GETSNAPTODEFBUTTON          := 0x005F
SPI_SETSNAPTODEFBUTTON          := 0x0060
SPI_GETMOUSEHOVERWIDTH          := 0x0062
SPI_SETMOUSEHOVERWIDTH          := 0x0063
SPI_GETMOUSEHOVERHEIGHT         := 0x0064
SPI_SETMOUSEHOVERHEIGHT         := 0x0065
SPI_GETMOUSEHOVERTIME           := 0x0066
SPI_SETMOUSEHOVERTIME           := 0x0067
SPI_GETWHEELSCROLLLINES         := 0x0068
SPI_SETWHEELSCROLLLINES         := 0x0069
SPI_GETMENUSHOWDELAY            := 0x006A
SPI_SETMENUSHOWDELAY            := 0x006B
SPI_GETWHEELSCROLLCHARS         := 0x006C
SPI_SETWHEELSCROLLCHARS         := 0x006D
SPI_GETSHOWIMEUI                := 0x006E
SPI_SETSHOWIMEUI                := 0x006F
SPI_GETMOUSESPEED               := 0x0070
SPI_SETMOUSESPEED               := 0x0071
SPI_GETSCREENSAVERRUNNING       := 0x0072
SPI_GETDESKWALLPAPER            := 0x0073
SPI_GETAUDIODESCRIPTION         := 0x0074
SPI_SETAUDIODESCRIPTION         := 0x0075
SPI_GETSCREENSAVESECURE         := 0x0076
SPI_SETSCREENSAVESECURE         := 0x0077
SPI_GETHUNGAPPTIMEOUT           := 0x0078
SPI_SETHUNGAPPTIMEOUT           := 0x0079
SPI_GETWAITTOKILLTIMEOUT        := 0x007A
SPI_SETWAITTOKILLTIMEOUT        := 0x007B
SPI_GETWAITTOKILLSERVICETIMEOUT := 0x007C
SPI_SETWAITTOKILLSERVICETIMEOUT := 0x007D
SPI_GETMOUSEDOCKTHRESHOLD       := 0x007E
SPI_SETMOUSEDOCKTHRESHOLD       := 0x007F
SPI_GETPENDOCKTHRESHOLD         := 0x0080
SPI_SETPENDOCKTHRESHOLD         := 0x0081
SPI_GETWINARRANGING             := 0x0082
SPI_SETWINARRANGING             := 0x0083
SPI_GETMOUSEDRAGOUTTHRESHOLD    := 0x0084
SPI_SETMOUSEDRAGOUTTHRESHOLD    := 0x0085
SPI_GETPENDRAGOUTTHRESHOLD      := 0x0086
SPI_SETPENDRAGOUTTHRESHOLD      := 0x0087
SPI_GETMOUSESIDEMOVETHRESHOLD   := 0x0088
SPI_SETMOUSESIDEMOVETHRESHOLD   := 0x0089
SPI_GETPENSIDEMOVETHRESHOLD     := 0x008A
SPI_SETPENSIDEMOVETHRESHOLD     := 0x008B
SPI_GETDRAGFROMMAXIMIZE         := 0x008C
SPI_SETDRAGFROMMAXIMIZE         := 0x008D
SPI_GETSNAPSIZING               := 0x008E
SPI_SETSNAPSIZING               := 0x008F
SPI_GETDOCKMOVING               := 0x0090
SPI_SETDOCKMOVING               := 0x0091
SPI_GETLOGICALDPIOVERRIDE       := 0x009E
SPI_SETLOGICALDPIOVERRIDE       := 0x009F
SPI_GETACTIVEWINDOWTRACKING     := 0x1000
SPI_SETACTIVEWINDOWTRACKING     := 0x1001
SPI_GETMENUANIMATION            := 0x1002
SPI_SETMENUANIMATION            := 0x1003
SPI_GETCOMBOBOXANIMATION        := 0x1004
SPI_SETCOMBOBOXANIMATION        := 0x1005
SPI_GETLISTBOXSMOOTHSCROLLING   := 0x1006
SPI_SETLISTBOXSMOOTHSCROLLING   := 0x1007
SPI_GETGRADIENTCAPTIONS         := 0x1008
SPI_SETGRADIENTCAPTIONS         := 0x1009
SPI_GETKEYBOARDCUES             := 0x100A
SPI_GETMENUUNDERLINES           := 0x100A
SPI_SETKEYBOARDCUES             := 0x100B
SPI_SETMENUUNDERLINES           := 0x100B
SPI_GETACTIVEWNDTRKZORDER       := 0x100C
SPI_SETACTIVEWNDTRKZORDER       := 0x100D
SPI_GETHOTTRACKING              := 0x100E
SPI_SETHOTTRACKING              := 0x100F
SPI_GETMENUFADE                 := 0x1012
SPI_SETMENUFADE                 := 0x1013
SPI_GETSELECTIONFADE            := 0x1014
SPI_SETSELECTIONFADE            := 0x1015
SPI_GETTOOLTIPANIMATION         := 0x1016
SPI_SETTOOLTIPANIMATION         := 0x1017
SPI_GETTOOLTIPFADE              := 0x1018
SPI_SETTOOLTIPFADE              := 0x1019
SPI_GETCURSORSHADOW             := 0x101A
SPI_SETCURSORSHADOW             := 0x101B
SPI_GETMOUSESONAR               := 0x101C
SPI_SETMOUSESONAR               := 0x101D
SPI_GETMOUSECLICKLOCK           := 0x101E
SPI_SETMOUSECLICKLOCK           := 0x101F
SPI_GETMOUSEVANISH              := 0x1020
SPI_SETMOUSEVANISH              := 0x1021
SPI_GETFLATMENU                 := 0x1022
SPI_SETFLATMENU                 := 0x1023
SPI_GETDROPSHADOW               := 0x1024
SPI_SETDROPSHADOW               := 0x1025
SPI_GETBLOCKSENDINPUTRESETS     := 0x1026
SPI_SETBLOCKSENDINPUTRESETS     := 0x1027
SPI_GETUIEFFECTS                := 0x103E
SPI_SETUIEFFECTS                := 0x103F
SPI_GETDISABLEOVERLAPPEDCONTENT := 0x1040
SPI_SETDISABLEOVERLAPPEDCONTENT := 0x1041
SPI_GETCLIENTAREAANIMATION      := 0x1042
SPI_SETCLIENTAREAANIMATION      := 0x1043
SPI_GETCLEARTYPE                := 0x1048
SPI_SETCLEARTYPE                := 0x1049
SPI_GETTHREADLOCALINPUTSETTINGS := 0x104E
SPI_SETTHREADLOCALINPUTSETTINGS := 0x104F
SPI_GETSYSTEMLANGUAGEBAR        := 0x1050
SPI_SETSYSTEMLANGUAGEBAR        := 0x1051
SPI_GETFOREGROUNDLOCKTIMEOUT    := 0x2000
SPI_SETFOREGROUNDLOCKTIMEOUT    := 0x2001
SPI_GETACTIVEWNDTRKTIMEOUT      := 0x2002
SPI_SETACTIVEWNDTRKTIMEOUT      := 0x2003
SPI_GETFOREGROUNDFLASHCOUNT     := 0x2004
SPI_SETFOREGROUNDFLASHCOUNT     := 0x2005
SPI_GETCARETWIDTH               := 0x2006
SPI_SETCARETWIDTH               := 0x2007
SPI_GETMOUSECLICKLOCKTIME       := 0x2008
SPI_SETMOUSECLICKLOCKTIME       := 0x2009
SPI_GETFONTSMOOTHINGTYPE        := 0x200A
SPI_SETFONTSMOOTHINGTYPE        := 0x200B
SPI_GETFONTSMOOTHINGCONTRAST    := 0x200C
SPI_SETFONTSMOOTHINGCONTRAST    := 0x200D
SPI_GETFOCUSBORDERWIDTH         := 0x200E ; For when a control has focus, e.g. the button of a MessageBox.
SPI_SETFOCUSBORDERWIDTH         := 0x200F
SPI_GETFOCUSBORDERHEIGHT        := 0x2010
SPI_SETFOCUSBORDERHEIGHT        := 0x2011
SPI_GETFONTSMOOTHINGORIENTATION := 0x2012
SPI_SETFONTSMOOTHINGORIENTATION := 0x2013
SPI_GETMESSAGEDURATION          := 0x2016
SPI_SETMESSAGEDURATION          := 0x2017
SPI_GETCONTACTVISUALIZATION     := 0x2018
SPI_SETCONTACTVISUALIZATION     := 0x2019
SPI_GETGESTUREVISUALIZATION     := 0x201A
SPI_SETGESTUREVISUALIZATION     := 0x201B
SPI_GETMOUSEWHEELROUTING        := 0x201C
SPI_SETMOUSEWHEELROUTING        := 0x201D
SPI_GETPENVISUALIZATION         := 0x201E
SPI_SETPENVISUALIZATION         := 0x201F

SPIF_UPDATEINIFILE    := 1
SPIF_SENDCHANGE       := 2
SPIF_SENDWININICHANGE := 3

GetSpiInt(action, param := 0) {
    value := Buffer(4)
    DllCall(
        "SystemParametersInfo",
        "UInt", action,
        "UInt", param,
        "Ptr", value,
        "UInt", 0,
        "Int",
    )
    return NumGet(value, "Int")
}

SetSpiInt(action, value, param := 0, update := 0) {
    DllCall(
        "SystemParametersInfo",
        "UInt", action,
        "UInt", param,
        "Int", value,
        "UInt", update,
        "Int",
    )
}

class CircularList {
    __New() {
        this._first := ""
        this._count := 0
    }

    First => this._first
    Last  => this._first ? this._first.previous : ""
    Count => this._count
    Empty => this._count == 0

    Swap(a, b) {
        this._swapTiles(a, b)
    }

    _swapTiles(a, b) {
        if b.next == a {
            if a.next !== b {
                this._swapTiles(b, a)
                return
            } else if a == b {
                return
            }
        } else if a.next == b {
            a.previous.next := b
            b.next.previous := a

            a.next := b.next
            b.next := a

            b.previous := a.previous
            a.previous := b
        } else {
            a.previous.next := b
            b.previous.next := a

            a.next.previous := b
            b.next.previous := a

            tmp := a.next
            a.next := b.next
            b.next := tmp

            tmp := a.previous
            a.previous := b.previous
            b.previous := tmp
        }

        if this._first == a {
            this._first := b
        } else if this._first == b {
            this._first := a
        }
    }

    Append(data, sibling := this.Last) {
        node := { data: data }
        if this._first {
            this._prependTile(node, sibling.next)
        } else {
            node.previous := node
            node.next := node
            this._first := node
        }
        this._count++
        return node
    }

    Prepend(data, sibling := this._first) {
        node := { data: data }
        if this._first {
            this._prependTile(node, sibling)
            if sibling == this._first {
                this._first := node
            }
        } else {
            node.previous := node
            node.next := node
            this._first := node
        }
        this._count++
        return node
    }

    _prependTile(a, b) {
        a.next := b
        a.previous := b.previous
        b.previous.next := a
        b.previous := a
    }

    Drop(node) {
        if node == this._first {
            if node.next !== node {
                this._first := node.next
                this._unlinkTile(node)
            } else {
                this._first := ""
            }
        } else {
            this._unlinkTile(node)
        }
        return --this._count
    }

    _unlinkTile(node) {
        node.previous.next := node.next
        node.next.previous := node.previous
    }
}

class Timeouts {
    __New() {
        this.timers := Map()
    }

    Add(func, delay, tag := "") {
        if !func {
            return
        }

        entry := { func: func, tag: tag }
        timer := this._callback.Bind(this, entry)
        entry.timer := timer

        this.timers[entry] := entry
        SetTimer(timer, -delay)
    }

    _callback(entry) {
        this.timers.Delete(entry)
        entry.func.Call()
    }

    Replace(func, delay, tag := "") {
        dropped := this.Drop(tag)
        this.Add(func, delay, tag)
        return dropped
    }

    Drop(tag := "") {
        dropped := []
        for k, v in this.timers {
            if !tag || v.tag == tag {
                timer := v.timer
                SetTimer(timer, 0)
                dropped.Push(k)
            }
        }
        for k, v in dropped {
            this.timers.Delete(v)
        }
        return dropped.Length
    }

    Tags() {
        unique := {}
        for k, v in this.timers {
            unique[v.tag] := ""
        }
        tags := []
        for k, v in unique {
            tags.Push(k)
        }
        return tags
    }
}

STD_OUTPUT_HANDLE := -11
ENABLE_ECHO_INPUT := 0x0004

;; The logging levels can be set for a class, the auto-execute section or
;; everything unspecified, they are: warn, debug (default), info and trace.
;; Use the env variable AHK_LOG like below.
;;
;; Examples:
;;    ; Set logging for class MiguruWM to debug
;;    ; Set logging to warn for everything else
;;    AHK_LOG=miguruwm=debug
;;
;;    ; Set logging for class Workspace to warn
;;    ; Set logging for auto-execute section to debug
;;    ; Turn off logging for everything else
;;    AHK_LOG=off,auto-exec=debug,workspace=warn
;;
;;    ; Disable logging completely
;;    AHK_LOG=disable
class Logger {
    static Disabled := false
    static Labels := [
        "WARN",
        "DEBUG",
        "INFO",
        "TRACE",
    ]
    static Colors := [
        "1;31",
        "1;34",
        "1;38",
        "1;30",
    ]
    static NO_COLOR := EnvGet("NO_COLOR") !== ""
    static Levels := Map()
    static PrintModule := true

    static Init() {
        attached := DllCall(
            "AttachConsole",
            "UInt", -1,
            "Int",
        )

        if attached {
            handle := DllCall(
                "GetStdHandle",
                "UInt", STD_OUTPUT_HANDLE,
                "UInt",
            )
            mode := 0
            DllCall(
                "GetConsoleMode",
                "UInt", handle,
                "UInt*", &mode,
                "Int",
            )

            ;; If writing to stdout is not possible,
            if mode & ENABLE_ECHO_INPUT == 0 {
                con := DllCall("GetConsoleWindow", "Ptr")

                ;; and there is no cmd window associated,
                if DllCall("IsWindow", "Ptr", con, "Int") &&
                    !DllCall("IsWindowVisible", "Ptr", con, "Int") {

                    ;; then undo AttachConsole.
                    DllCall("FreeConsole", "Int")
                    attached := false
                } else {
                    Logger.NO_COLOR := true
                }
            }
        }

        opts := StrLower(EnvGet("AHK_LOG"))
        if (!attached && opts == "") || opts == "disable" {
            Logger.Disabled := true
            return
        }

        if !attached {
            ;; If AHK_LOG was set but there's no attached console.
            DllCall("AllocConsole", "Int")
        }

        for part in StrSplit("debug," opts, ",") {
            if !part {
                continue
            }
            parts := StrSplit(part, "=")
            module := ""
            level := parts[1]
            if !level {
                continue
            } else if parts.Length >= 2 {
                module := parts[1]
                level := parts[2]
            }
            if level !== "off" {
                for v, l in Logger.Labels {
                    if level == StrLower(l) {
                        Logger.Levels[module] := v
                    }
                }
            } else {
                Logger.Levels[module] := 0
            }
        }
    }

    static Log(level, fmt, args*) {
        if Logger.Disabled {
            return
        }

        err := ""
        loop {
            err := Error("", -(A_Index + 1))
        } until InStr(err.What, ".") || IsInteger(err.What)

        module := !IsInteger(err.What)
            ? StrSplit(err.What, ".")[1]
            : "auto-exec"
        key := StrLower(module)
        max := Logger.Levels[Logger.Levels.Has(key) ? key : ""]

        if level <= max {
            s := ""
            if fmt is Func {
                s := Format(fmt()*)
            } else {
                s := Format(fmt, args*)
            }
            t := FormatTime(, "HH:mm:ss")
            m := Logger.PrintModule && module
                ? module !== "auto-exec"
                    ? " " module
                    : ""
                : ""

            l := Logger.Labels[level]
            c := Logger.Colors[level]
            if c && !Logger.NO_COLOR {
                l := Chr(27) "[" c "m" l Chr(27) "[0m"
            }

            FileAppend(t "." A_MSec m " [" l "] " s "`n", "*")
        }
    }
}

Logger.Init()

trace(fmt, args*) {
    Logger.Log(4, fmt, args*)
}

info(fmt, args*) {
    Logger.Log(3, fmt, args*)
}

debug(fmt, args*) {
    Logger.Log(2, fmt, args*)
}

warn(fmt, args*) {
    Logger.Log(1, fmt, args*)
}

qsort(arr, fn := "asc") {
    buf := Buffer(arr.Length * 4)
    offset := 0
    loop arr.Length {
        NumPut("UInt", A_Index, buf, offset)
        offset += 4
    }

    w := ""
    if fn is Func {
        w := (a, b) => fn(arr[NumGet(a, "UInt")], arr[NumGet(b, "UInt")])
    } else if fn is String {
        switch StrLower(fn) {
        case "asc":
            w := (a, b) => arr[NumGet(a, "UInt")] - arr[NumGet(b, "UInt")]
        case "desc":
            w := (a, b) => arr[NumGet(b, "UInt")] - arr[NumGet(a, "UInt")]
        }
    }
    if !w {
        throw "second parameter is unrecognized"
    }

    callback := CallbackCreate(w)
    DllCall(
        "msvcrt.dll\qsort",
        "Ptr", buf,
        "UInt", arr.Length,
        "UInt", 4,
        "Ptr", callback,
        "Cdecl",
    )
    CallbackFree(callback)

    sorted := []
    sorted.Capacity := arr.Length
    offset := 0
    loop arr.Length {
        sorted.Push(arr[NumGet(buf, offset, "UInt")])
        offset += 4
    }
    return sorted
}

ObjMerge(v*) {
    res := {}
    for , v in v {
        for k, v in v.OwnProps() {
            res.%k% := Type(v) == "Object"
            ? ObjMerge(
                res.HasProp(k) && Type(res.%k%) == "Object"
                    ? res.%k%
                    : {},
                v,
            )
            : v
        }
    }
    return res
}

ObjClone(v) => ObjMerge({}, v)

class WindowError {
    __New(hwnd, err) {
        this.hwnd := hwnd
        this.cause := err
    }
}

StringifySL(self) {
    s := Stringify(self)
    s := StrReplace(s, "`n`t", ", ")
    s := StrReplace(s, "`n}", " }")
    s := StrReplace(s, "`n", "")
    s := StrReplace(s, "`t", "")
    s := StrReplace(s, "{, ", "{ ")
    s := StrReplace(s, ", }", " }")
    s := StrReplace(s, "[, ", "[")
    s := StrReplace(s, ", ]", "]")
    s := StrReplace(s, "(, ", "(")
    s := StrReplace(s, ", )", ")")
    s := StrReplace(s, " {", "= {")
    s := StrReplace(s, " [", "= [")
    return s
}

Stringify(self, visited := Map()) {
    if self is String {
        return '"' self '"'
    } else if self is Primitive {
        return String(self)
    } else if self is Func {
        return ""
    }

    if visited.Has((self)) {
        return Format("{}(0x{:x})", Type(self), ObjPtr(self))
    }

    visited[(self)] := true

    if visited.Count > 1 && self.HasMethod("ToString") {
        return self.ToString()
    } else if self is Array {
        if self.Length == 0 {
            return "[]"
        }
        s := "["
        for v in self {
            v := Stringify(v, visited)
            if v !== "" {
                s .= "`n" RegExReplace(v, "m)^", "`t")
            }
        }
        s .= "`n]"
        return s
    } else if self is Map {
        if self.Count == 0 {
            return "{ }"
        }
        s := "{"
        for k, v in self {
            v := Stringify(v, visited)
            if v == "" {
                continue
            } else if InStr(v, "`n") {
                s .= "`n`t[" k "]"
                s .= IsAlpha(SubStr(v, 1, 1)) ? " = " : " "
                s .= SubStr(RegExReplace(v, "m)^", "`t"), 2)
            } else {
                s .= "`n`t[" k "] = " v
            }
        }
        s .= "`n}"
        return s
    } else if self is Object {
        s := ""
        props := []

        for k in self.OwnProps() {
            if SubStr(k, 1, 1) !== "_" {
                props.Push(k)
            }
        }

        proto := self.Base
        while proto && proto !== IUnknown.Base.Prototype {
            for k in proto.OwnProps() {
                desc := proto.GetOwnPropDesc(k)
                if !desc.HasProp("Call") && SubStr(k, 1, 1) !== "_" {
                    props.Push(k)
                }
            }
            proto := proto.Base
        }

        if props.Length == 0 {
            return "{ }"
        }

        for prop in props {
            v := Stringify(self.%prop%, visited)
            if v == "" {
                continue
            } else if InStr(v, "`n") {
                s .= "`n`t" prop
                s .= IsAlpha(SubStr(v, 1, 1)) ? " = " : " "
                s .= SubStr(RegExReplace(v, "m)^", "`t"), 2)
            } else {
                s .= "`n`t" prop " = " v
            }
        }

        if Type(self) !== "Object" {
            return Type(self) "(" s "`n)"
        }
        return "{" s "`n}"
    } else {
        return "???"
    }
}

time(since := 0) {
    ticks := 0
    DllCall(
        "QueryPerformanceCounter",
        "Int64*", &ticks,
        "Int",
    )
    if since == 0 {
        Return ticks
    }
    freq := 0
    DllCall(
        "QueryPerformanceFrequency",
        "Int64*", &freq,
        "Int",
    )
    Return (ticks - since) * 1000 / freq
}

measure(cb, iterations := 1) {
    tc := time()
    i := 0
    while i < iterations {
        cb()
        i++
    }
    return time(tc)
}

RemoveWinDecoration(hwnd) {
    style := WinGetStyle("ahk_id" hwnd)
    WinSetStyle(style & ~WS_DLGFRAME, "ahk_id" hwnd)

    DllCall(
        "SetWindowPos",
        "Ptr", hwnd,
        "Ptr", HWND_TOP,
        "Int", 0,
        "Int", 0,
        "Int", 0,
        "Int", 0,
        "UInt", SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED,
        "Int",
    )
}

WinInfo(hwnd) {
    info := "W=" hwnd
    try {
        info := info " P=" WinGetProcessName("ahk_id" hwnd)
    }
    try {
        info := info " C=" WinGetClass("ahk_id" hwnd)
    }
    try {
        info := info " T=`"" WinGetTitle("ahk_id" hwnd) "`""
    }
    return info
}

GetNextWindowOfApp(hwnd, filter := (_) => true) {
    winclass := WinGetClass("ahk_id" hwnd)
    procname := WinGetProcessName("ahk_id" hwnd)
    windows := WinGetList("ahk_class" winclass)
    i := windows.Length + 1
    loop {
        if --i == 0 {
            break
        }
        window := windows[i]
        tmp := WinGetProcessName("ahk_id" window)
        if tmp == procname && filter(window) {
            return window
        }
    }
    return ""
}

CenterWindow(hwnd) {
    WinGetPos(, , &width, &height, "ahk_id" hwnd)
    info := Buffer(10 * 4)
    NumPut("UInt", 10 * 4, info) ; cbSize, rcMonitor, rcWork, dwFlags
    monitor := DllCall(
        "MonitorFromWindow",
        "Ptr", hwnd,
        "UInt", MONITOR_DEFAULTTONEAREST,
        "Ptr",
    )
    DllCall(
        "GetMonitorInfo",
        "Ptr", monitor,
        "Ptr", info,
        "Int",
    )
    rcWorkLeft   := NumGet(info, 5 * 4, "Int")
    rcWorkTop    := NumGet(info, 6 * 4, "Int")
    rcWorkRight  := NumGet(info, 7 * 4, "Int")
    rcWorkBottom := NumGet(info, 8 * 4, "Int")
    x := (rcWorkRight - width) / 2
    y := (rcWorkBottom - height) / 2
    WinMove(x, y, , , "ahk_id" hwnd)
}

ResizeWindow(hwnd, delta := 0) {
    WinGetPos(&x, &y, &width, &height, "ahk_id" hwnd)
    WinMove(
        x - delta,
        y - delta,
        width + delta * 2,
        height + delta * 2,
        "ahk_id" hwnd,
    )
}
