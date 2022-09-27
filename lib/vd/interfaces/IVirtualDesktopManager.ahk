class IVirtualDesktopManager_19044 extends IUnknown {
    static GUID    := "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}"
    static Methods := [
        "IsWindowOnCurrentVirtualDesktop",
        "GetWindowDesktopId",
        "MoveWindowToDesktop",
    ]

    IsWindowOnCurrentVirtualDesktop(hwnd) {
        ret := 0
        this._funcs["IsWindowOnCurrentVirtualDesktop"](
            "Ptr", hwnd,
            "Int*", &ret,
            "HRESULT",
        )
        return ret > 0
    }

    GetWindowDesktopId(hwnd) {
        desktopId := Buffer(16)
        if this._funcs["GetWindowDesktopId"](
            "Ptr", hwnd,
            "Ptr", desktopId,
            "UInt",
        ) {
            return false
        }
        return StrGet(desktopId)
    }

    MoveWindowToDesktop(desktopId, hwnd) {
        this._funcs["MoveWindowToDesktop"](
            "Ptr", hwnd,
            "Ptr", desktopId,
            "HRESULT",
        )
    }
}
