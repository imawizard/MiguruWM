SWP_NOSIZE          := 0x0001
SWP_NOMOVE          := 0x0002
SWP_NOZORDER        := 0x0004
SWP_NOREDRAW        := 0x0008
SWP_NOACTIVATE      := 0x0010
SWP_FRAMECHANGED    := 0x0020
SWP_SHOWWINDOW      := 0x0040
SWP_HIDEWINDOW      := 0x0080
SWP_NOCOPYBITS      := 0x0100
SWP_NOOWNERZORDER   := 0x0200
SWP_NOSENDCHANGING  := 0x0400
SWP_DEFERERASE      := 0x2000
SWP_ASYNCWINDOWPOS  := 0x4000
SWP_DRAWFRAME       := SWP_FRAMECHANGED
SWP_NOREPOSITION    := SWP_NOOWNERZORDER

HWND_TOPMOST   := -1
HWND_TOP       := 0
HWND_BOTTOM    := 1
HWND_NOTOPMOST := -2

TILED    := 0
FLOATING := 1

INSERT_FIRST      := 0
INSERT_LAST       := 1
INSERT_BEFORE_MRU := 2
INSERT_AFTER_MRU  := 3

INDICATE_FOCUS       := 1
INDICATE_FOCUS_DELAY := 200

SWP_FLAGS := 0
    | SWP_ASYNCWINDOWPOS
    | SWP_FRAMECHANGED
    | SWP_NOACTIVATE
    | SWP_NOCOPYBITS
    | SWP_NOOWNERZORDER
    | SWP_NOSENDCHANGING
    | SWP_NOZORDER

class WorkspaceList {
    class Workspace {
        __New(monitor, index, opts) {
            this._monitor := monitor
            this._index := index

            this._windows := Map()
            this._tiled := CircularList()
            this._floating := []

            this._active := ""
            this._mruTile := ""
            this._mruHwnd := ""
            this._opts := opts
            this._delayed := Timeouts()

            this._tileInsertion := Map(
                "first",      INSERT_FIRST,
                "last",       INSERT_LAST,
                "before-mru", INSERT_BEFORE_MRU,
                "after-mru",  INSERT_AFTER_MRU,
            )[this._opts.tilingInsertion]
        }

        Monitor     => this._monitor
        Index       => this._index
        WindowCount => this._windows.Count
        TileCount   => this._tiled.Count
        MruTile     => this._mruTile

        ToString() {
            return Stringify(this)
        }

        Hwnds {
            get {
                hwnds := []
                for hwnd in this._windows {
                    hwnds.Push(hwnd)
                }
                return hwnds
            }
        }

        Layout {
            get => this._opts.layout
            set {
                this._opts.layout := value
                RunDpiAware(() => value.Init(this))
                this.Retile()
            }
        }

        ActiveWindow {
            get => this._active
            set {
                window := this._windows.Get(value, "")
                if !window {
                    return
                }

                if this._active !== value {
                    this._mruHwnd := this._active
                }
                this._active := value
                if window.type == TILED {
                    this._mruTile := window.node
                }
                RunDpiAware(() =>
                    this._opts.layout.ActiveWindowChanged(this))
            }
        }

        LastWindow {
            get => this._mruHwnd
        }

        IsTiled(hwnd) {
            window := this._windows.Get(hwnd, "")
            return window
                ? window.type == TILED
                : ""
        }

        IsFloating(hwnd) {
            window := this._windows.Get(hwnd, "")
            return window
                ? window.type == FLOATING
                : ""
        }

        AddIfNew(hwnd) {
            if this._windows.Has(hwnd) {
                trace(() => ["Ignoring: already added {}", WinInfo(hwnd)])
                return false
            }

            shouldTile := true
            decoless := WinExist("ahk_id" hwnd " ahk_group MIGURU_DECOLESS")
            exstyle := WinGetExStyle("ahk_id" hwnd)
            if !decoless && exstyle & WS_EX_WINDOWEDGE == 0 {
                info(() => ["Floating: no WS_EX_WINDOWEDGE {}", WinInfo(hwnd)])

                shouldTile := false
            } else if !decoless && exstyle & WS_EX_DLGMODALFRAME !== 0 {
                info(() => ["Floating: WS_EX_DLGMODALFRAME {}", WinInfo(hwnd)])

                shouldTile := false
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_AUTOFLOAT") {
                info(() => ["Floating: ahk_group  {}", WinInfo(hwnd)])

                shouldTile := false
            } else {
                width := 0, height := 0

                RunDpiAware(() =>
                    WinGetPos(, , &width, &height, "ahk_id" hwnd)
                )

                if width < this._opts.tilingMinWidth {
                    info(() => ["Floating: width {}<{} {}",
                        width, this._opts.tilingMinWidth,
                        WinInfo(hwnd)])

                    shouldTile := false
                } else if height < this._opts.tilingMinHeight {
                    info(() => ["Floating: height {}<{} {}",
                        height, this._opts.tilingMinHeight,
                        WinInfo(hwnd)])

                    shouldTile := false
                } else {
                    info(() => ["Tiling: {}", WinInfo(hwnd)])
                }
            }

            if shouldTile {
                this._addTiled(hwnd)
            } else {
                this._addFloating(hwnd)
            }
            return true
        }

        _addTiled(hwnd) {
            switch this._tileInsertion {
            case INSERT_FIRST:
                tile := this._tiled.Prepend(hwnd)
            case INSERT_LAST:
                tile := this._tiled.Append(hwnd)
            case INSERT_BEFORE_MRU:
                tile := this._tiled.Prepend(hwnd, this._mruTile)
            case INSERT_AFTER_MRU:
                tile := this._tiled.Append(hwnd, this._mruTile)
            default:
                throw "Incorrect tiling insertion setting: " this._tileInsertion
            }
            if !this._mruTile || this._active == hwnd {
                this._mruTile := tile
            }
            this._windows[hwnd] := { type: TILED, node: tile }
            try WinSetAlwaysOnTop(false, "ahk_id" hwnd)
            this.Retile()
        }

        _addFloating(hwnd) {
            this._floating.Push(hwnd)
            this._windows[hwnd] := {
                type: FLOATING,
                index: this._floating.Length,
            }
            try WinSetAlwaysOnTop(this._opts.floatingAlwaysOnTop, "ahk_id" hwnd)
        }

        Remove(hwnd) {
            window := this._windows.Get(hwnd, "")
            if !window {
                return ""
            }

            trace(() => ["Disappeared: {} {}",
                window.type == TILED ? "tiled" :
                window.type == FLOATING ? "floating" : "",
                WinInfo(hwnd)])

            next := ""
            if window.type == TILED {
                this._removeTiled(window)

                if this._mruTile {
                    next := this._mruTile.data
                } else if this._floating.Length > 0 {
                    next := this._floating[1]
                }
            } else if window.type == FLOATING {
                this._removeFloating(window)

                idx := Min(window.index, this._floating.Length)
                if idx > 0 {
                    next := this._floating[idx]
                } else if this._mruTile {
                    next := this._mruTile.data
                }
            } else {
                return ""
            }

            if hwnd == this._active {
                this._active := next
                return next
            } else {
                return ""
            }
        }

        _removeTiled(window) {
            hwnd := window.node.data
            this._windows.Delete(hwnd)
            wasLast := this._tiled.Last == window.node
            this._mruTile := this._tiled.Drop(window.node)
                ? window.node.next
                : ""
            if this._mruTile && wasLast {
                this._mruTile := this._mruTile.previous
            }
            this.Retile()
        }

        _removeFloating(window) {
            hwnd := this._floating[window.index]
            this._windows.Delete(hwnd)
            for i, hwnd in this._floating {
                if i > window.index {
                    this._windows[hwnd].index--
                }
            }
            this._floating.RemoveAt(window.index)

            if this._opts.floatingAlwaysOnTop {
                try WinSetAlwaysOnTop(false, "ahk_id" hwnd)
            }
        }

        _nextWindow(from) {
            a := this._windows.Get(from, "")
            if !a {
                return ""
            } else if a.type == TILED {
                if a.node == this._tiled.Last && this._floating.Length > 0 {
                    return this._floating[1]
                } else {
                    return a.node.next.data
                }
            } else if a.type == FLOATING {
                if a.index < this._floating.Length {
                    return this._floating[a.index + 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.First.data
                } else {
                    return this._floating[1]
                }
            }
        }

        _previousWindow(from) {
            a := this._windows.Get(from, "")
            if !a {
                return ""
            } else if a.type == TILED {
                if a.node == this._tiled.First && this._floating.Length > 0 {
                    return this._floating[this._floating.Length]
                } else {
                    return a.node.previous.data
                }
            } else if a.type == FLOATING {
                if a.index > 1 {
                    return this._floating[a.index - 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.Last.data
                } else {
                    return this._floating[this._floating.Length]
                }
            }
        }

        GetWindow(target := "", origin := "") {
            if this.WindowCount < 1 {
                return ""
            }

            ;; Start with the active, the mru or the first floating window.
            hwnd := this._windows.Get(origin, "") ? origin
                : this._active
                || this._mruTile && this._mruTile.data
                || this._floating.Get(1, "")

            switch target {
            case "master":
                return this._tiled.First ? this._tiled.First.data : ""
            case "next":
                return this._nextWindow(hwnd)
            case "previous":
                return this._previousWindow(hwnd)
            case "":
                return hwnd
            default:
                throw "Incorrect window target: " target
            }
        }

        Swap(hwnd, with, mouseFollowsFocus := false) {
            if this._tiled.Count < 2 {
                return
            }

            a := this._mruTile
            if hwnd {
                window := this._windows.Get(hwnd, "")
                if !window || window.type !== TILED {
                    debug("Window #{} to swap not in workspace", hwnd)
                    return
                }
                a := window.node
            }

            switch with {
            case "next":
                b := a.next
            case "previous":
                b := a.previous
            case "master":
                b := this._tiled.First
            default:
                throw "Incorrect swap parameter: " with
            }

            if mouseFollowsFocus
                && (a.data == this._active || b.data == this._active) {

                hwnd := b.data == this._active
                    ? a.data
                    : b.data

                RunDpiAware(() => (
                    WinGetPos(&left, &top, &width, &height,
                        "ahk_id" hwnd),
                    DllCall(
                        "SetCursorPos",
                        "Int", left + width // 2,
                        "Int", top + height // 2,
                        "Int",
                    ))
                )
            }

            if a.data == this._active {
                this._mruHwnd := b.data
            }

            this._tiled.Swap(a, b)
            this.Retile()
        }

        Float(hwnd, value) {
            window := this._windows.Get(hwnd, "")
            if !window {
                return
            }

            if window.type == TILED {
                if value || value == "toggle" {
                    this._removeTiled(window)
                    this._addFloating(hwnd)
                }
            } else if window.type == FLOATING {
                if !value || value == "toggle" {
                    this._removeFloating(window)
                    this._addTiled(hwnd)
                }
            }
        }

        MasterCount {
            get => this._opts.masterCount
            set {
                if !IsNumber(value) {
                    throw "Must be a number"
                }
                if value >= 1 && value <= 6 {
                    this._opts.masterCount := value
                    this.Retile()
                }
            }
        }

        MasterSize {
            get => Round(this._opts.masterSize, 3)
            set {
                if !IsNumber(value) {
                    throw "Must be a number"
                }
                if value >= 0.0 && value <= 1.0 {
                    this._opts.masterSize := value
                    this.Retile()
                }
            }
        }

        Padding {
            get => ObjClone(this._opts.padding)
            set {
                this._opts.padding := ObjMerge(this._opts.padding, value)
                this.Retile()
            }
        }

        Spacing {
            get => this._opts.spacing
            set {
                if !IsInteger(value) {
                    throw "Must be an integer"
                }
                if value >= 0 {
                    this._opts.spacing := Integer(value)
                    this.Retile()
                }
            }
        }

        Retile() {
            if !this._tiled.First {
                return
            }

            info("Retiling... D={} WS={} T={} L={}",
                this._monitor.Index, this._index,
                this._tiled.Count, this._opts.layout.DisplayName)

            if this._opts.focusIndicator.UpdateOnRetile
                && this._opts.focusIndicator.HideWhenPositioning {
                this._opts.focusIndicator.Hide()
            }

            try {
                RunDpiAware(() => this._opts.layout.Retile(this))
            } catch WindowError as err {
                warn("Removing window: {} {}",
                    err.cause.Message, WinInfo(err.hwnd))
                this.Remove(err.hwnd)
            }

            if this._opts.focusIndicator.UpdateOnRetile {
                this._delayed.Replace(
                    () => this._opts.focusIndicator.Show(WinExist("A")),
                    INDICATE_FOCUS_DELAY,
                    INDICATE_FOCUS,
                )
            }
        }

        _moveWindow(hwnd, x, y, width, height) {
            bounds := ExtendedFrameBounds(hwnd)
            info(() => ["ExtendedFrameBounds({}) are {}",
                hwnd, StringifySL(bounds)])

            x -= bounds.left
            y -= bounds.top
            width += bounds.left + bounds.right
            height += bounds.top + bounds.bottom

            context := DllCall(
                "GetWindowDpiAwarenessContext",
                "Ptr", hwnd,
                "Ptr",
            )
            hwndAwareness := DllCall(
                "GetAwarenessFromDpiAwarenessContext",
                "Ptr", context,
                "UInt",
            )

            awareness := ""
            couldOverflow := false

            if hwndAwareness < DPI_AWARENESS_PER_MONITOR_AWARE {
                hwndDPI := DllCall(
                    "GetDpiFromDpiAwarenessContext",
                    "Ptr", context,
                    "UInt",
                )
                debug("Non-dpi aware window: {}", WinInfo(hwnd))
                debug("  awareness of window={}", hwndAwareness)
                debug("  dpi of window={} monitor={} system={} ahk={}",
                    hwndDPI, this._monitor.DPI, A_SystemDPI, A_ScreenDPI)

                if A_ScreenDPI == A_SystemDPI && A_ScreenDPI == this._monitor.DPI {
                    awareness := SetDpiAwareness(DPI_SYSAWARE)
                } else if A_ScreenDPI !== A_SystemDPI && A_ScreenDPI > this._monitor.DPI {
                    awareness := SetDpiAwareness(DPI_UNAWARE)
                } else {
                    couldOverflow := true
                }
            }

            if couldOverflow {
                ;; HACK: Keep DPI_PMv2, but since filling out all the available
                ;; space makes windows that are not properly dpi-aware overflow
                ;; to the next monitor, shrink their width here by bounds.left.
                ;; Weirdly, shrinking just by e.g. bounds.left-1 the window
                ;; already overflows, even though there'd still be space to fill.
                if x <= this._monitor.Area.Left + bounds.left {
                    if this._monitor.Index > 1 {
                        x     += this._monitor.Area.Left + bounds.left - x
                        width -= this._monitor.Area.Left + bounds.left - x
                    }
                }
                if x + width >= this._monitor.Area.Right - bounds.right {
                    if this._monitor.Index < MonitorGetCount() {
                        width := this._monitor.Area.Right - bounds.right - x
                    }
                }
            }

            try {
                if WinGetMinMax("ahk_id" hwnd) > 0 {
                    WinRestore("ahk_id" hwnd)
                }

                if !DllCall(
                    "SetWindowPos",
                    "Ptr", hwnd,
                    "Ptr", HWND_TOP,
                    "Int", x,
                    "Int", y,
                    "Int", width,
                    "Int", height,
                    "UInt", SWP_FLAGS,
                    "Int",
                ) {
                    warn("SetWindowPos failed for hwnd #{}"
                        " with x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
                        hwnd, x, y, width, height)
                } else if awareness !== "" {
                    debug("SetWindowPos({})"
                        " to x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
                        hwnd, x, y, width, height)
                }
            } catch {
                throw
            } finally {
                if awareness !== "" {
                    SetDpiAwareness(awareness)
                }
            }
        }
    }

    __New(monitors, defaults) {
        this._workspaces := Map()
        this._defaults := defaults
        this.Update(monitors)
    }

    ToString() {
        return Type(this) "(" SubStr(Stringify({
            Workspaces: this._workspaces,
            Count: this.Count,
        }), 2, -1) ")"
    }

    __Enum(numberOfVars) {
        mapiter := this._workspaces.__Enum(2)
        arriter := ""

        iter(&v) {
            if arriter && arriter(&idx, &v) {
                return true
            } else if !mapiter(&handle, &workspaces) {
                return false
            }
            arriter := workspaces.__Enum(1)
            return iter(&v)
        }
        return iter
    }

    Update(monitors) {
        had := this._workspaces.Clone()
        for m in monitors {
            if had.Has(m.Handle) {
                for idx, ws in this._workspaces[m.Handle] {
                    ws._monitor := m
                }
                had.Delete(m.Handle)
            } else {
                this._workspaces[m.Handle] := Map()
            }
        }
        return had
    }

    __Item[monitor, index] {
        get {
            workspaces := this._workspaces[monitor.Handle]
            ws := workspaces.Get(index, "")
            if !ws {
                opts := ObjClone(this._defaults)
                ws := WorkspaceList.Workspace(monitor, index, opts)
                workspaces[index] := ws
            }
            return ws
        }
    }
}
