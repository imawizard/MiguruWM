SID_IVirtualDesktopPinnedApps_19044 := "{B5A399E7-1C87-46B8-88E9-FC5747B171BD}"

class VirtualDesktopPinnedApps extends InterfaceWrapper {
    Static Interfaces := [
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
        Return this.wrapped.IsAppIdPinned(appId)
    }

    PinAppID(appId) {
        Return this.wrapped.PinAppID(appId)
    }

    UnpinAppID(appId) {
        Return this.wrapped.UnpinAppID(appId)
    }

    IsViewPinned(view) {
        Return this.wrapped.IsViewPinned(view)
    }

    PinView(view) {
        Return this.wrapped.PinView(view)
    }

    UnpinView(view) {
        Return this.wrapped.UnpinView(view)
    }
}
