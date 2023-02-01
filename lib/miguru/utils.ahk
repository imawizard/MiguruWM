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

class CircularList {
    __New() {
        this._first := ""
        this._count := 0
    }

    First      => this._first
    Last       => this._first ? this._first.previous : ""
    Count      => this._count
    Empty      => this._count == 0

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

    Append(data, sibling := this._first) {
        if sibling {
            return this.Prepend(data, sibling.next)
        } else {
            return this.Prepend(data)
        }
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

; The logging levels can be set for a class, the auto-execute section or
; everything unspecified, they are: warn, debug (default), info and trace.
; Use the env variable AHK_LOG like below.
;
; Examples:
;    ; Set logging for class MiguruWM to debug
;    ; Set logging to warn for everything else
;    AHK_LOG=miguruwm=debug
;
;    ; Set logging for class Workspace to warn
;    ; Set logging for auto-execute section to debug
;    ; Turn off logging for everything else
;    AHK_LOG=off,auto-exec=debug,workspace=warn
;
;    ; Disable logging completely
;    AHK_LOG=disable
class Logger {
    static Disabled := false
    static Labels := [
        "WARN",
        "DEBUG",
        "INFO",
        "TRACE",
    ]
    static Levels := Map()
    static PrintModule := true

    static Init() {
        attached := DllCall("AttachConsole",
            "UInt", -1,
            "Int")

        if attached {
            handle := DllCall("GetStdHandle",
                "UInt", STD_OUTPUT_HANDLE,
                "UInt")
            mode := 0
            DllCall("GetConsoleMode",
                "UInt", handle,
                "UInt*", &mode,
                "Int")

            ; If writing to stdout is not possible...
            if mode & ENABLE_ECHO_INPUT == 0 {
                con := DllCall("GetConsoleWindow", "Ptr")

                ; and there is no cmd window associated...
                if DllCall("IsWindow", "Ptr", con, "Int") &&
                    !DllCall("IsWindowVisible", "Ptr", con, "Int") {

                    ; then undo AttachConsole.
                    DllCall("FreeConsole", "Int")
                    attached := false
                }
            }
        }

        opts := StrLower(EnvGet("AHK_LOG"))
        if (!attached && opts == "") || opts == "disable" {
            Logger.Disabled := true
            return
        }

        if !attached {
            ; If AHK_LOG was set but there's no attached console.
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

StringifySL(self) {
    s := Stringify(self)
    s := StrReplace(s, "`n`t", ", ")
    s := StrReplace(s, "`n", "")
    s := StrReplace(s, "`t", "")
    s := StrReplace(s, "{, ", "{")
    s := StrReplace(s, "[, ", "[")
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
                s .= "`n`t[" k "] " SubStr(RegExReplace(v, "m)^", "`t"), 2)
            } else {
                s .= "`n`t[" k "] = " v
            }
        }
        s .= "`n}"
        return s
    } else if self is Object {
        s := "{"
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
                s .= "`n`t" prop " " SubStr(RegExReplace(v, "m)^", "`t"), 2)
            } else {
                s .= "`n`t" prop " = " v
            }
        }

        s .= "`n}"
        return s
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
