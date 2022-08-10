class IObjectArray {
    __New(ptr) {
        this.ptr := ptr
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetCount"
                , "GetAt")
        }
        this.unknownGUID := ParseGUID(IID_Unknown)
    }

    __Delete() {
        DllCall("GlobalFree"
            , "Ptr", this.unknownGUID
            , "Int")
    }

    GetCount() {
        ret := -1
        DllCall(this.methods["GetCount"]
            , "Ptr", this.ptr
            , "UIntP", ret
            , "UInt")
        Return ret
    }

    GetAt(index, guid := "") {
        ret := false
        DllCall(this.methods["GetAt"]
            , "Ptr", this.ptr
            , "UInt", index - 1
            , "Ptr", guid ? guid : this.unknownGUID
            , "PtrP", ret
            , "UInt")
        Return ret
    }
}
