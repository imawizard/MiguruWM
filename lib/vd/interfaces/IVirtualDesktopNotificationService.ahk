class IVirtualDesktopNotificationService_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{0CD45E71-D927-4F15-8B0A-8FEF525337BF}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "Register"
                , "Unregister")
        }
    }

    Register(handler) {
        cookie := 0
        if DllCall(this.methods["Register"]
            , "Ptr", this.ptr
            , "Ptr", handler
            , "IntP", cookie
            , "UInt") {
            Return false
        }
        Return cookie
    }

    Unregister(cookie) {
        Return DllCall(this.methods["Unregister"]
            , "Ptr", this.ptr
            , "Int", cookie
            , "UInt") == 0
    }
}
