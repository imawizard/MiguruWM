class FocusIndicator {
    __New(opts := {}) {
        opts := ObjMerge({
            color: "0xff0000",
            thickness: 2,
            inlay: "alwaysOnTop",
        }, opts)

        this._gui := Gui(
            " +ToolWindow"
            " +E" WS_EX_NOACTIVATE
            " +E" WS_EX_CLICKTHROUGH
            " -Caption"
            " -SysMenu"
        )

        this.Color := opts.color
        this._thickness := opts.thickness
        this._inlay := opts.inlay
    }

    __Delete() {
        this._gui.Destroy()
    }

    HideWhenPositioning {
        get => true
    }

    ShowOnFocusRequest {
        get => this._inlay !== true
    }

    SetMonitorList(monitors) {
        ;; Do nothing
    }

    Color {
        get => this._gui.BackColor
        set => this._gui.BackColor := value
    }

    Show(hwnd) {
        RunDpiAware(() => this._show(hwnd))
    }

    _show(hwnd) {
        if !hwnd {
            return
        }

        WinGetPos(&left, &top, &width, &height, "ahk_id" hwnd)
        bounds := ExtendedFrameBounds(hwnd)

        x := left + bounds.left
        y := top + bounds.top
        width := width - bounds.left - bounds.right
        height := height - bounds.top - bounds.bottom

        if width < 0 || height < 0 {
            return
        } else if !this._inlay {
            x -= this._thickness
            y -= this._thickness
            width += this._thickness * 2
            height += this._thickness * 2
        }

        xa := this._thickness
        ya := this._thickness
        xb := width - xa
        yb := height - ya

        WinSetRegion(
            Format(
                "0-0 {}-0 {}-{} 0-{} 0-0 "
                "{}-{} {}-{} {}-{} {}-{} {}-{} ",
                width, width, height, height,
                xa, ya, xb, ya, xb, yb, xa, yb, xa, ya,
            ),
            "ahk_id" this._gui.Hwnd,
        )

        DllCall(
            "SetWindowPos",
            "Ptr", this._gui.Hwnd,
            "Ptr", this._inlay == "alwaysOnTop" ? HWND_TOPMOST : hwnd,
            "Int", x,
            "Int", y,
            "Int", width,
            "Int", height,
            "UInt", SWP_SHOWWINDOW | SWP_NOACTIVATE,
            "Int",
        )

        if this._inlay == true {
            DllCall(
                "SetWindowPos",
                "Ptr", hwnd,
                "Ptr", this._gui.Hwnd,
                "Int", 0,
                "Int", 0,
                "Int", 0,
                "Int", 0,
                "UInt", SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_NOCOPYBITS | SWP_NOSENDCHANGING,
                "Int",
            )
        }
    }

    Hide() {
        RunDpiAware(() => this._gui.Show("Hide"))
    }

    Unmanaged(hwnd) {
        if WinExist("ahk_id" hwnd " ahk_class Shell_TrayWnd")
            || WinExist("ahk_id" hwnd " ahk_class Shell_SecondaryTrayWnd")
            || WinExist("ahk_id" hwnd " ahk_class Progman")
            || (WinExist("ahk_id" hwnd " ahk_class WorkerW")
            && WinGetTitle("ahk_id" hwnd) == "") {
            this.Hide()
        } else {
            this.Show(hwnd)
        }
    }
}
