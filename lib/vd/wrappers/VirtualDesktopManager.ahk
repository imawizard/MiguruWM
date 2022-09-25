CLSID_IVirtualDesktopManager_19044 := "{AA509086-5CA9-4C25-8F95-589D3C07B48A}"
CLSID_IVirtualDesktopManager_22000 := "{B2F925B9-5A0F-4D2E-9F4D-2B1507593C10}"

class VirtualDesktopManager extends InterfaceWrapper {
    Static Interfaces := [
        IVirtualDesktopManager_19044,
    ]

    __New(immersiveShell) {
        super.__New()
        IUnknown.FromCLSID(
            this,
            CLSID_IVirtualDesktopManager_19044,
            CLSID_IVirtualDesktopManager_22000,
        )
    }

    IsWindowOnCurrentVirtualDesktop(hwnd) {
        Return this.wrapped.IsWindowOnCurrentVirtualDesktop(hwnd)
    }

    GetWindowDesktopId(hwnd) {
        Return this.wrapped.GetWindowDesktopId(hwnd)
    }

    MoveWindowToDesktop(desktopId, hwnd) {
        Return this.wrapped.MoveWindowToDesktop(desktopId, hwnd)
    }
}
