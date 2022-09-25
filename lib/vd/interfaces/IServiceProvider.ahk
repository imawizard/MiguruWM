class IServiceProvider extends IUnknown {
    Static GUID    := "{6D5140C1-7436-11CE-8034-00AA006009FA}"
    Static Methods := [
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
        Return out
    }
}
