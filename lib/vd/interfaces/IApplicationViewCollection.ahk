class IApplicationViewCollection_19044 {
    __New(obj) {
        this.ptr := ComObjQuery(obj, "{1841C6D7-4F9D-42C0-AF41-8747538F10E5}")
        if this.ptr {
            this.methods := MethodTable(this.ptr
                , "GetViews"
                , "GetViewsByZOrder"
                , "GetViewsByAppUserModelId"
                , "GetViewForHwnd"
                , "GetViewForApplication"
                , "GetViewForAppUserModelId"
                , "GetViewInFocus"
                , "Unknown1"
                , "RefreshCollection"
                , "RegisterForApplicationViewChanges"
                , "UnregisterForApplicationViewChanges")
        }
    }

    GetViews() {
        views := false
        DllCall(this.methods["GetViews"]
            , "Ptr", this.ptr
            , "PtrP", views
            , "UInt")
        Return views
    }

    GetViewsByZOrder() {
        views := false
        DllCall(this.methods["GetViewsByZOrder"]
            , "Ptr", this.ptr
            , "PtrP", views
            , "UInt")
        Return views
    }

    GetViewsByAppUserModelId(modelId) {
        views := false
        DllCall(this.methods["GetViewsByAppUserModelId"]
            , "Ptr", this.ptr
            , "Ptr", modelId
            , "PtrP", views
            , "UInt")
        Return views
    }

    GetViewForHwnd(hwnd) {
        view := 0
        DllCall(this.methods["GetViewForHwnd"]
            , "Ptr", this.ptr
            , "Ptr", hwnd
            , "PtrP", view
            , "UInt")
        Return view
    }

    GetViewForAppUserModelId(modelId) {
        view := 0
        DllCall(this.methods["GetViewForAppUserModelId"]
            , "Ptr", this.ptr
            , "Ptr", modelId
            , "PtrP", view
            , "UInt")
        Return view
    }

    GetViewInFocus() {
        view := 0
        DllCall(this.methods["GetViewInFocus"]
            , "Ptr", this.ptr
            , "PtrP", view
            , "UInt")
        Return view
    }

    Unknown1() {
        view := 0
        DllCall(this.methods["Unknown1"]
            , "Ptr", this.ptr
            , "PtrP", view
            , "UInt")
        Return view
    }

    RefreshCollection() {
        Return DllCall(this.methods["RefreshCollection"]
            , "Ptr", this.ptr
            , "UInt") == 0
    }

    RegisterForApplicationViewChanges(handler) {
        cookie := 0
        DllCall(this.methods["RegisterForApplicationViewChanges"]
            , "Ptr", this.ptr
            , "Ptr", handler
            , "IntP", cookie
            , "UInt")
        Return cookie
    }

    UnregisterForApplicationViewChanges(cookie) {
        Return DllCall(this.methods["UnregisterForApplicationViewChanges"]
            , "Ptr", this.ptr
            , "Int", cookie
            , "UInt") == 0
    }
}
