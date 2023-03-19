AW_HOR_POSITIVE := 0x00000001
AW_HOR_NEGATIVE := 0x00000002
AW_VER_POSITIVE := 0x00000004
AW_VER_NEGATIVE := 0x00000008
AW_CENTER       := 0x00000010
AW_HIDE         := 0x00010000
AW_ACTIVATE     := 0x00020000
AW_SLIDE        := 0x00040000
AW_BLEND        := 0x00080000

WM_LBUTTONDOWN := 0x201

;; Adapted from https://github.com/sdias/win-10-virtual-desktop-enhancer/blob/master/libraries/tooltip.ahk
class Popup {
    static active := Map()

    __New(message, opts := {}) {
        o := Map()
        for k, v in opts.OwnProps() {
            o[k] := v
        }

        fontSize          := o.Get("fontSize",          18)
        fontWeight        := o.Get("fontWeight",        700)
        fontColor         := o.Get("fontColor",         "0xffffff")
        backgroundColor   := o.Get("backgroundColor",   "0x1f1f1f")
        duration          := o.Get("duration",          1000)
        horzPadding       := o.Get("horzPadding",       100)
        vertPadding       := o.Get("vertPadding",       60)
        activeMonitor     := o.Get("activeMonitor",     MonitorGetPrimary())
        showOnAllMonitors := o.Get("showOnAllMonitors", false)
        closeOtherPopups  := o.Get("closeOtherPopups",  true)

        if (closeOtherPopups) {
            for k, v in Popup.active {
                v.Call()
            }
        }

        monitors := [activeMonitor]
        if showOnAllMonitors {
            loop MonitorGetCount() {
                if A_Index !== activeMonitor {
                    monitors.Push(A_Index)
                }
            }
        }

        this.guis := []
        for monitor in monitors {
            g := Gui("+ToolWindow +AlwaysOnTop -Caption")
            this.guis.Push(g)

            g.BackColor := backgroundColor
            fontOpt := Format("s{} c{} w{}", fontSize, fontColor, fontWeight)
            g.SetFont(fontOpt, "Segoe UI")
            msg := g.Add("Text", , message)

            ;; Create window hidden to get text width and height.
            g.Show("Hide")

            ;; Resize window to message plus padding.
            msg.GetPos(, , &msgWidth, &msgHeight)
            guiWidth := msgWidth + horzPadding
            guiHeight := msgHeight + vertPadding
            g.Move(, , guiWidth, guiHeight)

            ;; Center message within window.
            msg.Move(
                (guiWidth - msgWidth) / 2 - 1,
                (guiHeight - msgHeight) / 2 - 1,
            )

            ;; Center window with WinGetPos and Show, because GetPos and Move
            ;; are DPI-scaled.
            MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
            WinGetPos(, , &guiWidth, &guiHeight, "ahk_id" g.Hwnd)
            centerX := (right + left - guiWidth) / 2
            centerY := (bottom + top - guiHeight) / 2
            g.Show(Format("Hide X{} Y{}", centerX, centerY))

            DllCall(
                "AnimateWindow",
                "Ptr", g.Hwnd,
                "Int", 50,
                "UInt", AW_BLEND,
                "Int",
            )
        }

        this.clickCb := this.LButtonDown.Bind(this)
        OnMessage(WM_LBUTTONDOWN, this.clickCb)

        this.closeCb := this.close.Bind(this)
        SetTimer(this.closeCb, -duration)

        Popup.active[this] := this.closeCb
    }

    LButtonDown(wParam, lParam, msg, hwnd) {
        for g in this.guis {
            if hwnd == g.Hwnd {
                this.close()
                return
            }
        }
    }

    close() {
        SetTimer(this.closeCb, 0)
        OnMessage(WM_LBUTTONDOWN, this.clickCb, 0)

        Popup.active.Delete(this)

        for g in this.guis {
            DllCall(
                "AnimateWindow",
                "Ptr", g.Hwnd,
                "Int", 100,
                "UInt", AW_BLEND | AW_HIDE,
                "Int",
            )
            g.Destroy()
        }
    }
}
