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
                "threecolumns", this._threeColumnsRetile,
                "spiral",       this._spiralRetile
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
                width := 0, height := 0

                RunDpiAware(() =>
                    WinGetPos(, , &width, &height, "ahk_id" hwnd)
                )

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
            this._windows[hwnd] := {
                type: FLOATING,
                index: this._floating.Length,
            }
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
            if mouseFollowsFocus {
                RunDpiAware(() => (
                    WinGetPos(&left, &top, &width, &height, "ahk_id" hwnd),
                    DllCall(
                        "SetCursorPos",
                        "Int", left + width // 2,
                        "Int", top + height // 2,
                        "Int",
                    ))
                )
            }

            WinActivate("ahk_id" hwnd)
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
                    RunDpiAware(() =>
                        DllCall(
                            "SetCursorPos",
                            "Int", monitor.Area.CenterX,
                            "Int", monitor.Area.CenterY,
                            "Int",
                        )
                    )
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
                        ;; this._active still holds the last active window for
                        ;; the workspace, so just focus that.
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

            if mouseFollowsFocus &&
                (a.data == this._active || b.data == this._active) {

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
            get => ObjClone(this._opts.padding)
            set {
                this._opts.padding := ObjMerge(this._opts.padding, value)
                this.Retile()
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

            try {
                RunDpiAware(() => this._retile())
            } catch WorkspaceList.Workspace.WindowError as err {
                warn("Removing window: {} {}",
                    err.cause.Message, WinInfo(err.hwnd))
                this.Remove(err.hwnd)
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

        _tallRetile() {
            opts := this._opts
            masterCount := Min(opts.masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            usableWidth := workArea.Width
                - opts.padding.left
                - opts.padding.right
            usableHeight := workArea.Height
                - opts.padding.top
                - opts.padding.bottom

            if masterCount >= 1 && slaveCount >= 1 {
                masterWidth := Round(usableWidth * opts.masterSize)
                firstSlave := this._tallRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    masterWidth - opts.spacing // 2,
                    usableHeight,
                )

                slaveWidth := usableWidth - masterWidth
                this._tallRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding.left
                        + masterWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                )
            } else {
                this._tallRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    usableWidth,
                    usableHeight,
                )
            }
        }

        _tallRetilePane(tile, count, x, startY, totalWidth, totalHeight) {
            spacing := this._opts.spacing > 0 && count > 1
                ? this._opts.spacing // 2
                : 0
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

            usableWidth := workArea.Width
                - opts.padding.left
                - opts.padding.right
            usableHeight := workArea.Height
                - opts.padding.top
                - opts.padding.bottom

            if masterCount >= 1 && slaveCount >= 1 {
                masterHeight := Round(usableHeight * opts.masterSize)
                firstSlave := this._wideRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    usableWidth,
                    masterHeight - opts.spacing // 2,
                )

                slaveHeight := usableHeight - masterHeight
                this._wideRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top
                        + masterHeight + opts.spacing // 2,
                    usableWidth,
                    slaveHeight - opts.spacing // 2,
                )
            } else {
                this._wideRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    usableWidth,
                    usableHeight,
                )
            }
        }

        _wideRetilePane(tile, count, startX, y, totalWidth, totalHeight) {
            spacing := this._opts.spacing > 0 && count > 1
                ? this._opts.spacing // 2
                : 0
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
                hwnd := this._mruTile.data
                opts := this._opts

                if !opts.nativeMaximize {
                    workArea := this._monitor.WorkArea
                    this._tallRetilePane(
                        this._mruTile,
                        1,
                        workArea.left + opts.padding.left,
                        workArea.top + opts.padding.top,
                        workArea.Width - opts.padding.left - opts.padding.right,
                        workArea.Height - opts.padding.top - opts.padding.bottom,
                    )
                } else {
                    WinMaximize("ahk_id" hwnd)
                }

                ;; Move window to the foreground, even in front of possible
                ;; siblings.
                this._silentlySetAlwaysOnTop(hwnd, true)
                this._silentlySetAlwaysOnTop(hwnd, false)
            }
        }

        _floatingRetile() {
            ;; Do nothing
        }

        _threeColumnsRetile() {
            opts := this._opts
            masterCount := Min(opts.masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            usableWidth := workArea.Width
                - opts.padding.left
                - opts.padding.right
            usableHeight := workArea.Height
                - opts.padding.top
                - opts.padding.bottom

            if masterCount >= 1 && slaveCount >= 1 {
                ; 1.3 should be replaced by an option
                masterWidth := Round(usableWidth * opts.masterSize * 1.3)
                slaveWidth := usableWidth - masterWidth
                if slaveCount == 1 {
                    firstSlave := this._tallRetilePane(
                        this._tiled.First,
                        masterCount,
                        workArea.left + opts.padding.left,
                        workArea.top + opts.padding.top,
                        masterWidth - opts.spacing // 2,
                        usableHeight,
                    )
                    this._tallRetilePane(
                        firstSlave,
                        slaveCount,
                        workArea.left + opts.padding.left + masterWidth + opts.spacing // 2,
                        workArea.top + opts.padding.top,
                        slaveWidth -  opts.spacing // 2,
                        usableHeight,
                    )
                }
                else{
                    masterWidth := Round(usableWidth * opts.masterSize * 1.3)
                    slaveWidth := Round((usableWidth - masterWidth) // 2)
                    firstSlave := this._tallRetilePane(
                        this._tiled.First,
                        masterCount,
                        workArea.left + opts.padding.left + 
                                    slaveWidth + opts.spacing // 2,
                        workArea.top + opts.padding.top,
                        masterWidth - opts.spacing,
                        usableHeight,
                    )
                    this._threeColumnsRetilePane(
                        firstSlave,
                        slaveCount,
                        workArea.left + opts.padding.left,
                        workArea.top + opts.padding.top,
                        workArea.right - opts.padding.right - slaveWidth + opts.spacing // 2,
                        workArea.top + opts.padding.top,
                        slaveWidth - opts.spacing // 2,
                        usableHeight,
                    )
                }
            }
            else {
                this._tallRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    usableWidth,
                    usableHeight,
                )
            }
        }

        _threeColumnsRetilePane(tile, count, left_x, left_y, right_x, right_y, totalWidth, totalHeight){
            spacing := this._opts.spacing > 0 && count > 1 ? this._opts.spacing // 2 : 0

            slave_left_num := Integer(count/2)
            slave_right_num := count - slave_left_num
            spacing_right := this._opts.spacing > 0 && slave_right_num > 1 ? this._opts.spacing // 2 : 0
            spacing_left  := this._opts.spacing > 0 && slave_left_num > 1 ? this._opts.spacing // 2 : 0
            height_right := Round((totalHeight - spacing_right * Max(slave_right_num - 2, 0)) / slave_right_num)
            height_left := Round((totalHeight - spacing_left * Max(slave_left_num - 2, 0)) / slave_left_num)

            try {
                Loop count {
                    if A_Index <= slave_right_num {
                        this._moveWindow(
                            tile.data,
                            right_x,
                            right_y,
                            totalWidth,
                            height_right - spacing_right,
                        )
                        right_y += height_right + spacing_right
                    }
                    else{
                        this._moveWindow(
                            tile.data,
                            left_x,
                            left_y,
                            totalWidth,
                            height_left - spacing_left,
                        )
                        left_y += height_left + spacing_left
                    }
                    tile := tile.next
                }
            } catch TargetError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            } catch OSError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            }
            return tile
        }

        _spiralRetile() {
            opts := this._opts
            masterCount := Min(opts.masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            usableWidth := workArea.Width
                - opts.padding.left
                - opts.padding.right
            usableHeight := workArea.Height
                - opts.padding.top
                - opts.padding.bottom

            if masterCount >=1 && slaveCount >= 1 {
                masterWidth := Round(usableWidth * opts.masterSize)
                firstSlave := this._tallRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    masterWidth - opts.spacing // 2,
                    usableHeight,
                )
                slaveWidth := usableWidth - masterWidth
                this._spiralRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + opts.padding.left + masterWidth + opts.spacing // 2,
                    workArea.top + opts.padding.top,
                    slaveWidth - opts.spacing // 2,
                    usableHeight,
                    "down"
                )
            }
            else {
                this._tallRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + opts.padding.left,
                    workArea.top + opts.padding.top,
                    usableWidth,
                    usableHeight, 
                )
            }
        }

        _spiralRetilePane(tile, count, x, y, totalWidth, totalHeight, splitDirection){
            spacing := this._opts.spacing > 0 && count > 1 ? this._opts.spacing // 2 : 0
            height := Round((totalHeight - spacing * Max(count - 2, 0)) / count)

            get_sub_container(cur_window){
                dir := cur_window[1]
                x := cur_window[2], y := cur_window[3]
                w := cur_window[4], h := cur_window[5]
                if dir=="right"     return ["down", x + w + spacing * 2, y, w, h]
                if dir=="down"      return ["left", x, y + h + spacing * 2, w, h]
                if dir=="left"      return ["up"  , x - spacing * 2 - w, y, w, h]
                if dir=="up"        return ["right",x, y - h - spacing * 2, w, h]
            }

            get_first_window_in_container(cur_container){
                dir := cur_container[1]
                x := cur_container[2], y := cur_container[3]
                w := cur_container[4], h := cur_container[5]
                if dir=="right"     return ["right", x, y, Round(w/2) - spacing, h]
                if dir=="down"      return ["down" , x, y, w, Round(h/2) - spacing]
                if dir=="left"      return ["left" , x + Round(w/2) + spacing, y, Round(w/2) - spacing, h]
                if dir=="up"        return ["up"   , x, y + Round(h/2) + spacing, w, Round(h/2) - spacing]
            }

            cur_container := [splitDirection,x,y,totalWidth,totalHeight]

            try {
            Loop count {
                    ; the formatted code might be confusing
                    ; let me know if it needs more comments
                    cur_window := get_first_window_in_container(cur_container)
                    cur_x := (A_Index == count) ? cur_container[2] : cur_window[2]
                    cur_y := (A_Index == count) ? cur_container[3] : cur_window[3]
                    cur_w := (A_Index == count) ? cur_container[4] : cur_window[4]
                    cur_h := (A_Index == count) ? cur_container[5] : cur_window[5]
                    this._moveWindow(
                        tile.data,
                        cur_x,
                        cur_y,
                        cur_w,
                        cur_h,
                    )
                    tile := tile.next
                    cur_container := get_sub_container(cur_window)
                }
            } catch TargetError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            } catch OSError as err {
                throw WorkspaceList.Workspace.WindowError(tile.data, err)
            }
            return tile
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
