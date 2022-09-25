class VirtualDesktop extends InterfaceWrapper {
    Static Interfaces := [
        IVirtualDesktop2_19044,
        IVirtualDesktop_19044,
        IVirtualDesktop_22000,
    ]

    IsViewVisible(view) {
        Return this.wrapped.IsViewVisible(view)
    }

    GetId() {
        Return this.wrapped.GetId()
    }

    GetName() {
        if this.wrapped.HasMethod("GetName") {
            Return this.wrapped.GetName()
        }

        guid := this.GetId()
        stringified := StringifyGUID(guid)
        Return RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops\" stringified, "Name")
    }
}

class VirtualDesktopArray extends IObjectArray {
    GetAt(index) {
        desktop := VirtualDesktop()

        super.GetAt(desktop, index)
        if !desktop.Ptr {
            Return false
        }
        Return desktop
    }
}
