class IVirtualDesktopManager_19044 extends IUnknown {
    Static GUID    := "{A5CD92FF-29BE-454C-8D04-D82879FB3F1B}"
    Static Methods := [
        "IsWindowOnCurrentVirtualDesktop",
        "GetWindowDesktopId",
        "MoveWindowToDesktop",
    ]

    IsWindowOnCurrentVirtualDesktop(hwnd) {
        ret := 0
        this._funcs["IsWindowOnCurrentVirtualDesktop"](
            "Ptr", hwnd,
            "IntP", &ret,
            "HRESULT",
        )
        Return ret > 0
    }

    GetWindowDesktopId(hwnd) {
        desktopId := Buffer(16)
        if this._funcs["GetWindowDesktopId"](
            "Ptr", hwnd,
            "Ptr", desktopId,
            "UInt",
        ) {
            Return false
        }
        Return StrGet(desktopId)
    }

    MoveWindowToDesktop(desktopId, hwnd) {
        this._funcs["MoveWindowToDesktop"](
            "Ptr", hwnd,
            "Ptr", desktopId,
            "HRESULT",
        )
    }
}
