SID_ApplicationViewCollection_19044 := "{1841C6D7-4F9D-42C0-AF41-8747538F10E5}"

class ApplicationViewCollection extends InterfaceWrapper {
    Static Interfaces := [
        IApplicationViewCollection_19044,
    ]

    __New(immersiveShell) {
        super.__New()
        IUnknown.FromSID(
            this,
            immersiveShell,
            SID_ApplicationViewCollection_19044,
        )
        this.handlers := {}
    }

    GetViews() {
        views := ApplicationViewArray()
        this.wrapped.GetViews(views)
        Return views
    }

    GetViewsByZOrder() {
        views := ApplicationViewArray()
        this.wrapped.GetViewsByZOrder(views)
        Return views
    }

    GetViewsByAppUserModelId(modelId) {
        views := ApplicationViewArray()
        this.wrapped.GetViewsByAppUserModelId(views, modelId)
        Return views
    }

    GetViewForHwnd(hwnd) {
        view := ApplicationView()
        this.wrapped.GetViewForHwnd(view, hwnd)
        Return view
    }

    GetViewForAppUserModelId(modelId) {
        view := ApplicationView()
        this.wrapped.GetViewForAppUserModelId(view, modelId)
        Return view
    }

    GetViewInFocus() {
        view := ApplicationView()
        this.wrapped.GetViewInFocus(view)
        Return view
    }

    RefreshCollection() {
        Return this.wrapped.RefreshCollection()
    }

    RegisterForApplicationViewChanges(listener) {
        handler := listener.ptr
        cookie := this.wrapped.RegisterForApplicationViewChanges(handler)
        this.handlers[handler] := cookie
        Return cookie > 0
    }

    UnregisterForApplicationViewChanges(listener) {
        handler := listener.ptr
        cookie := this.handlers[handler]
        Return this.wrapped.UnregisterForApplicationViewChanges(cookie)
    }
}

class ApplicationViewArray extends IObjectArray {
    GetAt(index) {
        view := ApplicationView()

        super.GetAt(view, index)
        if !view.Ptr {
            Return false
        }
        Return view
    }
}

IID_IApplicationViewChangeListener_19044 := "{727F9E97-76EE-497B-A942-B6371328485C}"

class ApplicationViewChangeListener extends ComObjectImpl {
    __New(callback) {
        super.__New([
            IID_IApplicationViewChangeListener_19044,
        ], [
            "OnEvent",
        ])
        this.callback := callback
    }

    OnEvent(view, state, unknown) {
        this := Object(A_EventInfo)
        this.callback.Call(ApplicationView(view), state, unknown)
    }
}
