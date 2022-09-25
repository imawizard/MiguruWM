class IApplicationView_19044 extends IInspectable {
    Static GUID    := "{372E1D3B-38D3-42E4-A15B-8AB2B178F513}"
    Static Methods := [
        "SetFocus",
        "SwitchTo",
        "TryInvokeBack",
        "GetThumbnailWindow",
        "GetMonitor",
        "GetVisibility",
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
            "PtrP", &hwnd,
            "HRESULT",
        )
        Return hwnd
    }

    GetMonitor() {
        monitor := 0
        this._funcs["GetMonitor"](
            "PtrP", &monitor,
            "HRESULT",
        )
        Return monitor
    }

    GetVisibility() {
        visible := 0
        this._funcs["GetVisibility"](
            "IntP", &visible,
            "HRESULT",
        )
        Return visible > 0
    }
}

class IApplicationView2_19044 extends IInspectable {
    Static GUID    := "{7F25223A-79AD-4E72-A39A-6A194DD604C1}"
    Static Methods := [
        "Unknown1",
        "Unknown2",
    ]

    Unknown1() {
        ret := 0
        this._funcs["Unknown1"](
            "IntP", &ret,
            "HRESULT",
        )
        Return ret
    }

    Unknown2(param) {
        ret := 0
        this._funcs["Unknown2"](
            "Int", param,
            "IntP", &ret,
            "HRESULT",
        )
        Return ret
    }
}
