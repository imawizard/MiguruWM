class IVirtualDesktopNotificationService_19044 extends IUnknown {
    Static GUID    := "{0CD45E71-D927-4F15-8B0A-8FEF525337BF}"
    Static Methods := [
        "Register",
        "Unregister",
    ]

    Register(handler) {
        cookie := 0
        this._funcs["Register"](
            "Ptr", handler,
            "IntP", &cookie,
            "HRESULT",
        )
        Return cookie
    }

    Unregister(cookie) {
        this._funcs["Unregister"](
            "Int", cookie,
            "HRESULT",
        )
    }
}
