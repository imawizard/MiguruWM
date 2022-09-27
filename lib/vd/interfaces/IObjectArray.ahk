class IObjectArray extends IUnknown {
    static GUID    := "{92CA9DCD-5622-4BBA-A805-5E9F541BD8C9}"
    static Methods := [
        "GetCount",
        "GetAt",
    ]

    static IID_Unknown := ParseGUID(IUnknown.GUID)

    GetCount() {
        ret := -1
        this._funcs["GetCount"](
            "UInt*", &ret,
            "HRESULT",
        )
        return ret
    }

    GetAt(out, index) {
        this._funcs["GetAt"](
            "UInt", index - 1,
            "Ptr", IObjectArray.IID_Unknown,
            "Ptr*", out,
            "HRESULT",
        )
    }
}
