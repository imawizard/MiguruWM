class IVirtualDesktopPinnedApps_19044 extends IUnknown {
    static GUID    := "{4CE81583-1E4C-4632-A621-07A53543148F}"
    static Methods := [
        "IsAppIdPinned",
        "PinAppID",
        "UnpinAppID",
        "IsViewPinned",
        "PinView",
        "UnpinView",
    ]

    IsAppIdPinned(appId) {
        ret := 0
        this._funcs["IsAppIdPinned"](
            "Str", appId,
            "Int*", &ret,
            "HRESULT",
        )
        return ret > 0
    }

    PinAppID(appId) {
        this._funcs["PinAppID"](
            "Str", appId,
            "HRESULT",
        )
    }

    UnpinAppID(appId) {
        this._funcs["UnpinAppID"](
            "Str", appId,
            "HRESULT",
        )
    }

    IsViewPinned(view) {
        ret := 0
        this._funcs["IsViewPinned"](
            "Ptr", view,
            "Int*", ret,
            "HRESULT",
        )
        return ret > 0
    }

    PinView(view) {
        this._funcs["PinView"](
            "Ptr", view,
            "HRESULT",
        )
    }

    UnpinView(view) {
        this._funcs["UnpinView"](
            "Ptr", view,
            "UInt",
            "HRESULT",
        )
    }
}
