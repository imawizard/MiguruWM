SID_IVirtualDesktopManagerInternal_19044 := "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}"

class VirtualDesktopManagerInternal extends InterfaceWrapper {
    Static Interfaces := [
        IVirtualDesktopManagerInternal3_19044,
        IVirtualDesktopManagerInternal2_19044,
        IVirtualDesktopManagerInternal_19044,
        IVirtualDesktopManagerInternal_22000,
        IVirtualDesktopManagerInternal_22489,
    ]

    __New(immersiveShell) {
        super.__New()
        IUnknown.FromSID(
            this,
            immersiveShell,
            SID_IVirtualDesktopManagerInternal_19044,
        )
    }

    GetCount() {
        Return this.wrapped.GetCount()
    }

    MoveViewToDesktop(view, desktop) {
        Return this.wrapped.MoveViewToDesktop(view, desktop)
    }

    CanViewMoveDesktops(view) {
        Return this.wrapped.CanViewMoveDesktops(view)
    }

    GetCurrentDesktop() {
        desktop := VirtualDesktop()
        this.wrapped.GetCurrentDesktop(desktop)
        Return desktop
    }

    GetDesktops() {
        desktops := VirtualDesktopArray()
        this.wrapped.GetDesktops(desktops)
        Return desktops
    }

    GetAdjacentDesktop(desktop, direction) {
        if (direction == "left") {
            direction := 3
        } else if (direction == "right") {
            direction := 4
        }
        adjacent := VirtualDesktop()
        this.wrapped.GetAdjacentDesktop(adjacent, desktop, direction)
        Return adjacent
    }

    SwitchDesktop(desktop) {
        Return this.wrapped.SwitchDesktop(desktop)
    }

    CreateDesktop() {
        desktop := VirtualDesktop()
        this.wrapped.CreateDesktop(desktop)
        Return desktop
    }

    RemoveDesktop(desktop, fallback) {
        Return this.wrapped.RemoveDesktop(desktop, fallback)
    }

    FindDesktop(desktopId) {
        found := VirtualDesktop()
        this.wrapped.FindDesktop(found, desktopId)
        Return found
    }

    SetDesktopName(desktop, name) {
        this.wrapped.SetDesktopName(desktop, name)
    }
}
