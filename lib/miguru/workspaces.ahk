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

class WorkspaceList {
    class Workspace {
        __New(monitor, index) {
            this._monitor := monitor
            this._index := index
            this._windows := Map()
            this._tiled := CircularList()
            this._mruTile := ""
            this._layout := ""
            this._masterCount := 0
            this._masterSize := 0
            this._padding := 0
            this._spacing := 0
        }

        Monitor    => this._monitor
        Index      => this._index
        TileCount  => this._tiled.Count
        MruTile    => this._mruTile

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
            get => this._layout
            set {
                this._layout := value
                this._retile := Map(
                    "tall",       this._tallRetile,
                    "wide",       this._wideRetile,
                    "fullscreen", this._fullscreenRetile,
                    "floating",   this._floatingRetile,
                )[this._layout]
                this.Retile()
            }
        }

        ActiveWindow {
            get => this._mruTile ? this._mruTile.data : ""
            set {
                entry := this._windows.Get(value, "")
                if entry {
                    this._mruTile := entry.node
                }
            }
        }

        Appear(hwnd) {
            if this._windows.Has(hwnd) {
                return false
            }

            this._mruTile := this._tiled.Prepend(hwnd, this._mruTile)
            this._windows[hwnd] := { node: this._mruTile }
            this.Retile()
            return true
        }

        Disappear(hwnd, focus := true) {
            entry := this._windows.Get(hwnd, "")
            if !entry {
                return false
            }

            wasLast := this._tiled.Last == entry.node
            this._windows.Delete(hwnd)
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
        }

        Focus(target) {
            if this._tiled.Count < 1 {
                return
            }

            tile := ""
            switch target {
            case "next":
                tile := this._mruTile.next
            case "previous":
                tile := this._mruTile.previous
            case "master":
                tile := this._tiled.First
            }
            if tile {
                WinActivate("ahk_id" tile.data)
                this._mruTile := tile
                if this._layout == "fullscreen" {
                    this.Retile()
                }
            }
        }

        Swap(target) {
            if this._tiled.Count < 2 || this._layout == "fullscreen" {
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
            get => this._masterCount
            set {
                if value >= 0 && value <= 6 {
                    this._masterCount := value
                    this.Retile()
                }
            }
        }

        MasterSize {
            get => Round(this._masterSize / 100, 2)
            set {
                if value >= 0.0 && value <= 1.0 {
                    this._masterSize := Round(value * 100)
                    this.Retile()
                }
            }
        }

        Padding {
            get => this._padding // 2
            set {
                if value >= 0 {
                    this._padding := Integer(value) * 2
                    this.Retile()
                }
            }
        }

        Spacing {
            get => this._spacing // 2
            set {
                if value >= 0 {
                    this._spacing := Integer(value) * 2
                    this.Retile()
                }
            }
        }

        Retile() {
            if !this._tiled.First {
                return
            }

            debug("Retiling ({}, {}) tiles={} layout={}",
                this._monitor.Index, this._index, this._tiled.Count, this._layout)

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
            masterCount := Min(this._masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            if masterCount >= 1 && slaveCount >= 1 {
                masterWidth := Round(workArea.Width * this._masterSize / 100)
                firstSlave := this._tallRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + this._padding,
                    workArea.top + this._padding,
                    masterWidth - this._padding - this._spacing // 2,
                    workArea.Height - 2 * this._padding,
                )

                slaveWidth := workArea.Width - masterWidth
                this._tallRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + masterWidth + this._spacing // 2,
                    workArea.top + this._padding,
                    slaveWidth - this._padding - this._spacing // 2,
                    workArea.Height - 2 * this._padding,
                )
            } else {
                this._tallRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + this._padding,
                    workArea.top + this._padding,
                    workArea.Width - 2 * this._padding,
                    workArea.Height - 2 * this._padding,
                )
            }
        }

        _tallRetilePane(tile, count, x, startY, totalWidth, totalHeight) {
            spacing := this._spacing > 0 && count > 1 ? this._spacing // 2 : 0
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
            masterCount := Min(this._masterCount, this._tiled.Count)
            slaveCount := this._tiled.Count - masterCount
            workArea := this._monitor.WorkArea

            if masterCount >= 1 && slaveCount >= 1 {
                masterHeight := Round(workArea.Height * this._masterSize / 100)
                firstSlave := this._wideRetilePane(
                    this._tiled.First,
                    masterCount,
                    workArea.left + this._padding,
                    workArea.top + this._padding,
                    workArea.Width - 2 * this._padding,
                    masterHeight - this._padding - this._spacing // 2,
                )

                slaveHeight := workArea.Height - masterHeight
                this._wideRetilePane(
                    firstSlave,
                    slaveCount,
                    workArea.left + this._padding,
                    workArea.top + masterHeight + this._spacing // 2,
                    workArea.Width - 2 * this._padding,
                    slaveHeight - this._padding - this._spacing // 2,
                )
            } else {
                this._wideRetilePane(
                    this._tiled.First,
                    masterCount || this._tiled.Count,
                    workArea.left + this._padding,
                    workArea.top + this._padding,
                    workArea.Width - 2 * this._padding,
                    workArea.Height - 2 * this._padding,
                )
            }
        }

        _wideRetilePane(tile, count, startX, y, totalWidth, totalHeight) {
            spacing := this._spacing > 0 && count > 1 ? this._spacing // 2 : 0
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
                workArea := this._monitor.WorkArea
                this._tallRetilePane(
                    this._mruTile,
                    1,
                    workArea.left + this._padding,
                    workArea.top + this._padding,
                    workArea.Width - 2 * this._padding,
                    workArea.Height - 2 * this._padding,
                )

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
                ws := WorkspaceList.Workspace(monitor, index)
                ws.Layout := this._defaults.layout
                ws.MasterCount := this._defaults.masterCount
                ws.MasterSize := this._defaults.masterSize
                ws.Padding := this._defaults.padding
                ws.Spacing := this._defaults.spacing
                workspaces[index] := ws
            }
            return ws
        }
    }
}
