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

TILED   := 0
FLOATED := 1

INSERT_FIRST      := 0
INSERT_LAST       := 1
INSERT_BEFORE_MRU := 2
INSERT_AFTER_MRU  := 3

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
            this._retile := this._retileFns[this._opts.layout]
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
                this._retile := this._retileFns[this._opts.layout]
                this.Retile()
            }
        }

        ActiveWindow {
            get => this._active
            set {
                entry := this._windows.Get(value, "")
                if !entry {
                    return
                }

                this._active := value
                if entry.type == TILED {
                    this._mruTile := entry.node
                }
            }
        }

        AddIfNew(hwnd) {
            if this._windows.Has(hwnd) {
                return false
            }

            shouldTile := true
            exstyle := WinGetExStyle("ahk_id" hwnd)
            if exstyle & WS_EX_WINDOWEDGE == 0 {
                trace(() => ["Floating: no WS_EX_WINDOWEDGE {}", WinInfo(hwnd)])
                shouldTile := false
            } else if exstyle & WS_EX_DLGMODALFRAME !== 0 {
                trace(() => ["Floating: WS_EX_DLGMODALFRAME {}", WinInfo(hwnd)])
                shouldTile := false
            } else if WinExist("ahk_id" hwnd " ahk_group MIGURU_AUTOFLOAT") {
                trace(() => ["Floating: ahk_group  {}", WinInfo(hwnd)])
                shouldTile := false
            } else {
                WinGetPos(, , &width, &height, "ahk_id" hwnd)
                if this._opts.tilingMinWidth > 0 && width < this._opts.tilingMinWidth {
                    trace(() => ["Floating: width {}<{} {}",
                        width, this._opts.tilingMinWidth,
                        WinInfo(hwnd)])
                    shouldTile := false
                } else if this._opts.tilingMinHeight > 0 && height < this._opts.tilingMinHeight {
                    trace(() => ["Floating: height {}<{} {}",
                        height, this._opts.tilingMinHeight,
                        WinInfo(hwnd)])
                    shouldTile := false
                } else {
                    trace(() => ["Tiling: {}", WinInfo(hwnd)])
                }
            }

            if shouldTile {
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
                    throw "Incorrect tiling insertion setting"
                }
                this._mruTile := tile
                this._windows[hwnd] := { type: TILED, node: tile }
                this.Retile()
            } else {
                this._floating.Push(hwnd)
                this._windows[hwnd] := { type: FLOATED, index: this._floating.Length }
                WinSetAlwaysOnTop(this._opts.floatingAlwaysOnTop, "ahk_id" hwnd)
            }

            this._active := hwnd
            return true
        }

        Remove(hwnd, focus := true) {
            entry := this._windows.Get(hwnd, "")
            if !entry {
                return false
            }

            trace(() => ["Disappeared: {} {}", entry.type, WinInfo(hwnd)])
            this._windows.Delete(hwnd)

            if entry.type == TILED {
                wasLast := this._tiled.Last == entry.node
                this._mruTile := this._tiled.Drop(entry.node)
                    ? entry.node.next
                    : ""

                if this._mruTile {
                    if wasLast {
                        this._mruTile := this._mruTile.previous
                    }
                    if focus {
                        WinActivate("ahk_id" this._mruTile.data)
                    }
                }
                this.Retile()
                return true
            } else if entry.type == FLOATED {
                for i, hwnd in this._floating {
                    if i > entry.index {
                        this._windows[hwnd].index--
                    }
                }
                this._floating.RemoveAt(entry.index)

                if focus {
                    next := Min(entry.index, this._floating.Length)
                    if next {
                        WinActivate("ahk_id" this._floating[next])
                    } else if this._mruTile {
                        WinActivate("ahk_id" this._mruTile.data)
                    }
                }
                return true
            }
        }

        _nextWindow() {
            a := this._windows[this._active]
            if a.type == TILED {
                if a.node == this._tiled.Last && this._floating.Length > 0 {
                    return this._floating[1]
                } else if this._tiled.Count > 1 {
                    return a.node.next.data
                }
            } else if a.type == FLOATED {
                if a.index < this._floating.Length {
                    return this._floating[a.index + 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.First.data
                }
            }
        }

        _previousWindow() {
            a := this._windows[this._active]
            if a.type == TILED {
                if a.node == this._tiled.First && this._floating.Length > 0 {
                    return this._floating[this._floating.Length]
                } else if this._tiled.Count > 1 {
                    return a.node.previous.data
                }
            } else if a.type == FLOATED {
                if a.index > 1 {
                    return this._floating[a.index - 1]
                } else if this._tiled.Count > 0 {
                    return this._tiled.Last.data
                }
            }
        }

        Focus(target) {
            if this._windows.Count < 1 {
                return
            }

            switch target {
            case "next":
                hwnd := this._nextWindow()
            case "previous":
                hwnd := this._previousWindow()
            case "master":
                hwnd := this._tiled.First.data
            default:
                throw "Incorrect focus target"
            }

            if !hwnd {
                info("Nothing to focus")
                return
            }
            info("Focus window #{}", hwnd)
            WinActivate("ahk_id" hwnd)

            t := this._windows[hwnd]
            if t.type == TILED {
                this._mruTile := t.node
                if this._opts.layout == "fullscreen" {
                    this.Retile()
                }
            }
        }

        Swap(target) {
            if this._tiled.Count < 2 {
                return
            }

            switch target {
            case "next":
                this._tiled.Swap(this._mruTile, this._mruTile.next)
            case "previous":
                this._tiled.Swap(this._mruTile, this._mruTile.previous)
            case "master":
                this._tiled.Swap(this._mruTile, this._tiled.First)
            }
            this.Retile()
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

            info("Retiling ({}, {}) tiles={} layout={}",
                this._monitor.Index, this._index, this._tiled.Count, this._opts.layout)

            old := SetDpiAwareness(DPI_PMv2)
            this._retile()
            SetDpiAwareness(old)
        }

        _moveWindow(hwnd, x, y, width, height) {
            static flags := 0
                | SWP_ASYNCWINDOWPOS
                | SWP_FRAMECHANGED
                | SWP_NOACTIVATE
                | SWP_NOCOPYBITS
                | SWP_NOOWNERZORDER
                | SWP_NOSENDCHANGING
                | SWP_NOZORDER

            context := DllCall(
                "GetWindowDpiAwarenessContext",
                "Ptr", hwnd,
                "Ptr",
            )
            dpi := DllCall(
                "GetDpiFromDpiAwarenessContext",
                "Ptr", context,
                "UInt",
            )

            ; FIXME: Seemed to work at first, but apparently only for specific
            ; combinations of monitor dpi, primary dpi and window dpi
            awareness := ""
            if dpi == A_ScreenDPI {
                if this._monitor.DPI == dpi {
                    awareness := SetDpiAwareness(DPI_SYSAWARE)
                    debug("Use DPI_SYSAWARE window={} monitor={} system={}",
                        dpi, this._monitor.DPI, A_ScreenDPI)
                } else {
                    awareness := SetDpiAwareness(DPI_UNAWARE)
                    debug("Use DPI_UNAWARE window={} monitor={} system={}",
                        dpi, this._monitor.DPI, A_ScreenDPI)
                }
            } else if dpi !== 0 {
                scale := this._monitor.DPI / dpi
                x /= scale
                y /= scale
                width /= scale
                height /= scale

                awareness := SetDpiAwareness(DPI_UNAWARE)
                debug("Scale manually by 1/{} (window={} monitor={} system={})",
                    scale, dpi, this._monitor.DPI, A_ScreenDPI)
            }

            if WinGetMinMax("ahk_id" hwnd) > 0 {
                WinRestore("ahk_id" hwnd)
            }

            if !DllCall(
                "SetWindowPos",
                "Ptr", hwnd,
                "Ptr", 0,
                "Int", x,
                "Int", y,
                "Int", width,
                "Int", height,
                "UInt", flags,
                "Int",
            ) {
                warn("SetWindowPos failed for hwnd 0x{:08x} with x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
                    hwnd, x, y, width, height)
            }

            if awareness !== "" {
                SetDpiAwareness(awareness)
                debug("SetWindowPos(0x{:08x}) to x={:.2f} y={:.2f} width={:.2f} height={:.2f}",
                    hwnd, x, y, width, height)
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

            Loop count {
                bounds := ExtendedFrameBounds(tile.data)
                debug("ExtendenFrameBounds(0x{:08x}) are {}",
                    tile.data, StringifySL(bounds))
                this._moveWindow(
                    tile.data,
                    x - bounds.left,
                    y - bounds.top,
                    totalWidth + bounds.left + bounds.right,
                    height + bounds.top + bounds.bottom - spacing,
                )
                y += height + spacing
                tile := tile.next
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

            Loop count {
                bounds := ExtendedFrameBounds(tile.data)
                debug("ExtendenFrameBounds(0x{:08x}) are {}",
                    tile.data, StringifySL(bounds))
                this._moveWindow(
                    tile.data,
                    x - bounds.left,
                    y - bounds.top,
                    width + bounds.left + bounds.right - spacing,
                    totalHeight + bounds.top + bounds.bottom,
                )
                x += width + spacing
                tile := tile.next
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

                ; Move window to the foreground, even in front of possible siblings
                WinSetAlwaysOnTop(true, "ahk_id" this._mruTile.data)
                WinSetAlwaysOnTop(false, "ahk_id" this._mruTile.data)
            }
        }

        _floatingRetile() {
            ; Do nothing
        }
    }

    __New(monitors, defaults) {
        this._workspaces := Map()
        this._defaults := defaults
        this.Update(monitors)
    }

    Count => this._workspaces.Length

    ToString() {
        return Stringify({
            Workspaces: this._workspaces,
            Count: this.Count,
        })
    }

    __Enum(numberOfVars) {
        return this._workspaces.__Enum(numberOfVars)
    }

    Update(monitors) {
        had := this._workspaces.Clone()
        for m in monitors {
            if had.Has(m.Handle) {
                for idx, ws in this._workspaces[m.handle] {
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
            workspaces := this._workspaces[monitor.handle]
            ws := workspaces.Get(index, 0)
            if !ws {
                ws := WorkspaceList.Workspace(monitor, index, ObjClone(this._defaults))
                workspaces[index] := ws
            }
            return ws
        }
    }
}
