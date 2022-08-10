Global SID_ApplicationViewCollection_19044 := "{1841C6D7-4F9D-42C0-AF41-8747538F10E5}"

class ApplicationViewCollection {
    __New(immersiveShell) {
        collectionObj := CreateFromSIDs(immersiveShell
            , SID_ApplicationViewCollection_19044
            , "")
        if !collectionObj {
            Throw "Could not create ApplicationViewCollection"
        }

        this.collection := ConstructInterface(collectionObj
            , IApplicationViewCollection_19044
            , "")
        ObjRelease(collectionObj)
        if !this.collection {
            Throw "Could not find IApplicationViewCollection"
        }

        this.handlers := {}
    }

    __Delete() {
        ObjRelease(this.collection.ptr)
    }

    GetViews() {
        views := this.collection.GetViews()
        Return views ? new ApplicationViewArray(views) : false
    }

    GetViewsByZOrder() {
        views := this.collection.GetViewsByZOrder()
        Return views ? new ApplicationViewArray(views) : false
    }

    GetViewsByAppUserModelId(modelId) {
        views := this.collection.GetViewsByAppUserModelId(modelId)
        Return views ? new ApplicationViewArray(views) : false
    }

    GetViewForHwnd(hwnd) {
        view := this.collection.GetViewForHwnd(hwnd)
        Return view ? new ApplicationView(view) : false
    }

    GetViewForAppUserModelId(modelId) {
        view := this.collection.GetViewForAppUserModelId(modelId)
        Return view ? new ApplicationView(view) : false
    }

    GetViewInFocus() {
        view := this.collection.GetViewInFocus()
        Return view ? new ApplicationView(view) : false
   }

    Unknown1() {
        view := this.collection.Unknown1()
        Return view ? new ApplicationView(view) : false
    }

    RefreshCollection() {
        Return this.collection.RefreshCollection()
    }

    RegisterForApplicationViewChanges(listener) {
        handler := listener.ptr
        cookie := this.collection.RegisterForApplicationViewChanges(handler)
        this.handlers[handler] := cookie
        Return cookie > 0
    }

    UnregisterForApplicationViewChanges(listener) {
        handler := listener.ptr
        cookie := this.handlers[handler]
        Return this.collection.UnregisterForApplicationViewChanges(cookie)
    }
}

class ApplicationViewArray {
    __New(ptr) {
        this.a := new IObjectArray(ptr)
    }

    __Delete() {
        ObjRelease(this.a.ptr)
    }

    Ptr() {
        Return this.a.ptr
    }

    GetCount() {
        Return this.a.GetCount()
    }

    GetAt(index) {
        obj := this.a.GetAt(index)
        if !obj {
            Return false
        }

        view := new ApplicationView(obj)
        ObjRelease(obj)
        Return view
    }
}

Global IID_IApplicationViewChangeListener_19044 := "{727F9E97-76EE-497B-A942-B6371328485C}"

class ApplicationViewChangeListener extends ComObject {
    __New(callback) {
        base.__New([""
            , IID_IApplicationViewChangeListener_19044
            , ""], [""
            , "OnEvent"
            , ""])
        this.fn := callback
    }

    OnEvent(view, state, unknown) {
        this := Object(A_EventInfo)
        this.fn.Call(new ApplicationView(view), state, unknown)
        ObjRelease(unknown)
    }
}
