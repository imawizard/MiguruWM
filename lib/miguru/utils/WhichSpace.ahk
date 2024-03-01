#include ..\..\gdi.ahk

class WhichSpace {
    __New(opts := {}) {
        opts := ObjMerge({
            color: "0x080808",
        }, opts)

        this._monitorCount := 0
        this._monitorIdx := -1
        this._wsCount := 0
        this._wsIdx := -1

        this._createIcons()
    }

    __Delete() {
        this._deleteIcons(this._leftIcons)
        this._deleteIcons(this._rightIcons)
        this._deleteIcons(this._midIcons)
    }

    _deleteIcons(icons) {
        for icon in icons {
            DllCall(
                "DestroyIcon",
                "Ptr", icon,
                "Int",
            )
        }
    }

    _createIcons() {
        this._leftIcons := []
        this._rightIcons := []
        this._midIcons := []

        digit := 1
        while digit <= 9 {
            loop 3 {
                bitmap := GdiBitmap(32, 32)
                font := GdiFont("Times New Roman", 24)
                bitmap.Canvas.RoundedRectangle(0, 0, 32, 32, 12, GdiPen(0xffffffff), GdiBrush(0xffffffff))
                bitmap.Canvas.Text(digit, 0, 0, bitmap.Width, bitmap.Height, font, GdiPen(0xff000000), GdiBrush(0xff000000))

                switch A_Index {
                case 1:
                    dest := this._leftIcons
                    bitmap.Canvas.Arc(0, 0, 5, 5, 0, 360, GdiPen(0), GdiBrush(0xffff0000))
                case 2:
                    dest := this._rightIcons
                    bitmap.Canvas.Arc(0, 0, 5, 5, 0, 360, GdiPen(0), GdiBrush(0xffff0000))
                case 3:
                    dest := this._midIcons
                    bitmap.Canvas.Arc(0, bitmap.Height / 2 - 10 / 2 - 1, 10, 10, 0, 360, GdiPen(0xffff0000), GdiBrush(0xffff0000))
                }

                dest.Push(bitmap.ToIcon())
            }
            digit++
        }
    }

    MonitorChanged(idx) {
        this._monitorIdx := idx
        this._update()
    }

    MonitorCountChanged(count) {
        this._monitorCount := count
        this._update()
    }

    WorkspaceChanged(ws) {
        this._wsIdx := ws.Index
        this._update()
    }

    WorkspaceCountChanged(count) {
        this._wsCount := count
        this._update()
    }

    LayoutChanged(ws) {
        ;; Do nothing
    }

    _update() {
        ; monitorMax := MonitorGetCount()
        if this._monitorCount > 1 && this._monitorIdx == 1 {
            icon := this._leftIcons[this._wsIdx]
        } else if this._monitorCount > 1 && this._monitorIdx == this._monitorCount {
            icon := this._rightIcons[this._wsIdx]
        } else {
            icon := this._midIcons[this._wsIdx]
        }

        copy := DllCall(
            "CopyIcon",
            "Ptr", icon,
            "Ptr",
        )
        TraySetIcon("HICON:" copy, , true)
    }
}
