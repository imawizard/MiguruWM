class IApplicationView_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{372E1D3B-38D3-42E4-A15B-8AB2B178F513}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetIids"
                , "GetRuntimeClassName"
                , "GetTrustLevel"
                , "SetFocus"
                , "SwitchTo"
                , "TryInvokeBack"
                , "GetThumbnailWindow"
                , "GetMonitor"
                , "GetVisibility")
        }
    }

    SetFocus() {
        Return DllCall(this.methods["SetFocus"]
            , "Ptr", this.ptr
            , "UInt") == 0
    }

    SwitchTo() {
        Return DllCall(this.methods["SwitchTo"]
            , "Ptr", this.ptr
            , "UInt") == 0
    }

    TryInvokeBack(callback) {
        Return DllCall(this.methods["TryInvokeBack"]
            , "Ptr", this.ptr
            , "Ptr", callback
            , "UInt") == 0
    }

    GetThumbnailWindow() {
        hwnd := 0
        DllCall(this.methods["GetThumbnailWindow"]
            , "Ptr", this.ptr
            , "PtrP", hwnd
            , "UInt")
        Return hwnd
    }

    GetMonitor() {
        monitor := 0
        DllCall(this.methods["GetMonitor"]
            , "Ptr", this.ptr
            , "PtrP", monitor
            , "UInt")
        Return monitor
    }

    GetVisibility() {
        visible := 0
        DllCall(this.methods["GetVisibility"]
            , "Ptr", this.ptr
            , "IntP", visible
            , "UInt")
        Return visible > 0
    }
}

class IApplicationView2_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{7F25223A-79AD-4E72-A39A-6A194DD604C1}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetIids"
                , "GetRuntimeClassName"
                , "GetTrustLevel"
                , "Unknown1"
                , "Unknown2")
        }
    }

    Unknown1() {
        ret := 0
        DllCall(this.methods["Unknown1"]
            , "Ptr", this.ptr
            , "IntP", ret
            , "UInt")
        Return ret
    }

    Unknown2(param) {
        ret := 0
        DllCall(this.methods["Unknown2"]
            , "Ptr", this.ptr
            , "Int", param
            , "IntP", ret
            , "UInt")
        Return ret
    }
}
