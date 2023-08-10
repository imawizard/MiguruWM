class HazeOver {
    __New(opts := {}) {
        opts := ObjMerge({
            color: "0x080808",
            transparency: 55,
        }, opts)

        this._guis := Map()
        this.Color := opts.color
        this.Transparency := opts.transparency
    }

    __Delete() {
        this._destroyGuis()
    }

    _destroyGuis() {
        for , v in this._guis {
            v.Destroy()
        }
        this._guis := Map()
    }

    HideWhenPositioning {
        get => false
    }

    ShowOnFocusRequest {
        get => true
    }

    UpdateOnRetile {
        get => false
    }

    SetMonitorList(monitors) {
        RunDpiAware(() => this._setMonitorList(monitors))
    }

    _setMonitorList(monitors) {
        this._monitors := monitors
        this._destroyGuis()

        for m in monitors {
            g := Gui(
                " +ToolWindow"
                " +E" WS_EX_NOACTIVATE
                " +E" WS_EX_CLICKTHROUGH
                " -Caption"
                " -SysMenu"
            )

            g.BackColor := this._color
            WinSetTransparent(this._transparency, g.Hwnd)

            g.Show("Hide")
            DllCall(
                "SetWindowPos",
                "Ptr", g.Hwnd,
                "Ptr", HWND_TOP,
                "Int", m.WorkArea.Left,
                "Int", m.WorkArea.Top,
                "Int", m.WorkArea.Width,
                "Int", m.WorkArea.Height,
                "UInt", SWP_NOACTIVATE,
                "Int",
            )

            this._guis[m.Handle] := g
        }
    }

    Color {
        get => this._color
        set {
            for , v in this._guis {
                v.BackColor := value
            }
            this._color := value
        }
    }

    Transparency {
        get => this._transparency
        set {
            for , v in this._guis {
                WinSetTransparent(value, v.Hwnd)
            }
            this._transparency := value
        }
    }

    Show(hwnd) {
        try RunDpiAware(() => this._show(hwnd))
    }

    _show(hwnd) {
        if !hwnd {
            return
        }

        exstyle := WinGetExStyle("ahk_id" hwnd)
        if exstyle & WS_EX_TOPMOST == 0 {
            WinSetAlwaysOnTop(true, "ahk_id" hwnd)
            WinSetAlwaysOnTop(false, "ahk_id" hwnd)
        }

        monitor := this._monitors.ByWindow(hwnd)
        DllCall(
            "SetWindowPos",
            "Ptr", this._guis[monitor.Handle].Hwnd,
            "Ptr", hwnd,
            "Int", 0,
            "Int", 0,
            "Int", 0,
            "Int", 0,
            "UInt", SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOSIZE | SWP_NOMOVE,
            "Int",
        )

        for m in this._monitors {
            if m != monitor {
                DllCall(
                    "SetWindowPos",
                    "Ptr", this._guis[m.Handle].Hwnd,
                    "Ptr", HWND_TOP,
                    "Int", 0,
                    "Int", 0,
                    "Int", 0,
                    "Int", 0,
                    "UInt", SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_NOSIZE | SWP_NOMOVE,
                    "Int",
                )
            }
        }
    }

    Hide() {
        try RunDpiAware(() => this._hide())
    }

    _hide() {
        for , v in this._guis {
            v.Show("Hide")
        }
    }

    Unmanaged(hwnd) {
        if WinExist("ahk_id" hwnd " ahk_class Shell_TrayWnd")
            || WinExist("ahk_id" hwnd " ahk_class Shell_SecondaryTrayWnd") {
            monitor := this._monitors.ByWindow(hwnd)
            RunDpiAware(() => this._guis[monitor.Handle].Show("Hide"))

            for m in this._monitors {
                if m != monitor {
                    WinSetAlwaysOnTop(true, "ahk_id" this._guis[m.Handle].Hwnd)
                    WinSetAlwaysOnTop(false, "ahk_id" this._guis[m.Handle].Hwnd)
                }
            }
        } else if WinExist("ahk_id" hwnd " ahk_class Progman")
            || (WinExist("ahk_id" hwnd " ahk_class WorkerW")
            && WinGetTitle("ahk_id" hwnd) == "") {
            this.Hide()
        } else {
            this.Show(hwnd)
        }
    }
}
