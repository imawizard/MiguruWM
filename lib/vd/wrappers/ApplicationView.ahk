class ApplicationView extends InterfaceWrapper {
    Static Interfaces := [
        IApplicationView_19044,
    ]

    SetFocus() {
        Return this.wrapped.SetFocus()
    }

    SwitchTo() {
        Return this.wrapped.SwitchTo()
    }

    TryInvokeBack(callback) {
        Return this.wrapped.TryInvokeBack(callback)
    }

    GetThumbnailWindow() {
        Return this.wrapped.GetThumbnailWindow()
    }

    GetMonitor() {
        Return this.wrapped.GetMonitor()
    }

    GetVisibility() {
        Return this.wrapped.GetVisibility()
    }
}
