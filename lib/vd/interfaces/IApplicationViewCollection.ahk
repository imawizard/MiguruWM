class IApplicationViewCollection_19044 extends IUnknown {
    static GUID    := "{1841C6D7-4F9D-42C0-AF41-8747538F10E5}"
    static Methods := [
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
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetViewsByZOrder(out) {
        this._funcs["GetViewsByZOrder"](
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetViewsByAppUserModelId(out, modelId) {
        this._funcs["GetViewsByAppUserModelId"](
            "Ptr", modelId,
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetViewForHwnd(out, hwnd) {
        res := this._funcs["GetViewForHwnd"](
            "Ptr", hwnd,
            "Ptr*", out,
            "UInt",
        )
        switch res {
        case E_ELEMENTNOTFOUND:
        }
    }

    GetViewForAppUserModelId(out, modelId) {
        this._funcs["GetViewForAppUserModelId"](
            "Ptr", modelId,
            "Ptr*", out,
            "HRESULT",
        )
    }

    GetViewInFocus(out) {
        this._funcs["GetViewInFocus"](
            "Ptr*", out,
            "HRESULT",
        )
    }

    Unknown1(out) {
        this._funcs["Unknown1"](
            "Ptr*", out,
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
            "Int*", &cookie,
            "HRESULT",
        )
        return cookie
    }

    UnregisterForApplicationViewChanges(cookie) {
        this._funcs["UnregisterForApplicationViewChanges"](
            "Int", cookie,
            "HRESULT",
        )
    }
}
