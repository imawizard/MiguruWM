class ApplicationView extends InterfaceWrapper {
    static Interfaces := [
        IApplicationView_19044,
    ]

    SetFocus() {
        return this.wrapped.SetFocus()
    }

    SwitchTo() {
        return this.wrapped.SwitchTo()
    }

    TryInvokeBack(callback) {
        return this.wrapped.TryInvokeBack(callback)
    }

    GetThumbnailWindow() {
        return this.wrapped.GetThumbnailWindow()
    }

    GetMonitor() {
        return this.wrapped.GetMonitor()
    }

    GetVisibility() {
        return this.wrapped.GetVisibility()
    }

    GetAppUserModelId() {
        return this.wrapped.GetAppUserModelId()
    }
}
