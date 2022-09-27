SID_IVirtualDesktopPinnedApps_19044 := "{B5A399E7-1C87-46B8-88E9-FC5747B171BD}"

class VirtualDesktopPinnedApps extends InterfaceWrapper {
    static Interfaces := [
        IVirtualDesktopPinnedApps_19044,
    ]

    __New(immersiveShell) {
        super.__New()
        IUnknown.FromSID(
            this,
            immersiveShell,
            SID_IVirtualDesktopPinnedApps_19044,
        )
    }

    IsAppIdPinned(appId) {
        return this.wrapped.IsAppIdPinned(appId)
    }

    PinAppID(appId) {
        return this.wrapped.PinAppID(appId)
    }

    UnpinAppID(appId) {
        return this.wrapped.UnpinAppID(appId)
    }

    IsViewPinned(view) {
        return this.wrapped.IsViewPinned(view)
    }

    PinView(view) {
        return this.wrapped.PinView(view)
    }

    UnpinView(view) {
        return this.wrapped.UnpinView(view)
    }
}
