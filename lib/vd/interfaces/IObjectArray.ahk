class IObjectArray extends IUnknown {
    Static GUID    := "{92CA9DCD-5622-4BBA-A805-5E9F541BD8C9}"
    Static Methods := [
        "GetCount",
        "GetAt",
    ]

    Static IID_Unknown := ParseGUID(IUnknown.GUID)

    GetCount() {
        ret := -1
        this._funcs["GetCount"](
            "UIntP", &ret,
            "HRESULT",
        )
        Return ret
    }

    GetAt(out, index) {
        this._funcs["GetAt"](
            "UInt", index - 1,
            "Ptr", IObjectArray.IID_Unknown,
            "PtrP", out,
            "HRESULT",
        )
    }
}
