class ApplicationView {
    __New(obj) {
        this.view := ConstructInterface(obj
            , IApplicationView_19044
            , "")
        this.view2 := ConstructInterface(obj
            , IApplicationView2_19044
            , "")
        if !this.view || !this.view2 {
            Throw "Could not find IApplicationView"
        }
    }

    __Delete() {
        ObjRelease(this.view.ptr)
        ObjRelease(this.view2.ptr)
    }

    Ptr() {
        Return this.view.ptr
    }

    SetFocus() {
        Return this.view.SetFocus()
    }

    SwitchTo() {
        Return this.view.SwitchTo()
    }

    TryInvokeBack(callback) {
        Return this.view.TryInvokeBack(callback)
    }

    GetThumbnailWindow() {
        Return this.view.GetThumbnailWindow()
    }

    GetMonitor() {
        Return this.view.GetMonitor()
    }

    GetVisibility() {
        Return this.view.GetVisibility()
    }

    Unknown1() {
        Return this.view2.Unknown1()
    }

    Unknown2(param) {
        Return this.view2.Unknown2(param)
    }
}
