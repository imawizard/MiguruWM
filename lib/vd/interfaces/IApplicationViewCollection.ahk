class IApplicationViewCollection_19044 extends IUnknown {
    Static GUID    := "{1841C6D7-4F9D-42C0-AF41-8747538F10E5}"
    Static Methods := [
        "GetViews",
        "GetViewsByZOrder",
        "GetViewsByAppUserModelId",
        "GetViewForHwnd",
        "GetViewForApplication",
        "GetViewForAppUserModelId",
        "GetViewInFocus",
        "Unknown1",
        "RefreshCollection",
        "RegisterForApplicationViewChanges",
        "UnregisterForApplicationViewChanges",
    ]

    GetViews(out) {
        this._funcs["GetViews"](
            "PtrP", out,
            "HRESULT",
        )
    }

    GetViewsByZOrder(out) {
        this._funcs["GetViewsByZOrder"](
            "PtrP", out,
            "HRESULT",
        )
    }

    GetViewsByAppUserModelId(out, modelId) {
        this._funcs["GetViewsByAppUserModelId"](
            "Ptr", modelId,
            "PtrP", out,
            "HRESULT",
        )
    }

    GetViewForHwnd(out, hwnd) {
        res := this._funcs["GetViewForHwnd"](
            "Ptr", hwnd,
            "PtrP", out,
            "UInt",
        )
        Switch res {
        Case E_ELEMENTNOTFOUND:
        }
    }

    GetViewForAppUserModelId(out, modelId) {
        this._funcs["GetViewForAppUserModelId"](
            "Ptr", modelId,
            "PtrP", out,
            "HRESULT",
        )
    }

    GetViewInFocus(out) {
        this._funcs["GetViewInFocus"](
            "PtrP", out,
            "HRESULT",
        )
    }

    Unknown1(out) {
        this._funcs["Unknown1"](
            "PtrP", out,
            "HRESULT",
        )
    }

    RefreshCollection() {
        this._funcs["RefreshCollection"](
            "HRESULT",
        )
    }

    RegisterForApplicationViewChanges(handler) {
        cookie := 0
        this._funcs["RegisterForApplicationViewChanges"](
            "Ptr", handler,
            "IntP", &cookie,
            "HRESULT",
        )
        Return cookie
    }

    UnregisterForApplicationViewChanges(cookie) {
        this._funcs["UnregisterForApplicationViewChanges"](
            "Int", cookie,
            "HRESULT",
        )
    }
}
