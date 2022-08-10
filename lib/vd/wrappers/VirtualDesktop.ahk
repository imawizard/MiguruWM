class VirtualDesktop {
    __New(obj) {
        this.desktop := ConstructInterface(obj
            , IVirtualDesktop2_19044
            , IVirtualDesktop_19044
            , IVirtualDesktop_22000
            , "")
        if !this.desktop {
            Throw "Could not find IVirtualDesktop"
        }
    }

    __Delete() {
        ObjRelease(this.desktop.ptr)
    }

    Ptr() {
        Return this.desktop.ptr
    }

    IsViewVisible(view) {
        Return this.desktop.IsViewVisible(view)
    }

    GetId() {
        Return this.desktop.GetId()
    }

    GetName() {
        if this.desktop.GetName {
            Return this.desktop.GetName()
        }

        guid := this.GetId()
        stringified := StringifyGUID(&guid)
        RegRead, name, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops\Desktops\%stringified%, Name
        Return name
    }
}
