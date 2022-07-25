Global SID_IVirtualDesktopPinnedApps_19044 := "{B5A399E7-1C87-46B8-88E9-FC5747B171BD}"

class VirtualDesktopPinnedApps {
    __New(immersiveShell) {
        pinnedAppsObj := CreateFromSIDs(immersiveShell
            , SID_IVirtualDesktopPinnedApps_19044
            , "")
        if !pinnedAppsObj {
            Throw "Could not create VirtualDesktopPinnedApps"
        }

        this.pinnedApps := ConstructInterface(pinnedAppsObj
            , IVirtualDesktopPinnedApps_19044
            , "")
        ObjRelease(pinnedAppsObj)
        if !this.pinnedApps {
            Throw "Could not find IVirtualDesktopPinnedApps"
        }
    }

    __Delete() {
        ObjRelease(this.pinnedApps.ptr)
    }

    IsAppIdPinned(appId) {
        Return this.pinnedApps.IsAppIdPinned(appId)
    }

    PinAppID(appId) {
        Return this.pinnedApps.PinAppID(appId)
    }

    UnpinAppID(appId) {
        Return this.pinnedApps.UnpinAppID(appId)
    }

    IsViewPinned(view) {
        Return this.pinnedApps.IsViewPinned(view)
    }

    PinView(view) {
        Return this.pinnedApps.PinView(view)
    }

    UnpinView(view) {
        Return this.pinnedApps.UnpinView(view)
    }
}
