class IServiceProvider extends IUnknown {
    static GUID    := "{6D5140C1-7436-11CE-8034-00AA006009FA}"
    static Methods := [
        "QueryService",
    ]

    QueryService(guid, sid) {
        out := IUnknown()
        this._funcs["QueryService"](
            guid,
            sid,
            out,
            "HRESULT",
        )
        return out
    }
}
