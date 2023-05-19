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
            this._opts := opts

            this._tileInsertion := Map(
                "first",      INSERT_FIRST,
                "last",       INSERT_LAST,
                "before-mru", INSERT_BEFORE_MRU,
                "after-mru",  INSERT_AFTER_MRU,
            )[this._opts.tilingInsertion]

            this._retileFns := Map(
                "tall",       this._tallRetile,
                "wide",       this._wideRetile,
                "fullscreen", this._fullscreenRetile,
                "floating",   this._floatingRetile,
            )
            this._retile := this._retileFns[StrLower(this._opts.layout)]
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
                this._retile := this._retileFns[StrLower(this._opts.layout)]
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

                this._active := value
                if window.type == TILED {
                    this._mruTile := window.node

                    if StrCompare(this._opts.layout, "fullscreen") == 0 {
                        this.Retile()
                    }
                }
            }
        }

        AddIfNew(hwnd) {
            if this._windows.Has(hwnd) {
                trace(() => ["Ignoring: already added {}", WinInfo(hwnd)])
                return false
            }

            shouldTile := true
            exstyle := WinGetExStyle("ahk_id" hwnd)
            if exstyle & WS_EX_WINDOWEDGE == 0 {
                info(() => ["Floating: no WS_EX_WINDOWEDGE {}", WinInfo(hwnd)])

                shouldTile := false
            } else if exstyle & WS_EX_DLGMODALFRAME !== 0 {
                info(() => ["Floating: WS_EX_DLGMODALFRAME {}", WinInfo(hwnd)])

                shouldTile := false
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_AUTOFLOAT") {
                info(() => ["Floating: ahk_group  {}", WinInfo(hwnd)])

                shouldTile := false
            } else {
                old := SetDpiAwareness(DPI_PMv2)
                try {
                    WinGetPos(, , &width, &height, "ahk_id" hwnd)
                } catch {
                    throw
                } finally {
                    SetDpiAwareness(old)
                }

                if this._opts.tilingMinWidth > 0 &&
                    width < this._opts.tilingMinWidth {
                    info(() => ["Floating: width {}<{} {}",
                        width, this._opts.tilingMinWidth,
                        WinInfo(hwnd)])

                    shouldTile := false
                } else if this._opts.tilingMinHeight > 0 &&
                    height < this._opts.tilingMinHeight {
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
            if !this._mruTile {
                this._mruTile := tile
            }
            this._windows[hwnd] := { type: TILED, node: tile }
            this._silentlySetAlwaysOnTop(hwnd, false)
            this.Retile()
        }

        _addFloating(hwnd) {
            this._floating.Push(hwnd)
            this._windows[hwnd] := { type: FLOATING, index: this._floating.Length }
            this._silentlySetAlwaysOnTop(hwnd, this._opts.floatingAlwaysOnTop)
        }

        _silentlySetAlwaysOnTop(hwnd, value) {
            try {
                WinSetAlwaysOnTop(value, "ahk_id" hwnd)
            } catch TargetError {
                ;; Do nothing
            } catch OSError {
                ;; Do nothing
            }
        }

        Remove(hwnd, focus := false, mouseFollowsFocus := false) {
            window := this._windows.Get(hwnd, "")
            if !window {
                return false
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
                return false
            }

            if hwnd == this._active {
                this._active := next
            }
            if focus && next {
                this._focusWindow(next, mouseFollowsFocus)
            }

            return true
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
                this._silentlySetAlwaysOnTop(hwnd, false)
            }
        }

        _focusWindow(hwnd, mouseFollowsFocus) {
            WinActivate("ahk_id" hwnd)

            if mouseFollowsFocus {
                old := SetDpiAwareness(DPI_PMv2)
                try {
                    WinGetPos(&left, &top, &width, &height, "ahk_id" hwnd)
                } catch {
                    throw
                } finally {
                    SetDpiAwareness(old)
                }

                old := A_CoordModeMouse
                CoordMode("Mouse", "Screen")
                MouseMove(left + width // 2, top + height // 2, 0)
                CoordMode("Mouse", old)
            }
        }

        _nextWindow(from) {
            a := this._windows[from]
            if a.type == TILED {
                if a.node == this._tiled.Last && this._floating.Length > 0 {
                    return this._floating[1]
                } else if this._tiled.Count > 1 {
                    return a.node.next.data
                }
            } else if a.type == FLOATING {
                if a.index < this._floating.Length {
                    return this._floating[a.index + 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.First.data
                }
            }
        }

        _previousWindow(from) {
            a := this._windows[from]
            if a.type == TILED {
                if a.node == this._tiled.First && this._floating.Length > 0 {
                    return this._floating[this._floating.Length]
                } else if this._tiled.Count > 1 {
                    return a.node.previous.data
                }
            } else if a.type == FLOATING {
                if a.index > 1 {
                    return this._floating[a.index - 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.Last.data
                }
            }
        }

        Focus(hwnd := "", target := "active", mouseFollowsFocus := false) {
            if this.WindowCount < 1 {
                ;; If there is no tile associated, focus the monitor by
                ;; activating its taskbar.
                monitor := this._monitor
                taskbar := monitor.Taskbar()
                if !taskbar {
                    warn("Can't focus monitor {} without a tile or a taskbar",
                        monitor.Index)
                    return
                }

                WinActivate("ahk_id" taskbar)

                if mouseFollowsFocus {
                    ;; Also place the cursor in the middle of the specified
                    ;; screen for e.g. PowerToys Run.
                    old := A_CoordModeMouse
                    CoordMode("Mouse", "Screen")
                    MouseMove(monitor.Area.CenterX, monitor.Area.CenterY, 0)
                    CoordMode("Mouse", old)
                }
                return
            }

            anchor := this._active ||
                this.mruTile && this.mruTile.data ||
                this._floating.Get(1, "")

            hwnd := ""
            switch target {
            case "next":
                hwnd := this._nextWindow(anchor)
            case "previous":
                hwnd := this._previousWindow(anchor)
            case "master":
                hwnd := this._tiled.First.data
            case "active":
                hwnd := anchor
            default:
                throw "Incorrect focus target: " target
            }

            if !hwnd {
                if this._active {
                    if this._active == WinExist("A") {
                        ;; If e.g. the currently active window is unmanaged,
                        ;; this._active still holds the last active window for the
                        ;; workspace, so just focus that.
                        info("Focus window #{} which was last active", hwnd)
                    } else {
                        warn("Focus window #{} which was last active but is inactive now",
                            hwnd)
                    }
                    this._focusWindow(this._active, mouseFollowsFocus)
                } else {
                    warn("Nothing to focus")
                }
                return
            }

            info("Focus window #{}", hwnd)
            this._focusWindow(hwnd, mouseFollowsFocus)

            t := this._windows[hwnd]
            if t.type == TILED {
                this._mruTile := t.node
                if StrCompare(this._opts.layout, "fullscreen") == 0 {
                    this.Retile()
                }
            }
        }

        Swap(hwnd, with) {
            if this._tiled.Count < 2 {
                return
            }

            target := this._mruTile
            if hwnd {
                window := this._windows.Get(hwnd, "")
                if !window || window.type !== TILED {
                    debug("Window #{} to swap not in workspace", hwnd)
                    return
                }
                target := window.node
            }

            switch with {
            case "next":
                this._tiled.Swap(target, target.next)
            case "previous":
                this._tiled.Swap(target, target.previous)
            case "master":
                this._tiled.Swap(target, this._tiled.First)
            default:
                throw "Incorrect swap parameter: " with
            }
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
                if value >= 0 && value <= 6 {
                    this._opts.masterCount := value
                    this.Retile()
                }
            }
        }

        MasterSize {
            get => Round(this._opts.masterSize, 2)
            set {
                if value >= 0.0 && value <= 1.0 {
                    this._opts.masterSize := value
                    this.Retile()
                }
            }
        }

        Padding {
            get => this._opts.padding // 2
            set {
                if value >= 0 {
                    this._opts.padding := Integer(value) * 2
                    this.Retile()
                }
            }
        }

        Spacing {
            get => this._opts.spacing // 2
            set {
                if value >= 0 {
                    this._opts.spacing := Integer(value) * 2
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
                this._tiled.Count, this._opts.layout)

            old := SetDpiAwareness(DPI_PMv2)
            try {
                this._retile()
            } catch WorkspaceList.Workspace.WindowError as err {
                warn("Removing window: {} {}",
                    err.cause.Message, WinInfo(err.hwnd))
                this.Remove(err.hwnd)
            } finally {
                SetDpiAwareness(old)
            }
        }

        class WindowError {
            __New(hwnd, err) {
                this.hwnd := hwnd
                this.cause := err
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
            hwndDPI := DllCall(
                "GetDpiFromDpiAwarenessContext",
                "Ptr", context,
                "UInt",
            )

            ;; FIXME: Seemed to work at first, but apparently only for specific
            ;; combinations of monitor dpi, primary dpi and window dpi.
            ;; There's also the case that an application doesn't react to system
            ;; dpi changes, e.g. a system dpi-aware application creates a window
            ;; with the system dpi being e.g. 120. Upon connecting an external
            ;; display that is set up as primary the system dpi might change to
            ;; e.g. 96 but the window still reports 120. When restarting the
            ;; application, however, its window would report 96.
            awareness := ""
            couldOverflow := false
            if hwndDPI == A_ScreenDPI {
                if this._monitor.DPI == A_ScreenDPI {
                    awareness := SetDpiAwareness(DPI_SYSAWARE)
                } else {
                    ;awareness := SetDpiAwareness(DPI_UNAWARE)
                    couldOverflow := true
              }
            } else if hwndDPI !== 0 {
                ;awareness := SetDpiAwareness(DPI_UNAWARE)
                ;scale := this._monitor.DPI / hwndDPI
                ;x /= scale
                ;y /= scale
                ;width /= scale
                ;height /= scale
                couldOverflow := true
            }
            if couldOverflow {
                debug("DPI window={} monitor={} system={}",
                    hwndDPI, this._monitor.DPI, A_ScreenDPI)

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
                    warn("SetWindowPos failed for hwnd #{} with x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
                        hwnd, x, y, width, height)
                } else if awareness !== "" {
                    debug("SetWindowPos({}) to x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
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

        _tallRetile() {
            opts := this._opts
            masterCount := Min(opts.masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            if masterCount >= 1 && slaveCount >= 1 {
                masterWidth := Round(workArea.Width * opts.masterSize)
                firstSlave := this._tallRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + opts.padding,
                    workArea.top + opts.padding,
                    masterWidth - opts.padding - opts.spacing // 2,
                    workArea.Height - 2 * opts.padding,
                )

                slaveWidth := workArea.Width - masterWidth
                this._tallRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + masterWidth + opts.spacing // 2,
                    workArea.top + opts.padding,
                    slaveWidth - opts.padding - opts.spacing // 2,
                    workArea.Height - 2 * opts.padding,
                )
            } else {
                this._tallRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding,
                    workArea.top + opts.padding,
                    workArea.Width - 2 * opts.padding,
                    workArea.Height - 2 * opts.padding,
                )
            }
        }

        _tallRetilePane(tile, count, x, startY, totalWidth, totalHeight) {
            spacing := this._opts.spacing > 0 && count > 1 ? this._opts.spacing // 2 : 0
            height := Round((totalHeight - spacing * Max(count - 2, 0)) / count)
            y := startY

            try {
                Loop count {
                    this._moveWindow(
                        tile.data,
                        x,
                        y,
                        totalWidth,
                        height - spacing,
                    )
                    y += height + spacing
                    tile := tile.next
                }
            } catch TargetError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            } catch OSError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            }
            return tile
        }

        _wideRetile() {
            opts := this._opts
            masterCount := Min(opts.masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            if masterCount >= 1 && slaveCount >= 1 {
                masterHeight := Round(workArea.Height * opts.masterSize)
                firstSlave := this._wideRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + opts.padding,
                    workArea.top + opts.padding,
                    workArea.Width - 2 * opts.padding,
                    masterHeight - opts.padding - opts.spacing // 2,
                )

                slaveHeight := workArea.Height - masterHeight
                this._wideRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding,
                    workArea.top + masterHeight + opts.spacing // 2,
                    workArea.Width - 2 * opts.padding,
                    slaveHeight - opts.padding - opts.spacing // 2,
                )
            } else {
                this._wideRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding,
                    workArea.top + opts.padding,
                    workArea.Width - 2 * opts.padding,
                    workArea.Height - 2 * opts.padding,
                )
            }
        }

        _wideRetilePane(tile, count, startX, y, totalWidth, totalHeight) {
            spacing := this._opts.spacing > 0 && count > 1 ? this._opts.spacing // 2 : 0
            width := Round((totalWidth - spacing * Max(count - 2, 0)) / count)
            x := startX

            try {
                Loop count {
                    this._moveWindow(
                        tile.data,
                        x,
                        y,
                        width - spacing,
                        totalHeight,
                    )
                    x += width + spacing
                    tile := tile.next
                }
            } catch TargetError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            } catch OSError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            }
            return tile
        }

        _fullscreenRetile() {
            if this._mruTile {
                opts := this._opts
                if !opts.nativeMaximize {
                    workArea := this._monitor.WorkArea
                    this._tallRetilePane(
                        this._mruTile,
                        1,
                        workArea.left + opts.padding,
                        workArea.top + opts.padding,
                        workArea.Width - 2 * opts.padding,
                        workArea.Height - 2 * opts.padding,
                    )
                } else {
                    WinMaximize("ahk_id" this._mruTile.data)
                }

                ;; Move window to the foreground, even in front of possible
                ;; siblings.
                WinSetAlwaysOnTop(true, "ahk_id" this._mruTile.data)
                WinSetAlwaysOnTop(false, "ahk_id" this._mruTile.data)
            }
        }

        _floatingRetile() {
            ;; Do nothing
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
                ws := WorkspaceList.Workspace(monitor, index, ObjClone(this._defaults))
                workspaces[index] := ws
            }
            return ws
        }
    }
}
