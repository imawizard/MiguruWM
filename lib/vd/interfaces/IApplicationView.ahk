class IApplicationView_19044 extends IInspectable {
    static GUID    := "{372E1D3B-38D3-42E4-A15B-8AB2B178F513}"
    static Methods := [
        "SetFocus",
        "SwitchTo",
        "TryInvokeBack",
        "GetThumbnailWindow",
        "GetMonitor",
        "GetVisibility",
        "SetCloak",
        "GetPosition",
        "SetPosition",
        "InsertAfterWindow",
        "GetExtendedFramePosition",
        "GetAppUserModelId",
    ]

    SetFocus() {
        this._funcs["SetFocus"](
            "HRESULT",
        )
    }

    SwitchTo() {
        this._funcs["SwitchTo"](
            "HRESULT",
        )
    }

    TryInvokeBack(callback) {
        this._funcs["TryInvokeBack"](
            "Ptr", callback,
            "HRESULT",
        )
    }

    GetThumbnailWindow() {
        hwnd := 0
        this._funcs["GetThumbnailWindow"](
            "Ptr*", &hwnd,
            "HRESULT",
        )
        return hwnd
    }

    GetMonitor() {
        monitor := 0
        this._funcs["GetMonitor"](
            "Ptr*", &monitor,
            "HRESULT",
        )
        return monitor
    }

    GetVisibility() {
        visible := 0
        this._funcs["GetVisibility"](
            "Int*", &visible,
            "HRESULT",
        )
        return visible > 0
    }

    GetAppUserModelId() {
        appId := ""
        this._funcs["GetAppUserModelId"](
            "Str*", &appId,
            "UInt",
        )
        return appId
    }
}

class IApplicationView2_19044 extends IInspectable {
    static GUID    := "{7F25223A-79AD-4E72-A39A-6A194DD604C1}"
    static Methods := [
        "Unknown1",
        "Unknown2",
    ]

    Unknown1() {
        ret := 0
        this._funcs["Unknown1"](
            "Int*", &ret,
            "HRESULT",
        )
        return ret
    }

    Unknown2(param) {
        ret := 0
        this._funcs["Unknown2"](
            "Int", param,
            "Int*", &ret,
            "HRESULT",
        )
        return ret
    }
}
