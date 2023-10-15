CCHDEVICENAME        := 32
MONITORINFOF_PRIMARY := 1

MDT_EFFECTIVE_DPI := 0
MDT_ANGULAR_DPI   := 1
MDT_RAW_DPI       := 2
MDT_DEFAULT       := MDT_EFFECTIVE_DPI

MONITOR_DEFAULTTONULL    := 0
MONITOR_DEFAULTTOPRIMARY := 1
MONITOR_DEFAULTTONEAREST := 2

class MonitorList {
    class Monitor {
        __New(handle, name, dpi, area, workArea) {
            this._handle := handle
            this._index := 0
            this._name := name
            this._dpi := dpi
            this._area := area
            this._workArea := workArea
        }

        Handle   => this._handle
        Index    => this._index
        Name     => this._name
        DPI      => this._dpi
        Area     => this._area
        WorkArea => this._workArea

        ToString() {
            return Stringify(this)
        }

        Taskbar() {
            old := A_TitleMatchMode
            SetTitleMatchMode("RegEx")
            taskbars := WinGetList(
                "ahk_exe explorer.exe ahk_class ^Shell_(Secondary)?TrayWnd$"
            )
            SetTitleMatchMode(old)

            for hwnd in taskbars {
                x := 0, y := 0
                width := 0, height := 0
                v := hwnd

                RunDpiAware(() =>
                    WinGetPos(&x, &y, &width, &height, "ahk_id" v)
                )

                if x >= this._area.Left && x + width <= this._area.Right
                    && y >= this._area.Top && y + height <= this._area.Bottom {
                    return hwnd
                }
            }
            return ""
        }
    }

    class Rect {
        __New(left, top, right, bottom) {
            this._left := left
            this._top := top
            this._right := right
            this._bottom := bottom
        }

        static FromBuffer(buf, offset) {
            return this(
                NumGet(buf, offset +  0, "Int"),
                NumGet(buf, offset +  4, "Int"),
                NumGet(buf, offset +  8, "Int"),
                NumGet(buf, offset + 12, "Int"),
            )
        }

        Left    => this._left
        Top     => this._top
        Right   => this._right
        Bottom  => this._bottom
        Width   => this._right - this._left
        Height  => this._bottom - this._top
        CenterX => this._left + this.Width // 2
        CenterY => this._top + this.Height // 2
        Center  => { x: this.CenterX, y: this.CenterY }

        ToString() {
            return Stringify(this)
        }
    }

    __New() {
        this._monitors := []
        this._handles := Map()
        this._primary := ""

        this.Update()
    }

    Count   => this._monitors.Length
    Primary => this._monitors[this._handles[this._primary]]

    ToString() {
        return Type(this) "(" SubStr(Stringify({
            Monitors: this._monitors,
            Count: this.Count,
            Primary: this._handles[this._primary],
        }), 2, -1) ")"
    }

    __Enum(numberOfVars) {
        return this._monitors.__Enum(numberOfVars)
    }

    Update() {
        old := this._monitors

        monitors := qsort(
            MonitorList.QueryAll(),
            (a, b) => a.Area.Left - b.Area.Left,
        )

        handles := Map()
        for i, m in monitors {
            m._index := i
            handles[m.Handle] := i
        }

        pt := Buffer(8, 0)
        primary := DllCall(
            "MonitorFromPoint",
            "Ptr", pt,
            "UInt", MONITOR_DEFAULTTOPRIMARY,
            "Ptr",
        )

        this._monitors := monitors
        this._handles := handles
        this._primary := primary
        return old
    }

    static QueryAll() {
        b := MonitorList._enumProc.Bind(MonitorList)
        callback := CallbackCreate(b, , 4)
        monitors := []
        DllCall(
            "EnumDisplayMonitors",
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", callback,
            "Ptr", ObjPtr(monitors),
            "UInt",
        )
        CallbackFree(callback)
        return monitors
    }

    static _enumProc(handle, dc, rect, lparam) {
        monitors := ObjFromPtrAddRef(lparam)

        size := 4 + (4 * 4) * 2 + 4
        info := Buffer(size + 2 * CCHDEVICENAME)
        NumPut("UInt", info.Size, info)

        monitorDPI := 0
        RunDpiAware(() => (
            DllCall(
                "GetMonitorInfo",
                "Ptr", handle,
                "Ptr", info,
                "Int",
            ),
            DllCall(
                "shcore.dll\GetDpiForMonitor",
                "Ptr", handle,
                "UInt", MDT_EFFECTIVE_DPI,
                "UInt*", &monitorDPI,
                "UInt*", 0,
                "HRESULT",
            ))
        )

        monitors.Push(MonitorList.Monitor(
            handle,
            StrGet(info.Ptr + size, CCHDEVICENAME),
            monitorDPI,
            MonitorList.Rect.FromBuffer(info, 4),
            MonitorList.Rect.FromBuffer(info, 20),
        ))
        return true
    }

    Has(monitor) {
        return this._handles.Has(monitor.Handle)
    }

    ByIndex(index) {
        return this._monitors[index]
    }

    ByHandle(handle) {
        return this._monitors[this._handles[handle]]
    }

    ByWindow(hwnd) {
        handle := DllCall(
            "MonitorFromWindow",
            "Ptr", hwnd,
            "UInt", MONITOR_DEFAULTTOPRIMARY,
            "Ptr",
        )
        if !this._handles.Has(handle) {
            warn("Monitor handle #{} for window #{} isn't mapped."
                " Returning primary monitor instead.",
                hwnd, handle)
            return this.Primary
        }
        return this._monitors[this._handles[handle]]
    }
}
