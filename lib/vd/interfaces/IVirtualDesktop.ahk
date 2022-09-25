class IVirtualDesktop_19044 extends IUnknown {
    Static GUID    := "{FF72FFDD-BE7E-43FC-9C03-AD81681E88E4}"
    Static Methods := [
        "IsViewVisible",
        "GetId",
    ]

    IsViewVisible(view) {
        ret := 0
        this._funcs["IsViewVisible"](
            "Ptr", view,
            "IntP", &ret,
            "HRESULT",
        )
        Return ret > 0
    }

    GetId() {
        desktopId := Buffer(16)
        this._funcs["GetId"](
            "Ptr", desktopId,
            "HRESULT",
        )
        Return StrGet(desktopId)
    }
}

class IVirtualDesktop2_19044 extends IVirtualDesktop_19044 {
    Static GUID    := "{31EBDE3F-6EC3-4CBD-B9FB-0EF6D09B41F4}"
    Static Methods := [
        "GetName",
    ]

    GetName() {
        hstr := 0
        this._funcs["GetName"](
            "PtrP", &hstr,
            "HRESULT",
        )
        if !hstr {
            Return ""
        }
        len := 0
        str := DllCall(
            "combase\WindowsGetStringRawBuffer",
            "Ptr", hstr,
            "UIntP", &len,
            "Ptr",
        )
        Return StrGet(str)
    }
}

class IVirtualDesktop_22000 extends IVirtualDesktop2_19044 {
    Static GUID    := "{536D3495-B208-4CC9-AE26-DE8111275BF8}"
    Static Methods := [
        "Unknown1",
        "GetName",
        "GetWallpaperPath",
    ]

    GetWallpaperPath() {
        hstr := 0
        this._funcs["GetWallpaperPath"](
            "PtrP", &hstr,
            "HRESULT",
        )
        if !hstr {
            Return ""
        }
        len := 0
        str := DllCall(
            "combase\WindowsGetStringRawBuffer"
            "Ptr", hstr,
            "UIntP", &len,
            "Ptr",
        )
        Return StrGet(str)
    }
}
