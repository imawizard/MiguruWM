class IVirtualDesktopPinnedApps_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{4CE81583-1E4C-4632-A621-07A53543148F}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "IsAppIdPinned"
                , "PinAppID"
                , "UnpinAppID"
                , "IsViewPinned"
                , "PinView"
                , "UnpinView")
        }
    }

    IsAppIdPinned(appId) {
        ret := 0
        DllCall(this.methods["IsAppIdPinned"]
            , "Ptr", this.ptr
            , "Str", appId
            , "IntP", ret
            , "UInt")
        Return ret > 0
    }

    PinAppID(appId) {
         Return DllCall(this.methods["PinAppID"]
            , "Ptr", this.ptr
            , "Str", appId
            , "UInt") == 0
    }

    UnpinAppID(appId) {
         Return DllCall(this.methods["UnpinAppID"]
            , "Ptr", this.ptr
            , "Str", appId
            , "UInt") == 0
    }

    IsViewPinned(view) {
        ret := 0
        DllCall(this.methods["IsViewPinned"]
            , "Ptr", this.ptr
            , "Ptr", view
            , "IntP", ret
            , "UInt")
        Return ret > 0
    }

    PinView(view) {
         Return DllCall(this.methods["PinView"]
            , "Ptr", this.ptr
            , "Ptr", view
            , "UInt") == 0
    }

    UnpinView(view) {
         Return DllCall(this.methods["UnpinView"]
            , "Ptr", this.ptr
            , "Ptr", view
            , "UInt") == 0
    }
}
