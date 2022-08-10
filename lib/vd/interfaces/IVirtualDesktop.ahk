class IVirtualDesktop_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{FF72FFDD-BE7E-43FC-9C03-AD81681E88E4}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "IsViewVisible"
                , "GetId")
        }
    }

    IsViewVisible(view) {
        ret := 0
        DllCall(this.methods["IsViewVisible"]
            , "Ptr", this.ptr
            , "Ptr", view.ptr
            , "IntP", ret
            , "UInt")
        Return ret > 0
    }

    GetId() {
        VarSetCapacity(desktopId, 16)
        if DllCall(this.methods["GetId"]
            , "Ptr", this.ptr
            , "Ptr", &desktopId
            , "UInt") {
            Return false
        }
        Return desktopId
    }
}

class IVirtualDesktop2_19044 extends IVirtualDesktop_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{31EBDE3F-6EC3-4CBD-B9FB-0EF6D09B41F4}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "IsViewVisible"
                , "GetId"
                , "GetName")
        }
    }

    GetName() {
        hstr := 0
        if DllCall(this.methods["GetName"]
            , "Ptr", this.ptr
            , "PtrP", hstr
            , "UInt") || !hstr {
            Return ""
        }
        len := 0
        str := DllCall("combase\WindowsGetStringRawBuffer"
            , "Ptr", hstr
            , "UIntP", len
            , "Ptr")
        Return StrGet(str)
    }
}

class IVirtualDesktop_22000 extends IVirtualDesktop2_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{536D3495-B208-4CC9-AE26-DE8111275BF8}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "IsViewVisible"
                , "GetId"
                , "Unknown1"
                , "GetName"
                , "GetWallpaperPath")
        }
    }

    GetWallpaperPath() {
        hstr := 0
        if DllCall(this.methods["GetWallpaperPath"]
            , "Ptr", this.ptr
            , "PtrP", hstr
            , "UInt") || !hstr {
            Return ""
        }
        len := 0
        str := DllCall("combase\WindowsGetStringRawBuffer"
            , "Ptr", hstr
            , "UIntP", len
            , "Ptr")
        Return StrGet(str)
    }
}
