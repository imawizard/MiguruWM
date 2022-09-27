SID_IVirtualDesktopManagerInternal_19044 := "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}"

class VirtualDesktopManagerInternal extends InterfaceWrapper {
    static Interfaces := [
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
        return this.wrapped.GetCount()
    }

    MoveViewToDesktop(view, desktop) {
        return this.wrapped.MoveViewToDesktop(view, desktop)
    }

    CanViewMoveDesktops(view) {
        return this.wrapped.CanViewMoveDesktops(view)
    }

    GetCurrentDesktop() {
        desktop := VirtualDesktop()
        this.wrapped.GetCurrentDesktop(desktop)
        return desktop
    }

    GetDesktops() {
        desktops := VirtualDesktopArray()
        this.wrapped.GetDesktops(desktops)
        return desktops
    }

    GetAdjacentDesktop(desktop, direction) {
        if direction == "left" {
            direction := 3
        } else if direction == "right" {
            direction := 4
        }
        adjacent := VirtualDesktop()
        this.wrapped.GetAdjacentDesktop(adjacent, desktop, direction)
        return adjacent
    }

    SwitchDesktop(desktop) {
        return this.wrapped.SwitchDesktop(desktop)
    }

    CreateDesktop() {
        desktop := VirtualDesktop()
        this.wrapped.CreateDesktop(desktop)
        return desktop
    }

    RemoveDesktop(desktop, fallback) {
        return this.wrapped.RemoveDesktop(desktop, fallback)
    }

    FindDesktop(desktopId) {
        found := VirtualDesktop()
        this.wrapped.FindDesktop(found, desktopId)
        return found
    }

    SetDesktopName(desktop, name) {
        this.wrapped.SetDesktopName(desktop, name)
    }
}
