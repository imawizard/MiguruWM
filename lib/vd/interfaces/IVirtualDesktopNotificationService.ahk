class IVirtualDesktopNotificationService_19044 extends IUnknown {
    static GUID    := "{0CD45E71-D927-4F15-8B0A-8FEF525337BF}"
    static Methods := [
        "Register",
        "Unregister",
    ]

    Register(handler) {
        cookie := 0
        this._funcs["Register"](
            "Ptr", handler,
            "Int*", &cookie,
            "HRESULT",
        )
        return cookie
    }

    Unregister(cookie) {
        this._funcs["Unregister"](
            "Int", cookie,
            "HRESULT",
        )
    }
}
