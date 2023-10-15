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
        transparency      := o.Get("transparency",      255)
        duration          := o.Get("duration",          1000)
        horzPadding       := o.Get("horzPadding",       80)
        vertPadding       := o.Get("vertPadding",       40)
        showIcon          := o.Get("showIcon",          false)
        activeMonitor     := o.Get("activeMonitor",     MonitorGetPrimary())
        showOnAllMonitors := o.Get("showOnAllMonitors", false)
        closeOtherPopups  := o.Get("closeOtherPopups",  true)

        if (closeOtherPopups) {
            for k, v in Popup.active {
                v.Call()
            }
        }

        if !message {
            return
        }

        monitors := [activeMonitor]
        if showOnAllMonitors {
            loop MonitorGetCount() {
                if A_Index !== activeMonitor {
                    monitors.Push(A_Index)
                }
            }
        }

        if transparency == 255 {
            this.anim := AW_BLEND
        } else {
            this.anim := AW_CENTER
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

            if showIcon {
                file := A_IconFile
                if !file {
                    path := RegExReplace(A_ScriptFullPath, "i)\.ahk$", ".exe")
                    if FileExist(path) {
                        file := path
                    }
                }
                if file {
                    icon := g.Add("Picture", "Icon1", file)
                    icon.GetPos(, , &iconWidth, &iconHeight)
                }
            } else {
                icon := ""
                iconWidth := 0
                iconHeight := 0
            }

            ;; Resize window to message plus padding.
            msgX := Max(horzPadding // 2 + iconWidth / 1.5, horzPadding // 4 + iconWidth)
            msg.GetPos(, , &msgWidth, &msgHeight)
            guiWidth := msgWidth + horzPadding + iconWidth // 2
            if msgX + msgWidth > guiWidth {
                guiWidth := msgX + msgWidth + horzPadding // 2
            }
            guiHeight := Max(msgHeight, iconHeight) + vertPadding
            g.Move(, , guiWidth, guiHeight)

            ;; Center message within window.
            msg.Move(
                msgX,
                (guiHeight - msgHeight) // 2,
            )

            if icon {
                icon.Move(
                    horzPadding / 4.5,
                    (guiHeight - iconHeight) // 2,
                )
            }

            ;; Center window with WinGetPos and Show, because GetPos and Move
            ;; are DPI-scaled.
            MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)
            WinGetPos(, , &guiWidth, &guiHeight, "ahk_id" g.Hwnd)
            centerX := (right + left - guiWidth) // 2
            centerY := (bottom + top - guiHeight) // 2
            g.Show(Format("Hide X{} Y{}", centerX, centerY))

            if transparency < 255 {
                WinSetTransparent(transparency, "ahk_id" g.Hwnd)
            }

            DllCall(
                "AnimateWindow",
                "Ptr", g.Hwnd,
                "Int", 50,
                "UInt", this.anim,
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
                "UInt", this.anim | AW_HIDE,
                "Int",
            )
            g.Destroy()
        }
    }
}
