class VirtualDesktop extends InterfaceWrapper {
    static Interfaces := [
        IVirtualDesktop2_19044,
        IVirtualDesktop_19044,
        IVirtualDesktop_22000,
    ]

    IsViewVisible(view) {
        return this.wrapped.IsViewVisible(view)
    }

    GetId() {
        return this.wrapped.GetId()
    }

    GetName() {
        if this.wrapped.HasMethod("GetName") {
            return this.wrapped.GetName()
        }

        guid := this.GetId()
        stringified := StringifyGUID(guid)
        return RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops\" stringified, "Name")
    }
}

class VirtualDesktopArray extends IObjectArray {
    GetAt(index) {
        desktop := VirtualDesktop()

        super.GetAt(desktop, index)
        if !desktop.Ptr {
            return false
        }
        return desktop
    }
}
